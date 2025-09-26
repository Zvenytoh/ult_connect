// client_page.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class ClientPage extends StatefulWidget {
  const ClientPage({super.key});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(
    text: "8080",
  );
  final TextEditingController _passwordController =
      TextEditingController(); // used for encrypt when sending (optional)
  List<Map<String, dynamic>> _serverFiles = []; // {name, encrypted, owner}
  final List<String> _logs = [];

  void _addLog(String msg) =>
      setState(() => _logs.add("[${DateTime.now().toIso8601String()}] $msg"));

  Uri _filesUri(String ip, int port) => Uri.parse("http://$ip:$port/files");
  Uri _fileGetUri(String ip, int port, String name) =>
      Uri.parse("http://$ip:$port/files/${Uri.encodeComponent(name)}");
  Uri _uploadUri(String ip, int port) => Uri.parse("http://$ip:$port/upload");

  // fetch file list (list of objects)
  Future<void> _refreshFiles() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8080;
    if (ip.isEmpty) {
      _addLog("❌ IP manquante");
      return;
    }
    try {
      final resp = await http
          .get(_filesUri(ip, port))
          .timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final list = jsonDecode(resp.body) as List<dynamic>;
        setState(() {
          _serverFiles =
              list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
        _addLog("✅ Liste mise à jour (${_serverFiles.length})");
      } else {
        _addLog("❌ Erreur list : ${resp.statusCode}");
      }
    } catch (e) {
      _addLog("❌ Erreur récupération liste : $e");
    }
  }

  // send file: if password provided -> encrypt with random IV, send body = iv + ciphertext
  Future<void> _pickAndSendFile() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8080;
    if (ip.isEmpty) {
      _addLog("❌ IP manquante");
      return;
    }

    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;
    final file = File(result.files.single.path!);
    final filename = result.files.single.name;
    final password = _passwordController.text;

    try {
      Uint8List payload = await file.readAsBytes();

      bool encryptedFlag = false;
      if (password.trim().isNotEmpty) {
        encryptedFlag = true;
        final key = encrypt.Key.fromUtf8(
          password.padRight(32).substring(0, 32),
        );
        final iv = encrypt.IV.fromSecureRandom(16);
        final encrypter = encrypt.Encrypter(encrypt.AES(key));
        final encrypted = encrypter.encryptBytes(payload, iv: iv);
        // body = iv (16 bytes) || ciphertext
        payload = Uint8List.fromList(iv.bytes + encrypted.bytes);
      }

      final req = http.Request('POST', _uploadUri(ip, port));
      req.headers['x-filename'] = filename;
      req.headers['x-encrypted'] = encryptedFlag ? '1' : '0';
      req.bodyBytes = payload;

      final streamedResp = await req.send();
      final text = await streamedResp.stream.bytesToString();
      if (streamedResp.statusCode == 200) {
        _addLog("✅ Envoi OK : $filename (encrypted: $encryptedFlag)");
        await _refreshFiles();
      } else {
        _addLog("❌ Envoi échoué : ${streamedResp.statusCode} $text");
      }
    } catch (e) {
      _addLog("❌ Erreur envoi : $e");
    }
  }

  // download raw bytes then if encrypted ask for password and attempt decrypt locally
  Future<void> _downloadAndMaybeDecrypt(Map<String, dynamic> fileObj) async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8080;
    final name = fileObj['name'] as String;
    final encrypted = fileObj['encrypted'] == true;

    try {
      final request = await HttpClient().getUrl(_fileGetUri(ip, port, name));
      final response = await request.close();
      if (response.statusCode != 200) {
        _addLog("❌ Erreur téléchargement ${response.statusCode}");
        return;
      }
      final raw = await consolidateHttpClientResponseBytes(response);

      Uint8List dataToSave;

      if (!encrypted) {
        dataToSave = Uint8List.fromList(raw);
      } else {
        // ask password
        final password = await showDialog<String>(
          context: context,
          builder: (ctx) {
            final ctrl = TextEditingController();
            return AlertDialog(
              title: const Text("Mot de passe requis"),
              content: TextField(
                controller: ctrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Mot de passe"),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, ctrl.text),
                  child: const Text("Valider"),
                ),
              ],
            );
          },
        );
        if (password == null || password.isEmpty) {
          _addLog("❌ Téléchargement annulé (mot de passe non fourni)");
          return;
        }

        // extract IV and ciphertext
        if (raw.length < 16) {
          _addLog("❌ Contenu invalide (trop court)");
          return;
        }
        final ivBytes = raw.sublist(0, 16);
        final cipher = raw.sublist(16);

        try {
          final key = encrypt.Key.fromUtf8(
            password.padRight(32).substring(0, 32),
          );
          final iv = encrypt.IV(ivBytes);
          final encrypter = encrypt.Encrypter(encrypt.AES(key));
          final decrypted = encrypter.decryptBytes(
            encrypt.Encrypted(cipher),
            iv: iv,
          );
          dataToSave = Uint8List.fromList(decrypted);
        } catch (e) {
          _addLog("❌ Déchiffrement échoué (mot de passe incorrect ?) : $e");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Mot de passe incorrect ou fichier corrompu"),
              ),
            );
          }
          return;
        }
      }

      // save to device documents
      final docs = await getApplicationDocumentsDirectory();
      final out = File(path.join(docs.path, name));
      await out.writeAsBytes(dataToSave, flush: true);
      _addLog("📥 Fichier téléchargé & enregistré: ${out.path}");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Téléchargé : ${out.path}")));
      }
    } catch (e) {
      _addLog("❌ Erreur téléchargement/déchiffrement : $e");
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Client")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(labelText: "IP"),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _portController,
                    decoration: const InputDecoration(labelText: "Port"),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _refreshFiles,
                  child: const Text("Connecter"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Mot de passe (pour chiffrer à l'envoi)",
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickAndSendFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Envoyer (chiffrer si mdp)"),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _refreshFiles,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Actualiser"),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // files list
            Expanded(
              flex: 3,
              child: Card(
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.folder),
                      title: Text("Fichiers serveur"),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _serverFiles.isEmpty
                          ? const Center(child: Text("Aucun fichier"))
                          : ListView.builder(
                              itemCount: _serverFiles.length,
                              itemBuilder: (c, i) {
                                final f = _serverFiles[i];
                                final encrypted = f['encrypted'] == true;
                                return ListTile(
                                  leading: Icon(
                                    encrypted
                                        ? Icons.lock
                                        : Icons.insert_drive_file,
                                  ),
                                  title: Text(f['name'] as String),
                                  subtitle: Text(
                                    encrypted
                                        ? "🔒 chiffré • owner: ${f['owner']}"
                                        : "non chiffré • owner: ${f['owner']}",
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (v) {
                                      if (v == 'download') {
                                        _downloadAndMaybeDecrypt(f);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'download',
                                        child: Text("⬇️ Télécharger"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // logs
            Expanded(
              flex: 2,
              child: Card(
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.list),
                      title: Text("Logs"),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _logs.isEmpty
                          ? const Center(child: Text("Aucun log"))
                          : ListView.builder(
                              itemCount: _logs.length,
                              itemBuilder: (c, i) => Text(
                                _logs[i],
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

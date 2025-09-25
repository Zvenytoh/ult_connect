import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class ServerPage extends StatefulWidget {
  const ServerPage({super.key});

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  HttpServer? _server;
  final List<String> _logs = [];
  final List<Map<String, dynamic>> _files = []; // {name, encrypted, owner}
  final String storageDir = "server_files";

  @override
  void initState() {
    super.initState();
    final dir = Directory(storageDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
  }

  void _addLog(String msg) {
    setState(() => _logs.add("[${DateTime.now().toIso8601String()}] $msg"));
  }

  Future<void> _startServer() async {
    if (_server != null) return;

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
      _addLog("✅ Serveur démarré sur http://${await _getLocalIp()}:8080");

      _server!.listen((HttpRequest request) async {
        final clientIp =
            request.connectionInfo?.remoteAddress.address ?? "inconnu";

        if (request.method == 'POST' && request.uri.path == '/upload') {
          try {
            final bytes = await request.fold<List<int>>(
              [],
              (prev, e) => prev..addAll(e),
            );
            final filename =
                request.headers.value('x-filename') ??
                'file_${DateTime.now().millisecondsSinceEpoch}';
            final encrypted = request.headers.value('x-encrypted') == '1';
            final owner = clientIp;

            final file = File(path.join(storageDir, filename));
            await file.writeAsBytes(bytes);

            _files.add({
              'name': filename,
              'encrypted': encrypted,
              'owner': owner,
            });

            _addLog(
              "💾 Fichier reçu de $owner : $filename (encrypted: $encrypted)",
            );
            request.response.write("✅ Fichier reçu !");
            await request.response.close();

            _updateFilesList();
          } catch (e) {
            _addLog("❌ Erreur réception fichier: $e");
            request.response.statusCode = HttpStatus.internalServerError;
            await request.response.close();
          }
        } else if (request.method == 'GET' && request.uri.path == '/files') {
          request.response
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(_files));
          await request.response.close();
        } else if (request.method == 'GET' &&
            request.uri.path.startsWith('/files/')) {
          final fileName = request.uri.pathSegments.last;
          final file = File(path.join(storageDir, fileName));
          if (file.existsSync()) {
            request.response.headers.contentType = ContentType.binary;
            await request.response.addStream(file.openRead());
          } else {
            request.response.statusCode = HttpStatus.notFound;
          }
          await request.response.close();
        } else {
          request.response.write("Serveur actif");
          await request.response.close();
        }
      });
    } catch (e) {
      _addLog("❌ Erreur serveur: $e");
    }
    setState(() {});
  }

  Future<void> _stopServer() async {
    await _server?.close(force: true);
    _server = null;
    _addLog("🛑 Serveur arrêté");
    setState(() {});
  }

  Future<void> _updateFilesList() async {
    final dir = Directory(storageDir);
    final existingFiles = dir.existsSync()
        ? dir
              .listSync()
              .whereType<File>()
              .map((f) => path.basename(f.path))
              .toList()
        : [];
    setState(() {
      _files.removeWhere((f) => !existingFiles.contains(f['name']));
    });
  }

  Future<String> _getLocalIp() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (var iface in interfaces) {
      for (var addr in iface.addresses) {
        if (!addr.isLoopback) return addr.address;
      }
    }
    return 'localhost';
  }

  Future<void> _downloadFile(Map<String, dynamic> fileObj) async {
    final fileName = fileObj['name'] as String;
    final encrypted = fileObj['encrypted'] == true;

    try {
      final file = File(path.join(storageDir, fileName));
      if (!file.existsSync()) return;

      Uint8List dataToSave = await file.readAsBytes();

      if (encrypted) {
        final password = await showDialog<String>(
          context: context,
          builder: (ctx) {
            final ctrl = TextEditingController();
            return AlertDialog(
              title: const Text("Mot de passe requis"),
              content: TextField(
                controller: ctrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Mot de passe du propriétaire",
                ),
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

        // déchiffrement iv + ciphertext
        if (dataToSave.length < 16) {
          _addLog("❌ Contenu invalide (trop court)");
          return;
        }
        final ivBytes = dataToSave.sublist(0, 16);
        final cipher = dataToSave.sublist(16);

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
          _addLog("❌ Déchiffrement échoué : $e");
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Mot de passe incorrect ou fichier corrompu"),
              ),
            );
          return;
        }
      }

      final dir = await getApplicationDocumentsDirectory();
      final outFile = File(path.join(dir.path, fileName));
      await outFile.writeAsBytes(dataToSave, flush: true);
      _addLog("📥 Fichier téléchargé & enregistré : ${outFile.path}");
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Téléchargé : ${outFile.path}")));
    } catch (e) {
      _addLog("❌ Erreur téléchargement : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = _server != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Serveur local"),
        backgroundColor: isRunning ? Colors.green : Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // --- État du serveur ---
            Card(
              color: isRunning ? Colors.green.shade100 : Colors.red.shade100,
              child: ListTile(
                leading: Icon(
                  isRunning ? Icons.check_circle : Icons.cancel,
                  color: isRunning ? Colors.green : Colors.red,
                ),
                title: Text(
                  isRunning ? "Serveur en ligne" : "Serveur arrêté",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isRunning ? Colors.green[900] : Colors.red[900],
                  ),
                ),
                subtitle: isRunning
                    ? FutureBuilder<String>(
                        future: _getLocalIp(),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.hasData
                                ? "Adresse: http://${snapshot.data}:8080"
                                : "Chargement...",
                          );
                        },
                      )
                    : const Text("Appuyez sur Démarrer pour lancer le serveur"),
                trailing: ElevatedButton.icon(
                  onPressed: isRunning ? _stopServer : _startServer,
                  icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
                  label: Text(isRunning ? "Arrêter" : "Démarrer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRunning ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // --- Logs ---
            Expanded(
              flex: 2,
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ListTile(
                      leading: Icon(Icons.list_alt),
                      title: Text(
                        "Logs",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _logs.isEmpty
                          ? const Center(
                              child: Text("Aucun log pour le moment"),
                            )
                          : ListView.builder(
                              itemCount: _logs.length,
                              itemBuilder: (context, index) => ListTile(
                                dense: true,
                                title: Text(
                                  _logs[index],
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --- Fichiers reçus ---
            Expanded(
              flex: 3,
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ListTile(
                      leading: Icon(Icons.folder),
                      title: Text(
                        "Fichiers reçus",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _files.isEmpty
                          ? const Center(
                              child: Text("Aucun fichier reçu pour le moment"),
                            )
                          : ListView.builder(
                              itemCount: _files.length,
                              itemBuilder: (context, index) {
                                final fileObj = _files[index];
                                final encrypted = fileObj['encrypted'] == true;
                                final owner = fileObj['owner'] ?? 'unknown';
                                return ListTile(
                                  leading: Icon(
                                    encrypted
                                        ? Icons.lock
                                        : Icons.insert_drive_file,
                                  ),
                                  title: Text(fileObj['name']),
                                  subtitle: Text(
                                    encrypted
                                        ? "🔒 chiffré • owner: $owner"
                                        : "non chiffré • owner: $owner",
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'download')
                                        _downloadFile(fileObj);
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
          ],
        ),
      ),
    );
  }
}

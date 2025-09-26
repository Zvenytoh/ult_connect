import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';

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
    _updateFilesList();
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
              (prev, element) => prev..addAll(element),
            );

            final filename = request.headers.value('x-filename') ??
                'file_${DateTime.now().millisecondsSinceEpoch}';
            final encryptedFlag = request.headers.value('x-encrypted') == '1';
            final owner = clientIp;
            final file = File(path.join(storageDir, filename));
            await file.writeAsBytes(bytes);

            _addLog(
              "💾 Fichier reçu de $clientIp : $filename (encrypted: $encryptedFlag)",
            );

            // Mettre à jour la liste
            await _updateFilesList();

            // stocke info fichier côté serveur
            final fileIndex = _files.indexWhere((f) => f['name'] == filename);
            if (fileIndex >= 0) {
              _files[fileIndex]['encrypted'] = encryptedFlag;
              _files[fileIndex]['owner'] = owner;
            } else {
              _files.add({
                'name': filename,
                'encrypted': encryptedFlag,
                'owner': owner,
              });
            }

            request.response.write("✅ Fichier reçu !");
            await request.response.close();
          } catch (e) {
            _addLog("❌ Erreur réception fichier: $e");
            request.response.statusCode = HttpStatus.internalServerError;
            await request.response.close();
          }
        } else if (request.method == 'GET' && request.uri.path == '/files') {
          // Retourne la liste des fichiers (JSON)
          request.response
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(_files));
          await request.response.close();
        } else if (request.method == 'GET' &&
            request.uri.path.startsWith('/files/')) {
          // Téléchargement fichier
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
    final list = dir.existsSync()
        ? dir.listSync().whereType<File>().map((f) {
            final name = path.basename(f.path);
            final existing = _files.firstWhere(
              (e) => e['name'] == name,
              orElse: () => {
                'name': name,
                'encrypted': false,
                'owner': 'unknown',
              },
            );
            return {
              'name': name,
              'encrypted': existing['encrypted'] ?? false,
              'owner': existing['owner'] ?? 'unknown',
            };
          }).toList()
        : [];
    setState(() {
      _files
        ..clear()
        ..addAll(list as Iterable<Map<String, dynamic>>);
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

  Future<void> _deleteFile(String fileName) async {
    try {
      final file = File(path.join(storageDir, fileName));
      if (file.existsSync()) {
        await file.delete();
        _addLog("🗑️ Fichier supprimé : $fileName");
        await _updateFilesList();
      }
    } catch (e) {
      _addLog("❌ Erreur suppression : $e");
    }
  }

  Future<void> _renameFile(String oldName, String newName) async {
    try {
      final oldFile = File(path.join(storageDir, oldName));
      if (oldFile.existsSync()) {
        final newFile = File(path.join(storageDir, newName));
        await oldFile.rename(newFile.path);
        _addLog("✏️ Fichier renommé : $oldName -> $newName");
        await _updateFilesList();
      }
    } catch (e) {
      _addLog("❌ Erreur renommage : $e");
    }
  }

  Future<void> _downloadFile(Map<String, dynamic> fileObj) async {
    final name = fileObj['name'] as String;
    final encrypted = fileObj['encrypted'] == true;

    try {
      final file = File(path.join(storageDir, name));
      if (!file.existsSync()) {
        _addLog("❌ Fichier introuvable : $name");
        return;
      }

      Uint8List bytes = await file.readAsBytes();

      if (encrypted) {
        // demander mot de passe pour déchiffrement
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
          _addLog("❌ Déchiffrement annulé (mot de passe non fourni)");
          return;
        }

        try {
          final key = encrypt.Key.fromUtf8(
            password.padRight(32).substring(0, 32),
          );
          final iv = encrypt.IV(bytes.sublist(0, 16));
          final cipher = bytes.sublist(16);
          final encrypter = encrypt.Encrypter(encrypt.AES(key));
          bytes = Uint8List.fromList(
            encrypter.decryptBytes(encrypt.Encrypted(cipher), iv: iv),
          );
        } catch (e) {
          _addLog("❌ Déchiffrement échoué : $e");
          return;
        }
      }

      final docs = await getApplicationDocumentsDirectory();
      final out = File(path.join(docs.path, name));
      await out.writeAsBytes(bytes, flush: true);
      _addLog("📥 Fichier téléchargé : ${out.path}");
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
            // Serveur
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
                        builder: (ctx, snap) => Text(
                          snap.hasData
                              ? "Adresse: http://${snap.data}:8080"
                              : "Chargement...",
                        ),
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

            // Logs
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
                          ? const Center(child: Text("Aucun log"))
                          : ListView.builder(
                              itemCount: _logs.length,
                              itemBuilder: (_, i) => Text(
                                _logs[i],
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Fichiers
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
                          ? const Center(child: Text("Aucun fichier"))
                          : ListView.builder(
                              itemCount: _files.length,
                              itemBuilder: (_, i) {
                                final f = _files[i];
                                return ListTile(
                                  leading: Icon(
                                    f['encrypted']
                                        ? Icons.lock
                                        : Icons.insert_drive_file,
                                  ),
                                  title: Text(f['name']),
                                  subtitle: Text(
                                    f['encrypted']
                                        ? "🔒 chiffré • owner: ${f['owner']}"
                                        : "non chiffré • owner: ${f['owner']}",
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (v) async {
                                      if (v == 'download') {
                                        await _downloadFile(f);
                                      }
                                      if (v == 'delete') {
                                        await _deleteFile(f['name']);
                                      }
                                      if (v == 'rename') {
                                        final ctrl = TextEditingController();
                                        await showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text(
                                              "Renommer fichier",
                                            ),
                                            content: TextField(
                                              controller: ctrl,
                                              decoration: const InputDecoration(
                                                labelText: "Nouveau nom",
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text("Annuler"),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  _renameFile(
                                                    f['name'],
                                                    ctrl.text,
                                                  );
                                                  Navigator.pop(context);
                                                },
                                                child: const Text("Valider"),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'download',
                                        child: Text("⬇️ Télécharger"),
                                      ),
                                      PopupMenuItem(
                                        value: 'rename',
                                        child: Text("✏️ Renommer"),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text("🗑️ Supprimer"),
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

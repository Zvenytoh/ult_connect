import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ServerPage extends StatefulWidget {
  const ServerPage({super.key});

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  HttpServer? _server;
  final List<String> _logs = [];
  final List<String> _files = [];
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

            final contentDisp = request.headers.value('content-disposition');
            String filename = 'file_${DateTime.now().millisecondsSinceEpoch}';
            if (contentDisp != null && contentDisp.contains('filename=')) {
              filename = contentDisp.split('filename=')[1].replaceAll('"', '');
            }

            final file = File(path.join(storageDir, filename));
            await file.writeAsBytes(bytes);

            _addLog("💾 Fichier reçu de $clientIp: $filename");
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
          // téléchargement depuis client
          final fileName = request.uri.pathSegments.last;
          final file = File(path.join(storageDir, fileName));
          if (await file.exists()) {
            request.response.headers.contentType = ContentType.binary;
            await request.response.addStream(file.openRead());
          } else {
            request.response.statusCode = HttpStatus.notFound;
            request.response.write("❌ Fichier non trouvé");
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
        ? dir
              .listSync()
              .whereType<File>()
              .map((f) => path.basename(f.path))
              .toList()
        : [];
    setState(() {
      _files
        ..clear()
        ..addAll(list as Iterable<String>);
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
    final file = File(path.join(storageDir, fileName));
    if (await file.exists()) {
      await file.delete();
      _addLog("🗑 Fichier supprimé: $fileName");
      _updateFilesList();
    }
  }

  Future<void> _renameFile(String oldName, String newName) async {
    final file = File(path.join(storageDir, oldName));
    final newFile = File(path.join(storageDir, newName));
    if (await file.exists()) {
      await file.rename(newFile.path);
      _addLog("✏️ Fichier renommé: $oldName → $newName");
      _updateFilesList();
    }
  }

  Future<void> _downloadFileLocally(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final target = File(path.join(dir.path, fileName));
    final source = File(path.join(storageDir, fileName));
    if (await source.exists()) {
      await target.writeAsBytes(await source.readAsBytes());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("📥 Sauvegardé dans Documents : ${target.path}"),
          ),
        );
      }
    }
  }

  Future<String?> _askNewName(BuildContext context, String oldName) async {
    final controller = TextEditingController(text: oldName);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer le fichier'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
            // --- Fichiers reçus ---
            Expanded(
              flex: 2,
              child: Card(
                child: Column(
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
                              itemBuilder: (context, index) {
                                final fileName = _files[index];
                                return ListTile(
                                  leading: const Icon(Icons.insert_drive_file),
                                  title: Text(fileName),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'delete') {
                                        await _deleteFile(fileName);
                                      } else if (value == 'rename') {
                                        final newName = await _askNewName(
                                          context,
                                          fileName,
                                        );
                                        if (newName != null &&
                                            newName.isNotEmpty) {
                                          await _renameFile(fileName, newName);
                                        }
                                      } else if (value == 'download') {
                                        await _downloadFileLocally(fileName);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text("🗑 Supprimer"),
                                      ),
                                      const PopupMenuItem(
                                        value: 'rename',
                                        child: Text("✏️ Renommer"),
                                      ),
                                      const PopupMenuItem(
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

            // --- Logs ---
            Expanded(
              flex: 1,
              child: Card(
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.list_alt),
                      title: Text("Logs"),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) => ListTile(
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isRunning ? _stopServer : _startServer,
        backgroundColor: isRunning ? Colors.red : Colors.green,
        icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
        label: Text(isRunning ? "Arrêter" : "Démarrer"),
      ),
    );
  }
}

import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

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
              flex: 2,
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
                              itemBuilder: (context, index) => ListTile(
                                leading: const Icon(Icons.insert_drive_file),
                                title: Text(_files[index]),
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

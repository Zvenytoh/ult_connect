import 'dart:io';
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
          final bytes = await request.fold<List<int>>(
            [],
            (prev, e) => prev..addAll(e),
          );
          final filename = 'file_${DateTime.now().millisecondsSinceEpoch}';
          final file = File(path.join(storageDir, filename));
          await file.writeAsBytes(bytes);
          _addLog("💾 Fichier reçu de $clientIp: $filename");
          request.response.write("✅ Fichier reçu !");
          await request.response.close();
          _updateFilesList();
        } else if (request.method == 'GET' && request.uri.path == '/files') {
          request.response
            ..headers.contentType = ContentType.json
            ..write(_files);
          await request.response.close();
        } else {
          request.response.write("Serveur actif");
          await request.response.close();
        }
      });
    } catch (e) {
      _addLog("❌ Erreur serveur: $e");
    }
  }

  Future<void> _stopServer() async {
    await _server?.close(force: true);
    _server = null;
    _addLog("🛑 Serveur arrêté");
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
      _files.clear();
      _files.addAll(list as Iterable<String>);
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
    return Scaffold(
      appBar: AppBar(title: const Text("Serveur")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: _startServer,
                  child: const Text("Démarrer"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _stopServer,
                  child: const Text("Arrêter"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text("Logs:", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) =>
                    ListTile(title: Text(_logs[index])),
              ),
            ),
            const Divider(),
            const Text(
              "Fichiers reçus:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _files.length,
                itemBuilder: (context, index) =>
                    ListTile(title: Text(_files[index])),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

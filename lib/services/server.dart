import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class SimpleServer {
  HttpServer? _server;
  Function(String)? onLog;
  final String storageDir = "server_files";

  bool get isRunning => _server != null;

  SimpleServer({this.onLog}) {
    final dir = Directory(storageDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
  }

  void _addLog(String msg) =>
      onLog?.call("[${DateTime.now().toIso8601String()}] $msg");

  Future<void> start({int port = 8080}) async {
    if (_server != null) {
      _addLog("⚠️ Serveur déjà lancé.");
      return;
    }

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _addLog("✅ Serveur démarré sur http://${await _getLocalIp()}:$port");

      _server!.listen((HttpRequest request) async {
        final clientIp =
            request.connectionInfo?.remoteAddress.address ?? "inconnu";

        if (request.method == 'POST' && request.uri.path == '/upload') {
          // Lecture des bytes du fichier
          final bytes = await consolidateHttpClientResponseBytes(
            request as HttpClientResponse,
          );

          // Récupération du nom original depuis les headers
          String filename = 'file_${DateTime.now().millisecondsSinceEpoch}';
          final contentDisposition = request.headers.value(
            'content-disposition',
          );
          if (contentDisposition != null) {
            final match = RegExp(
              r'filename="(.+)"',
            ).firstMatch(contentDisposition);
            if (match != null) filename = match.group(1)!;
          }

          final file = File(path.join(storageDir, filename));
          await file.writeAsBytes(bytes);
          _addLog("💾 Fichier reçu de $clientIp : $filename");

          request.response.write("✅ Fichier reçu !");
          await request.response.close();
        } else if (request.method == 'GET' && request.uri.path == '/files') {
          final files = Directory(storageDir)
              .listSync()
              .whereType<File>()
              .map((f) => path.basename(f.path))
              .toList();
          request.response
            ..headers.contentType = ContentType.json
            ..write(files);
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

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _addLog("🛑 Serveur arrêté");
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
}

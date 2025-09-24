import 'dart:io';

class SimpleLocalServer {
  HttpServer? _server;
  bool get isRunning => _server != null;

  Future<void> start({int port = 8080}) async {
    if (_server != null) return;

    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    print("✅ Serveur lancé sur ${_server!.address.address}:$port");

    _server!.listen((HttpRequest request) async {
      if (request.uri.path == '/') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write("<h1>✅ Serveur actif</h1><p>IP: ${_server!.address.address}</p>");
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write("404 - Page non trouvée");
      }
      await request.response.close();
    });
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    print("🛑 Serveur arrêté");
  }
}

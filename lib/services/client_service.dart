import 'dart:io';

class ClientService {
  Socket? _socket;

  Future<void> connect(String host, int port, Function(String) onMessage) async {
    try {
      _socket = await Socket.connect(host, port);
      onMessage("Connecté au serveur $host:$port");

      _socket!.listen((data) {
        onMessage(String.fromCharCodes(data));
      }, onDone: () {
        onMessage("Déconnecté du serveur");
      });
    } catch (e) {
      onMessage("Erreur connexion: $e");
    }
  }

  void sendMessage(String msg) {
    _socket?.write("$msg\n");
  }

  void disconnect() {
    _socket?.close();
    _socket = null;
  }
}

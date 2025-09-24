import 'dart:io';

class SocketService {
  ServerSocket? _server;
  Socket? _client;
  
  // Callbacks pour la communication avec l'UI
  Function(String)? onClientConnected;
  Function(String)? onMessageReceived;
  Function(String)? onLogMessage;
  Function()? onServerStarted;
  Function()? onServerStopped;

  /// Vérifie si le serveur est en cours d'exécution
  bool get isServerRunning => _server != null;

  /// Lance un serveur local (host)
  Future<void> startServer({int port = 8889}) async {
    try {
      _server = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        port,
        shared: true,
      );

      onLogMessage?.call("✅ Serveur lancé sur le port $port");
      onServerStarted?.call();

      _server?.listen((client) {
        final clientIp = client.remoteAddress.address;
        onLogMessage?.call("Nouvelle connexion : $clientIp");
        onClientConnected?.call(clientIp);
        
        client.listen((data) {
          final message = String.fromCharCodes(data);
          onLogMessage?.call("Message reçu de $clientIp : $message");
          onMessageReceived?.call(message);
        });
        
        // Gérer la déconnexion du client
        client.done.then((_) {
          onLogMessage?.call("👤 Client déconnecté : $clientIp");
        });
      });

    } catch (e) {
      onLogMessage?.call("❌ Erreur lors du démarrage du serveur : $e");
      rethrow;
    }
  }

  /// Se connecte à un serveur local
  Future<void> connectToServer(String host, {int port = 8889}) async {
    try {
      _client = await Socket.connect(host, port);
      onLogMessage?.call("✅ Connecté à $host:$port");
    } catch (e) {
      onLogMessage?.call("❌ Erreur de connexion à $host:$port : $e");
      rethrow;
    }
  }

  /// Envoie un message (client -> serveur)
  void sendMessage(String message) {
    if (_client != null) {
      _client?.write(message);
      onLogMessage?.call("📤 Message envoyé : $message");
    } else {
      onLogMessage?.call("❌ Aucun client connecté pour envoyer un message");
    }
  }

  /// Arrête le serveur
  void stopServer() {
    _server?.close();
    _server = null;
    onLogMessage?.call("🛑 Serveur arrêté");
    onServerStopped?.call();
  }

  /// Test de ping pour vérifier si le serveur répond
  Future<bool> testServerConnection(String host, {int port = 8889, int timeoutSeconds = 5}) async {
    try {
      final socket = await Socket.connect(host, port)
          .timeout(Duration(seconds: timeoutSeconds));
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }
}

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
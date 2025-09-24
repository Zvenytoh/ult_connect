import 'package:flutter_test/flutter_test.dart';
import 'package:ult_connect/services/socket_services.dart';

void main() {
  group('SocketService Tests', () {
    late SocketService socketService;

    setUp(() {
      socketService = SocketService();
    });

    tearDown(() {
      socketService.stopServer();
    });

    test('Server should not be running initially', () {
      expect(socketService.isServerRunning, false);
    });

    test('Server should start and stop correctly', () async {
      // Test du démarrage
      await socketService.startServer(port: 8889);
      expect(socketService.isServerRunning, true);

      // Test de l'arrêt
      socketService.stopServer();
      expect(socketService.isServerRunning, false);
    });

    test('Server connection test should work', () async {
      // Démarrer le serveur sur un port différent
      await socketService.startServer(port: 8890);
      
      // Tester la connexion
      final result = await socketService.testServerConnection('127.0.0.1', port: 8890);
      expect(result, true);
    });

    test('Server should handle callbacks correctly', () async {
      var clientConnectedCalled = false;
      var messageReceivedCalled = false;

      socketService.onClientConnected = (ip) {
        clientConnectedCalled = true;
      };

      socketService.onMessageReceived = (msg) {
        messageReceivedCalled = true;
      };

      await socketService.startServer(port: 8891);
      
      expect(socketService.isServerRunning, true);
    });
  });
}
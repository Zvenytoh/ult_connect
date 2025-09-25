import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

class AddServer extends StatefulWidget {
  const AddServer({super.key});

  @override
  State<AddServer> createState() => _AddServerState();
}

class _AddServerState extends State<AddServer> {
  bool isServerRunning = false;
  String serverIp = 'Chargement...';
  int serverPort = 8080;
  List<String> connectedClients = [];
  late HttpServer _server;
  final List<WebSocket> _webSocketClients = [];
  int _totalConnections = 0;

  @override
  void initState() {
    super.initState();
    _getLocalIp();
  }

  Future<void> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            setState(() {
              serverIp = addr.address;
            });
            return;
          }
        }
      }
      setState(() {
        serverIp = 'Non disponible';
      });
    } catch (e) {
      setState(() {
        serverIp = 'Erreur: $e';
      });
    }
  }

  Future<void> _startServer() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, serverPort);
      
      setState(() {
        isServerRunning = true;
        connectedClients.clear();
        _totalConnections = 0;
      });

      // Ajouter l'adresse IP locale à la liste des clients
      _addClient('Localhost (127.0.0.1)');
      
      print('✅ Serveur démarré sur http://$serverIp:$serverPort');

      // Gérer les requêtes HTTP
      _server.listen((HttpRequest request) async {
        _handleRequest(request);
      });

    } catch (e) {
      print('❌ Erreur démarrage serveur: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleRequest(HttpRequest request) {
    final clientIp = request.connectionInfo!.remoteAddress.address;
    final clientInfo = '$clientIp (${DateTime.now().formatTime()})';
    
    // Ajouter le client à la liste
    _addClient(clientInfo);
    
    // Répondre selon le type de requête
    if (request.uri.path == '/status') {
      _serveStatus(request);
    } else if (request.uri.path == '/files') {
      _serveFileList(request);
    } else {
      _serveHomePage(request);
    }
  }

  void _addClient(String clientInfo) {
    if (!connectedClients.contains(clientInfo)) {
      setState(() {
        connectedClients.add(clientInfo);
        _totalConnections++;
      });
      
      // Supprimer après 2 minutes pour garder la liste propre
      Future.delayed(const Duration(minutes: 2), () {
        if (mounted) {
          setState(() {
            connectedClients.remove(clientInfo);
          });
        }
      });
    }
  }

  void _serveHomePage(HttpRequest request) {
    final response = '''
    <html>
      <head>
        <title>Serveur Flutter</title>
        <style>
          body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
          .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }
          .status { background: #4CAF50; color: white; padding: 10px; border-radius: 5px; }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>🚀 Serveur Flutter Actif</h1>
          <div class="status">
            <strong>IP:</strong> $serverIp<br>
            <strong>Port:</strong> $serverPort<br>
            <strong>Statut:</strong> ✅ En ligne
          </div>
          <h3>Endpoints disponibles:</h3>
          <ul>
            <li><a href="/status">/status</a> - Statut du serveur</li>
            <li><a href="/files">/files</a> - Liste des fichiers</li>
          </ul>
        </div>
      </body>
    </html>
    ''';
    
    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.html
      ..write(response)
      ..close();
  }

  void _serveStatus(HttpRequest request) {
    final status = {
      'server_ip': serverIp,
      'port': serverPort,
      'status': 'running',
      'clients_connected': connectedClients.length,
      'total_connections': _totalConnections,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(json.encode(status))
      ..close();
  }

  void _serveFileList(HttpRequest request) {
    final files = {
      'files': [
        {'name': 'document.pdf', 'size': '1.2 MB', 'type': 'PDF'},
        {'name': 'image.jpg', 'size': '450 KB', 'type': 'Image'},
        {'name': 'data.json', 'size': '15 KB', 'type': 'JSON'},
      ]
    };
    
    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(json.encode(files))
      ..close();
  }

  Future<void> _stopServer() async {
    try {
      await _server.close(force: true);
      for (var client in _webSocketClients) {
        await client.close();
      }
      
      setState(() {
        isServerRunning = false;
        connectedClients.clear();
      });
      
      print('🛑 Serveur arrêté');
    } catch (e) {
      print('Erreur arrêt serveur: $e');
    }
  }

  Future<void> _testServer() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('http://localhost:$serverPort/status'));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Serveur fonctionne correctement'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur test: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un serveur'),
        backgroundColor: Colors.green,
        actions: [
          if (isServerRunning)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _testServer,
              tooltip: 'Tester le serveur',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Statut du serveur
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          isServerRunning ? Icons.check_circle : Icons.error,
                          color: isServerRunning ? Colors.green : Colors.red,
                          size: 30,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isServerRunning ? 'SERVEUR ACTIF' : 'SERVEUR INACTIF',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isServerRunning ? Colors.green : Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'IP: $serverIp',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Port: $serverPort',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (isServerRunning) ...[
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Clients', connectedClients.length.toString()),
                          _buildStatItem('Connexions', _totalConnections.toString()),
                          _buildStatItem('Port', serverPort.toString()),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Bouton Start/Stop
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isServerRunning ? _stopServer : _startServer,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      backgroundColor: isServerRunning ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      isServerRunning ? 'ARRÊTER LE SERVEUR' : 'DÉMARRER LE SERVEUR',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            
            if (isServerRunning) ...[
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _testServer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('TESTER LA CONNEXION'),
              ),
            ],
            
            const SizedBox(height: 30),
            
            // Clients connectés
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📱 CLIENTS CONNECTÉS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: connectedClients.isEmpty
                          ? const Center(
                              child: Text(
                                'Aucun client connecté',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: connectedClients.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  leading: const Icon(Icons.computer, color: Colors.green),
                                  title: Text(connectedClients[index]),
                                  trailing: const Icon(Icons.wifi, color: Colors.blue),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isServerRunning
          ? FloatingActionButton(
              onPressed: () {
                // Copier l'URL dans le presse-papier
                // _copyToClipboard('http://$serverIp:$serverPort');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('URL copiée: http://$serverIp:$serverPort'),
                  ),
                );
              },
              child: const Icon(Icons.link),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  @override
  void dispose() {
    if (isServerRunning) {
      _stopServer();
    }
    super.dispose();
  }
}

// Extension pour formater l'heure
extension DateTimeExtension on DateTime {
  String formatTime() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
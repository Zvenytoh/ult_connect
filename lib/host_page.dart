import 'package:flutter/material.dart';

class HostPage extends StatefulWidget {
  const HostPage({super.key});

  @override
  State<HostPage> createState() => _HostPageState();
}

class _HostPageState extends State<HostPage> {
  bool isServerRunning = false;
  String serverIp = '192.168.1.10'; // Exemple
  List<String> connectedClients = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Être le Host'),
        backgroundColor: Colors.green,
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
                    Icon(
                      isServerRunning ? Icons.check_circle : Icons.error,
                      color: isServerRunning ? Colors.green : Colors.red,
                      size: 50,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isServerRunning ? 'Serveur Actif' : 'Serveur Inactif',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('IP: $serverIp'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Bouton Start/Stop
            ElevatedButton(
              onPressed: isServerRunning ? _stopServer : _startServer,
              style: ElevatedButton.styleFrom(
                backgroundColor: isServerRunning ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(
                isServerRunning ? 'ARRÊTER LE SERVEUR' : 'DÉMARRER LE SERVEUR',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Clients connectés
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clients connectés (${connectedClients.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: connectedClients.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucun client connecté',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: connectedClients.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                leading: const Icon(Icons.person),
                                title: Text('Client ${index + 1}'),
                                subtitle: Text(connectedClients[index]),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startServer() {
    setState(() {
      isServerRunning = true;
      // Simuler l'ajout de clients pour la démo
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          connectedClients.add('192.168.1.15');
        });
      });
    });
  }

  void _stopServer() {
    setState(() {
      isServerRunning = false;
      connectedClients.clear();
    });
  }
}

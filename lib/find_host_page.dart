import 'package:flutter/material.dart';

class FindHostPage extends StatefulWidget {
  const FindHostPage({super.key});

  @override
  State<FindHostPage> createState() => _FindHostPageState();
}

class _FindHostPageState extends State<FindHostPage> {
  String serverIp = '';
  bool isConnected = false;
  String userCode = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trouver un Host'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Champ de saisie IP
            TextField(
              decoration: const InputDecoration(
                labelText: 'Adresse IP du serveur',
                hintText: 'ex: 192.168.1.10',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => serverIp = value),
            ),
            
            const SizedBox(height: 20),
            
            // Bouton connexion
            ElevatedButton(
              onPressed: isConnected ? _disconnect : _connectToServer,
              style: ElevatedButton.styleFrom(
                backgroundColor: isConnected ? Colors.red : Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(
                isConnected ? 'SE DÉCONNECTER' : 'SE CONNECTER',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Statut connexion
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      isConnected ? Icons.wifi : Icons.wifi_off,
                      color: isConnected ? Colors.green : Colors.red,
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isConnected ? 'Connecté au serveur' : 'Non connecté',
                      style: const TextStyle(fontSize: 18),
                    ),
                    if (isConnected) ...[
                      const SizedBox(height: 10),
                      Text('Votre code: $userCode'),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Bouton envoyer fichier (visible seulement si connecté)
            if (isConnected)
              ElevatedButton(
                onPressed: _sendFile,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.file_upload),
                      SizedBox(width: 10),
                      Text('Envoyer un fichier'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _connectToServer() {
    setState(() {
      isConnected = true;
      userCode = 'X7B9K2'; // Code généré par le serveur
    });
  }

  void _disconnect() {
    setState(() {
      isConnected = false;
      userCode = '';
    });
  }

  void _sendFile() {
    // À implémenter plus tard
    print('Envoi du fichier...');
  }
}
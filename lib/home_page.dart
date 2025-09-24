import 'package:flutter/material.dart';
import 'digital_identity_page.dart';
import 'host_page.dart';
import 'find_host_page.dart';
import 'encrypt_and_send_page.dart'; // 👈 import de la nouvelle page

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ult Connect'),
        backgroundColor: Colors.blue[700],
      ),
      body: Center(
        child: SingleChildScrollView( // pour éviter les débordements
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bouton Identité Numérique
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DigitalIdentityPage()),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.badge, size: 40),
                        SizedBox(height: 10),
                        Text('Identité Numérique', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Bouton Être le Host
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HostPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.computer, size: 40),
                        SizedBox(height: 10),
                        Text('Être le Host', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Bouton Trouver un Host
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FindHostPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.search, size: 40),
                        SizedBox(height: 10),
                        Text('Trouver un Host', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Nouveau bouton : Chiffrer & Envoyer un fichier
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EncryptAndSendPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.lock, size: 40),
                        SizedBox(height: 10),
                        Text('Chiffrer & Envoyer', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

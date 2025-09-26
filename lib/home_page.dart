import 'package:flutter/material.dart';
import 'package:ult_connect/file_manager_page.dart';
import 'digital_identity_page.dart';
import 'host_page.dart';
import 'find_host_page.dart';
import 'service/bluetooth_page.dart';
import 'inventory_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ult Connect'),
        backgroundColor: Colors.blue[700],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Bouton Identité Numérique
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DigitalIdentityPage()),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.badge, size: 40),
                        SizedBox(height: 10),
                        Text('Identité Numérique',
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              
              // Bouton Échange Bluetooth
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BluetoothPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.bluetooth, size: 40),
                        SizedBox(height: 10),
                        Text('Échange Bluetooth', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Bouton Être le Host
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HostPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(height: 10),
                        Text('Être le Host', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Bouton Trouver un Host
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FindHostPage()),
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

              const SizedBox(height: 20),

              // Bouton Gestionnaire de Fichiers
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FileManagerPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.folder, size: 40),
                        SizedBox(height: 10),
                        Text('Fichiers', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Bouton Inventaire
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => InventoryPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.inventory, size: 40),
                        SizedBox(height: 10),
                        Text('Inventaire', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20), // Espace final pour le défilement
            ],
          ),
        ),
      ),
    );
  }
}
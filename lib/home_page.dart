import 'package:flutter/material.dart';
import 'package:ult_connect/digital_identity_page.dart';
import 'package:ult_connect/client_page.dart';
import 'package:ult_connect/server_page.dart';
import 'service/bluetooth_page.dart';
import 'inventory_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ult Connect',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[800],
        centerTitle: true,
        elevation: 4,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            children: [
              _buildMenuCard(
                context,
                icon: Icons.computer,
                label: "Démarrer Serveur",
                color: Colors.green.shade600,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ServerPage()),
                ),
              ),
              _buildMenuCard(
                context,
                icon: Icons.search,
                label: "Trouver un Host",
                color: Colors.orange.shade600,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ClientPage()),
                ),
              ),
              _buildMenuCard(
                context,
                icon: Icons.badge,
                label: "Identité Numérique",
                color: Colors.blue.shade700,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const DigitalIdentityPage()),
                ),
              ),
              _buildMenuCard(
                context,
                icon: Icons.inventory,
                label: "Inventaire",
                color: Colors.teal.shade700,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const InventoryPage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:ult_connect/digital_identity_page.dart';
import 'package:ult_connect/client_page.dart';
import 'package:ult_connect/server_page.dart'; // <-- Page pour gérer le serveur

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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Identité Numérique
              _buildMenuCard(
                context,
                icon: Icons.badge,
                label: "Identité Numérique",
                color: Colors.blue.shade600,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DigitalIdentityPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Démarrer Serveur
              _buildMenuCard(
                context,
                icon: Icons.computer,
                label: "Démarrer Serveur",
                color: Colors.green.shade600,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ServerPage()),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Trouver un Host (Client)
              _buildMenuCard(
                context,
                icon: Icons.search,
                label: "Trouver un Host",
                color: Colors.orange.shade600,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ClientPage()),
                  );
                },
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
    return SizedBox(
      width: 280,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(20),
          ),
          child: Column(
            children: [
              Icon(icon, size: 42, color: Colors.white),
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

import 'package:flutter/material.dart';
import 'package:ult_connect/digital_identity_page.dart';
import 'package:ult_connect/find_host_page.dart';
import 'package:ult_connect/server_monitoring_page.dart';
import 'package:ult_connect/simple_local_server.dart';

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

              // Être le Host (Serveur Local)
              _buildMenuCard(
                context,
                icon: Icons.computer,
                label: "Démarrer Serveur Local",
                color: Colors.green.shade600,
                onTap: () => _startServer(context),
              ),
              const SizedBox(height: 20),

              // Trouver un Host
              _buildMenuCard(
                context,
                icon: Icons.search,
                label: "Trouver un Host",
                color: Colors.orange.shade600,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FindHostPage()),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              // Monitoring Serveur
              _buildSecondaryButton(
                context,
                icon: Icons.monitor,
                label: "Monitor Serveur",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServerMonitorPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startServer(BuildContext context) async {
    final server = SimpleLocalServer();
    bool success = await server.startServer(8080, bindTo: '0.0.0.0');
    
    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServerMonitorPage(server: server),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: Port 8080 peut-être déjà utilisé'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Widget _buildSecondaryButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 280,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue[800],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.blue.shade300 ?? Colors.blue,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.blue[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class DigitalIdentityPage extends StatefulWidget {
  const DigitalIdentityPage({super.key});

  @override
  State<DigitalIdentityPage> createState() => _DigitalIdentityPageState();
}

class _DigitalIdentityPageState extends State<DigitalIdentityPage> {
  String name = '';
  String email = '';
  String phone = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identité Numérique'),
        backgroundColor: Colors.blue[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Photo de profil
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Formulaire
            TextField(
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => name = value),
            ),
            
            const SizedBox(height: 15),
            
            TextField(
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => email = value),
            ),
            
            const SizedBox(height: 15),
            
            TextField(
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => phone = value),
            ),
            
            const SizedBox(height: 30),
            
            ElevatedButton(
              onPressed: _saveIdentity,
              child: const Text('Sauvegarder l\'identité'),
            ),
          ],
        ),
      ),
    );
  }

  void _pickImage() {
    // À implémenter plus tard
    print('Sélection d\'image');
  }

  void _saveIdentity() {
    // À implémenter plus tard
    print('Sauvegarde de l\'identité: $name, $email, $phone');
  }
}
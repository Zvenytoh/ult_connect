import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DigitalIdentityPage extends StatefulWidget {
  const DigitalIdentityPage({super.key});

  @override
  State<DigitalIdentityPage> createState() => _DigitalIdentityPageState();
}

class _DigitalIdentityPageState extends State<DigitalIdentityPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  // Charger les données sauvegardées avec plus de débogage
  void _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      String name = prefs.getString('name') ?? 'Non trouvé';
      String email = prefs.getString('email') ?? 'Non trouvé';
      String phone = prefs.getString('phone') ?? 'Non trouvé';
      
      print('Chargement des données:');
      print('Nom: $name');
      print('Email: $email');
      print('Téléphone: $phone');
      
      if (mounted) {
        setState(() {
          _nameController.text = name != 'Non trouvé' ? name : '';
          _emailController.text = email != 'Non trouvé' ? email : '';
          _phoneController.text = phone != 'Non trouvé' ? phone : '';
        });
      }
    } catch (e) {
      print('Erreur lors du chargement: $e');
    }
  }

  // Sauvegarder les données avec plus de débogage
  void _saveIdentity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('name', _nameController.text);
      await prefs.setString('email', _emailController.text);
      await prefs.setString('phone', _phoneController.text);
      
      // Forcer l'écriture immédiate
      await prefs.reload();
      
      print('Sauvegarde réussie:');
      print('Nom: ${_nameController.text}');
      print('Email: ${_emailController.text}');
      print('Téléphone: ${_phoneController.text}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informations sauvegardées avec succès !'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Méthode pour vérifier manuellement les données sauvegardées
  void _checkSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    print('=== VÉRIFICATION DES DONNÉES SAUVEGARDÉES ===');
    print('Nom: ${prefs.getString('name') ?? 'NULL'}');
    print('Email: ${prefs.getString('email') ?? 'NULL'}');
    print('Téléphone: ${prefs.getString('phone') ?? 'NULL'}');
    print('============================================');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identité Numérique'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: _checkSavedData,
            tooltip: 'Vérifier les données sauvegardées',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
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
            
            const SizedBox(height: 30),
            
            // Formulaire
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            
            const SizedBox(height: 15),
            
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            
            const SizedBox(height: 15),
            
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            
            const SizedBox(height: 30),
            
            ElevatedButton(
              onPressed: _saveIdentity,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Sauvegarder l\'identité',
                style: TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _checkSavedData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Vérifier les données sauvegardées'),
            ),
          ],
        ),
      ),
    );
  }

  void _pickImage() {
    print('Sélection d\'image');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
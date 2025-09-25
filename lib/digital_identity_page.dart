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
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _nationalityController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  
  String _selectedBloodType = 'Non spécifié';
  final List<String> _bloodTypes = [
    'Non spécifié',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  // Charger les données sauvegardées
  void _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _nameController.text = prefs.getString('name') ?? '';
        _emailController.text = prefs.getString('email') ?? '';
        _phoneController.text = prefs.getString('phone') ?? '';
        _weightController.text = prefs.getString('weight') ?? '';
        _heightController.text = prefs.getString('height') ?? '';
        _nationalityController.text = prefs.getString('nationality') ?? '';
        _birthDateController.text = prefs.getString('birthDate') ?? '';
        _selectedBloodType = prefs.getString('bloodType') ?? 'Non spécifié';
      });
    } catch (e) {
      print('Erreur lors du chargement: $e');
    }
  }

  // Sauvegarder les données
  void _saveIdentity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('name', _nameController.text);
      await prefs.setString('email', _emailController.text);
      await prefs.setString('phone', _phoneController.text);
      await prefs.setString('weight', _weightController.text);
      await prefs.setString('height', _heightController.text);
      await prefs.setString('nationality', _nationalityController.text);
      await prefs.setString('birthDate', _birthDateController.text);
      await prefs.setString('bloodType', _selectedBloodType);
      
      await prefs.reload();
      
      print('Sauvegarde réussie avec tous les champs');

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

  // Sélecteur de date
  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('fr'),
    );
    
    if (picked != null) {
      setState(() {
        _birthDateController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  // Méthode pour vérifier manuellement les données sauvegardées
  void _checkSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    print('=== VÉRIFICATION DES DONNÉES SAUVEGARDÉES ===');
    print('Nom: ${prefs.getString('name') ?? 'NULL'}');
    print('Email: ${prefs.getString('email') ?? 'NULL'}');
    print('Téléphone: ${prefs.getString('phone') ?? 'NULL'}');
    print('Poids: ${prefs.getString('weight') ?? 'NULL'}');
    print('Taille: ${prefs.getString('height') ?? 'NULL'}');
    print('Nationalité: ${prefs.getString('nationality') ?? 'NULL'}');
    print('Date naissance: ${prefs.getString('birthDate') ?? 'NULL'}');
    print('Groupe sanguin: ${prefs.getString('bloodType') ?? 'NULL'}');
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
      body: SingleChildScrollView(
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
            
            // Section Informations personnelles
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Informations personnelles',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 15),
            
            // Nom complet
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            
            const SizedBox(height: 15),
            
            // Email
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
            
            // Téléphone
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            
            const SizedBox(height: 15),
            
            // Date de naissance
            TextField(
              controller: _birthDateController,
              decoration: const InputDecoration(
                labelText: 'Date de naissance',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cake),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: _selectBirthDate,
            ),
            
            const SizedBox(height: 15),
            
            // Nationalité
            TextField(
              controller: _nationalityController,
              decoration: const InputDecoration(
                labelText: 'Nationalité',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Section Informations physiques
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Informations physiques',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ),
            const SizedBox(height: 15),
            
            // Poids et Taille sur la même ligne
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Poids (kg)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monitor_weight),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: 'Taille (cm)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.height),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Section Informations médicales
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Informations médicales',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
            const SizedBox(height: 15),
            
            // Groupe sanguin
            DropdownButtonFormField<String>(
              value: _selectedBloodType,
              decoration: const InputDecoration(
                labelText: 'Groupe sanguin',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.bloodtype, color: Colors.red),
              ),
              items: _bloodTypes.map((String bloodType) {
                return DropdownMenuItem<String>(
                  value: bloodType,
                  child: Text(bloodType),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedBloodType = newValue;
                  });
                }
              },
            ),
            
            const SizedBox(height: 30),
            
            // Bouton sauvegarder
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
            
            // Bouton de vérification (pour debug)
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
    _weightController.dispose();
    _heightController.dispose();
    _nationalityController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }
} 
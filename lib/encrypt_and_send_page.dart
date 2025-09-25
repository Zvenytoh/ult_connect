import 'dart:io'
    show File, Directory; // pas dispo en web mais protégé par kIsWeb
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' hide Key;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:open_file/open_file.dart';

// Import web uniquement
import 'dart:html' as html;

class EncryptAndSendPage extends StatefulWidget {
  const EncryptAndSendPage({super.key});

  @override
  State<EncryptAndSendPage> createState() => _EncryptAndSendPageState();
}

class _EncryptAndSendPageState extends State<EncryptAndSendPage> {
  Uint8List? _selectedBytes;
  String? _selectedName;
  String? _processedFilePath;
  bool _isProcessing = false;
  bool _isEncryptedFile = false; // Nouveau: pour détecter si c'est un fichier chiffré
  final TextEditingController _passCtrl = TextEditingController();

  @override
  void dispose() {
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chiffrer & Déchiffrer'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.attach_file),
              label: const Text('Sélectionner un fichier'),
              onPressed: _isProcessing ? null : () => _pickFile(),
            ),
            const SizedBox(height: 10),
            if (_selectedName != null)
              Card(
                child: ListTile(
                  leading: Icon(
                    _isEncryptedFile ? Icons.lock : Icons.insert_drive_file,
                    color: _isEncryptedFile ? Colors.orange : Colors.blue,
                  ),
                  title: Text(_selectedName!),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Taille: ${(_selectedBytes!.length / 1024).toStringAsFixed(2)} KB',
                      ),
                      if (_isEncryptedFile)
                        const Text(
                          '🔒 Fichier chiffré détecté',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.clear, color: Colors.red),
                    onPressed: _isProcessing ? null : _clearSelection,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Phrase secrète',
                border: OutlineInputBorder(),
                hintText: 'Entrez la même phrase pour chiffrer/déchiffrer',
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedBytes != null)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.lock),
                      label: const Text('Chiffrer'),
                      onPressed: _isProcessing ? null : _encryptFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isEncryptedFile ? Colors.grey : Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Déchiffrer'),
                      onPressed: _isProcessing || !_isEncryptedFile ? null : _decryptFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isEncryptedFile ? Colors.orange : Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            if (_isProcessing) 
              Column(
                children: [
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(
                    _isEncryptedFile ? 'Déchiffrement en cours...' : 'Chiffrement en cours...',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            if (_processedFilePath != null && !kIsWeb)
              Card(
                color: Colors.green[50],
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Fichier généré avec succès'),
                  subtitle: Text(_processedFilePath!.split('/').last),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => _openFile(_processedFilePath!),
                  ),
                ),
              ),
            
            // Section d'information
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Information:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• Chiffrer: Convertit un fichier normal en fichier sécurisé (.enc)'),
                    Text('• Déchiffrer: Convertit un fichier .enc en fichier original'),
                    Text('• Utilisez la même phrase secrète pour les deux opérations'),
                    Text('• Les fichiers chiffrés ont l\'extension .enc'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedBytes = null;
      _selectedName = null;
      _processedFilePath = null;
      _isEncryptedFile = false;
    });
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes == null) {
          _showError('Impossible de lire le fichier.');
          return;
        }
        
        // Vérifier si c'est un fichier chiffré
        bool isEncrypted = _isEncryptedFileFormat(file.bytes!);
        
        setState(() {
          _selectedBytes = file.bytes;
          _selectedName = file.name;
          _processedFilePath = null;
          _isEncryptedFile = isEncrypted;
        });
        
        if (isEncrypted) {
          _showMessage('✅ Fichier chiffré détecté - Prêt pour le déchiffrement');
        } else {
          _showMessage('📄 Fichier normal - Prêt pour le chiffrement');
        }
      }
    } catch (e) {
      _showError('Erreur sélection: $e');
    }
  }

  bool _isEncryptedFileFormat(Uint8List bytes) {
    if (bytes.length < 6) return false;
    
    // Vérifier le magic number "ULTC" = [85, 76, 84, 67]
    final magicBytes = bytes.sublist(0, 4);
    const expectedMagic = [85, 76, 84, 67]; // "ULTC"
    
    return const ListEquality().equals(magicBytes, expectedMagic);
  }

  Uint8List _deriveKey(String pass) {
    final digest = sha256.convert(utf8.encode(pass));
    return Uint8List.fromList(digest.bytes); // 32 bytes
  }

  IV _randomIV() {
    final rnd = Random.secure();
    final ivBytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return IV(Uint8List.fromList(ivBytes));
  }

  Future<void> _encryptFile() async {
    if (_selectedBytes == null || _selectedName == null) return;
    if (_passCtrl.text.isEmpty) {
      _showError('Veuillez entrer une phrase secrète.');
      return;
    }
    
    if (_isEncryptedFile) {
      _showError('Ce fichier est déjà chiffré. Sélectionnez un fichier normal.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final key = Key(_deriveKey(_passCtrl.text));
      final iv = _randomIV();
      final encrypter = Encrypter(
        AES(key, mode: AESMode.cbc, padding: 'PKCS7'),
      );
      final encrypted = encrypter.encryptBytes(_selectedBytes!, iv: iv);

      // Format : magic|version|ivLen|iv|cipher
      final magic = utf8.encode('ULTC');
      final version = [1];
      final ivLen = [iv.bytes.length];
      final data = <int>[];
      data.addAll(magic); // 0..3
      data.addAll(version); // 4
      data.addAll(ivLen); // 5
      data.addAll(iv.bytes); // 6..21
      data.addAll(encrypted.bytes); // 22..

      final outputFileName = '${_selectedName!}.enc';

      if (kIsWeb) {
        _downloadWeb(data, outputFileName);
        _showMessage('✅ Fichier chiffré téléchargé: $outputFileName');
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final outPath = '${dir.path}/$outputFileName';
        await File(outPath).writeAsBytes(data, flush: true);
        setState(() => _processedFilePath = outPath);
        _showMessage('✅ Fichier chiffré créé: ${outPath.split('/').last}');
      }

    } catch (e) {
      _showError('Erreur chiffrement: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _decryptFile() async {
    if (_selectedBytes == null || _selectedName == null) return;
    if (_passCtrl.text.isEmpty) {
      _showError('Veuillez entrer la phrase secrète utilisée pour le chiffrement.');
      return;
    }
    
    if (!_isEncryptedFile) {
      _showError('Ce fichier n\'est pas un fichier chiffré valide.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final bytes = _selectedBytes!;
      if (bytes.length < 22) throw Exception('Fichier trop court pour être un fichier chiffré valide.');

      // Lecture en-tête
      final magicBytes = bytes.sublist(0, 4);
      const expectedMagic = [85, 76, 84, 67]; // "ULTC"

      if (!const ListEquality().equals(magicBytes, expectedMagic)) {
        throw Exception(
          "Format non reconnu. Ce n'est pas un fichier chiffré valide.",
        );
      }

      final version = bytes[4];
      if (version != 1) throw Exception('Version non supportée: $version');

      final ivLen = bytes[5];
      final ivStart = 6;
      final ivEnd = ivStart + ivLen;

      if (ivEnd > bytes.length) throw Exception('IV invalide (fichier corrompu)');
      if (ivLen != 16) throw Exception('Longueur IV invalide: $ivLen (attendu: 16)');

      final ivBytes = bytes.sublist(ivStart, ivEnd);
      final cipher = bytes.sublist(ivEnd);

      if (cipher.isEmpty) throw Exception('Données chiffrées manquantes.');

      // Déchiffrement
      final key = Key(_deriveKey(_passCtrl.text));
      final encrypter = Encrypter(
        AES(key, mode: AESMode.cbc, padding: 'PKCS7'),
      );
      
      final decrypted = encrypter.decryptBytes(
        Encrypted(cipher),
        iv: IV(ivBytes),
      );

      // Générer le nom de fichier de sortie
      String outName;
      if (_selectedName!.toLowerCase().endsWith('.enc')) {
        outName = _selectedName!.substring(0, _selectedName!.length - 4) + '_decrypted';
      } else {
        outName = '${_selectedName!}_decrypted';
      }

      if (kIsWeb) {
        _downloadWeb(decrypted, outName);
        _showMessage('✅ Fichier déchiffré téléchargé: $outName');
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final outPath = '${dir.path}/$outName';
        await File(outPath).writeAsBytes(decrypted, flush: true);
        setState(() => _processedFilePath = outPath);
        _showMessage('✅ Fichier déchiffré créé: ${outPath.split('/').last}');
      }

    } catch (e) {
      _showError('Erreur déchiffrement: $e\n\nVérifiez que:\n• Le fichier est bien chiffré\n• La phrase secrète est correcte');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _downloadWeb(List<int> bytes, String fileName) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _openFile(String path) async {
    try {
      await OpenFile.open(path);
    } catch (e) {
      _showError('Impossible d\'ouvrir: $e');
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      )
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      )
    );
  }
}
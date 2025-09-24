import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart' hide Key;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:open_file/open_file.dart';

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
              label: const Text('Sélectionner un fichier à chiffrer'),
              onPressed: _isProcessing ? null : () => _pickFile(toEncrypt: true),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.lock_open),
              label: const Text('Sélectionner un fichier .enc à déchiffrer'),
              onPressed: _isProcessing ? null : () => _pickFile(toEncrypt: false),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
            const SizedBox(height: 12),
            if (_selectedName != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file),
                  title: Text(_selectedName!),
                  subtitle: Text(
                    'Taille: ${(_selectedBytes!.length / 1024).toStringAsFixed(2)} KB',
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
                helperText: 'Doit être la même pour chiffrer/déchiffrer',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedBytes != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_circle),
                  label: const Text('Lancer l\'opération'),
                  onPressed: _isProcessing ? null : _processFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            if (_isProcessing) const LinearProgressIndicator(),
            if (_processedFilePath != null)
              Card(
                color: Colors.green[50],
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('Opération réussie'),
                  subtitle: Text(_processedFilePath!),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => _openFile(_processedFilePath!),
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
    });
  }

  Future<void> _pickFile({required bool toEncrypt}) async {
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
        setState(() {
          _selectedBytes = file.bytes;
          _selectedName = file.name;
          _processedFilePath = null;
        });
      }
    } catch (e) {
      _showError('Erreur sélection: $e');
    }
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

  Future<void> _processFile() async {
    if (_selectedBytes == null || _selectedName == null) return;
    if (_passCtrl.text.isEmpty) {
      _showError('Veuillez entrer une phrase secrète.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      if (_selectedName!.endsWith('.enc')) {
        await _decryptFile();
      } else {
        await _encryptFile();
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _encryptFile() async {
    final key = Key(_deriveKey(_passCtrl.text));
    final iv = _randomIV();
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
    final encrypted = encrypter.encryptBytes(_selectedBytes!, iv: iv);

    // Préfixe: magic + version + ivLen + iv
    final magic = utf8.encode('ULTC');
    final version = [1];
    final ivLen = [iv.bytes.length];
    final data = <int>[];
    data.addAll(magic);
    data.addAll(version);
    data.addAll(ivLen);
    data.addAll(iv.bytes);
    data.addAll(encrypted.bytes);

    final dir = await getApplicationDocumentsDirectory();
    final outPath = '${dir.path}/${_selectedName!}.enc';
    await File(outPath).writeAsBytes(data, flush: true);

    setState(() => _processedFilePath = outPath);
    _showMessage('Fichier chiffré sauvegardé.');
  }

  Future<void> _decryptFile() async {
    final bytes = _selectedBytes!;
    if (bytes.length < 22) throw Exception('Fichier trop court.');

    final magic = utf8.decode(bytes.sublist(0, 4));
    if (magic != 'ULTC') throw Exception('Format non reconnu.');
    final ivLen = bytes[5];
    final ivBytes = bytes.sublist(6, 6 + ivLen);
    final cipher = bytes.sublist(6 + ivLen);

    final key = Key(_deriveKey(_passCtrl.text));
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
    final decrypted = encrypter.decryptBytes(Encrypted(cipher), iv: IV(ivBytes));

    final dir = await getApplicationDocumentsDirectory();
    final outPath = '${dir.path}/${_selectedName!.replaceAll(".enc", ".dec")}';
    await File(outPath).writeAsBytes(decrypted, flush: true);

    setState(() => _processedFilePath = outPath);
    _showMessage('Fichier déchiffré sauvegardé.');
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
      SnackBar(content: Text(msg), backgroundColor: Colors.blue),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ClientPage extends StatefulWidget {
  const ClientPage({super.key});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(
    text: "8080",
  );
  final List<String> _logs = [];
  List<String> _serverFiles = [];

  void _addLog(String msg) {
    setState(() => _logs.add("[${DateTime.now().toIso8601String()}] $msg"));
  }

  Future<void> _pickAndSendFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    final file = File(result.files.single.path!);
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8080;

    try {
      final uri = Uri.parse("http://$ip:$port/upload");
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final respBody = await response.stream.bytesToString();
      _addLog(respBody);
      _listServerFiles();
    } catch (e) {
      _addLog("❌ Erreur envoi fichier : $e");
    }
  }

  Future<void> _listServerFiles() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8080;
    try {
      final uri = Uri.parse("http://$ip:$port/files");
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        setState(
          () => _serverFiles = List<String>.from(jsonDecode(response.body)),
        );
      } else {
        _addLog("❌ Impossible de lister les fichiers : ${response.statusCode}");
      }
    } catch (e) {
      _addLog("❌ Erreur récupération fichiers : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Client")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(labelText: "IP du serveur"),
            ),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(labelText: "Port"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _pickAndSendFile,
              child: const Text("Envoyer un fichier"),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _listServerFiles,
              child: const Text("Lister les fichiers serveur"),
            ),
            const Divider(),
            const Text(
              "Fichiers sur serveur:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _serverFiles.length,
                itemBuilder: (context, index) =>
                    ListTile(title: Text(_serverFiles[index])),
              ),
            ),
            const Divider(),
            const Text("Logs:", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) =>
                    ListTile(title: Text(_logs[index])),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

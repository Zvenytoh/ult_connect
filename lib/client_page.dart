import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

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

  void _addLog(String msg) =>
      setState(() => _logs.add("[${DateTime.now().toIso8601String()}] $msg"));

  Future<void> _pickAndSendFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    final file = File(result.files.single.path!);
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8080;

    try {
      final uri = Uri.parse("http://$ip:$port/upload");
      final request = http.MultipartRequest('POST', uri);

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      );

      final response = await request.send();
      final respBody = await response.stream.bytesToString();
      _addLog("✅ $respBody");

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
            // --- Connexion au serveur ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.cloud),
                      title: Text(
                        "Connexion au serveur",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        labelText: "IP du serveur",
                        prefixIcon: Icon(Icons.lan),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: "Port",
                        prefixIcon: Icon(Icons.numbers),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickAndSendFile,
                          icon: const Icon(Icons.upload_file),
                          label: const Text("Envoyer un fichier"),
                        ),
                        ElevatedButton.icon(
                          onPressed: _listServerFiles,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Lister fichiers"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --- Fichiers serveur ---
            Expanded(
              flex: 2,
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ListTile(
                      leading: Icon(Icons.folder),
                      title: Text(
                        "Fichiers sur le serveur",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _serverFiles.isEmpty
                          ? const Center(
                              child: Text("Aucun fichier disponible"),
                            )
                          : ListView.builder(
                              itemCount: _serverFiles.length,
                              itemBuilder: (context, index) => ListTile(
                                leading: const Icon(Icons.insert_drive_file),
                                title: Text(_serverFiles[index]),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --- Logs ---
            Expanded(
              flex: 2,
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ListTile(
                      leading: Icon(Icons.list_alt),
                      title: Text(
                        "Logs",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _logs.isEmpty
                          ? const Center(
                              child: Text("Aucun log pour le moment"),
                            )
                          : ListView.builder(
                              itemCount: _logs.length,
                              itemBuilder: (context, index) => ListTile(
                                dense: true,
                                title: Text(
                                  _logs[index],
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

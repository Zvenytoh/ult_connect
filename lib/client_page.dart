import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
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

  List<String> _serverFiles = [];
  final List<String> _logs = [];

  void _addLog(String msg) {
    setState(() => _logs.add("[${DateTime.now().toIso8601String()}] $msg"));
  }

  String get _serverAddress =>
      "${_ipController.text.trim()}:${_portController.text.trim()}";

  // --- Se connecter / récupérer fichiers ---
  Future<void> _fetchServerFiles() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8080;

    if (ip.isEmpty) {
      _addLog("❌ IP serveur non renseignée");
      return;
    }

    try {
      final uri = Uri.parse("http://$ip:$port/files");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        setState(
          () => _serverFiles = List<String>.from(jsonDecode(response.body)),
        );
        _addLog("✅ Liste des fichiers récupérée depuis $ip:$port");
      } else {
        _addLog("❌ Erreur récupération fichiers : ${response.statusCode}");
      }
    } catch (e) {
      _addLog("❌ Erreur récupération fichiers : $e");
    }
  }

  // --- Envoyer un fichier ---
  Future<void> _pickAndSendFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    final file = File(result.files.single.path!);
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8080;

    if (ip.isEmpty) {
      _addLog("❌ IP serveur non renseignée");
      return;
    }

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
      _addLog(respBody);

      // Rafraîchir la liste après envoi
      await _fetchServerFiles();
    } catch (e) {
      _addLog("❌ Erreur envoi fichier : $e");
    }
  }

  // --- Télécharger un fichier ---
  Future<void> _downloadFile(String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');

      final url =
          "http://${_ipController.text.trim()}:${_portController.text.trim()}/files/$fileName";
      final request = await HttpClient().getUrl(Uri.parse(url));
      final response = await request.close();
      final bytes = await consolidateHttpClientResponseBytes(response);
      await file.writeAsBytes(bytes);

      _addLog("📥 Fichier téléchargé : $fileName");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("📥 Fichier téléchargé : ${file.path}")),
        );
      }
    } catch (e) {
      _addLog("❌ Erreur téléchargement : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Client - Fichiers Serveur")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // --- IP / Port / Connecter / Envoyer ---
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      labelText: "IP du serveur",
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _portController,
                    decoration: const InputDecoration(labelText: "Port"),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _fetchServerFiles,
                  child: const Text("Connecter"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _pickAndSendFile,
                  child: const Text("Envoyer"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _fetchServerFiles,
                  child: const Text("Actualiser"),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // --- Fichiers serveur ---
            Expanded(
              flex: 2,
              child: Card(
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.folder),
                      title: Text(
                        "Fichiers disponibles sur le serveur",
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
                              itemBuilder: (context, index) {
                                final fileName = _serverFiles[index];
                                return ListTile(
                                  leading: const Icon(Icons.insert_drive_file),
                                  title: Text(fileName),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'download') {
                                        await _downloadFile(fileName);
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: 'download',
                                        child: Text("⬇️ Télécharger"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --- Logs ---
            Expanded(
              flex: 1,
              child: Card(
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.list_alt),
                      title: Text("Logs"),
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

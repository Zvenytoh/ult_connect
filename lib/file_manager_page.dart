import 'dart:typed_data';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FileManagerPage extends StatefulWidget {
  const FileManagerPage({super.key});

  @override
  State<FileManagerPage> createState() => _FileManagerPageState();
}

class _FileManagerPageState extends State<FileManagerPage> {
  List<Map<String, dynamic>> receivedFiles = [];
  final bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result != null && result.files.isNotEmpty) {
        final picked = result.files.first;
        if (picked.bytes != null) {
          setState(() {
            receivedFiles.add({
              "name": picked.name,
              "bytes": picked.bytes,
            });
          });
        }
      }
    } catch (e) {
      setState(() => _errorMessage = "Erreur lors de la sélection: $e");
    }
  }

  Future<void> _openFile(Map<String, dynamic> file) async {
    final Uint8List? bytes = file["bytes"];
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, "_blank");
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> _deleteFile(Map<String, dynamic> file) async {
    setState(() {
      receivedFiles.remove(file);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Fichier supprimé"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fichiers reçus"),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _pickFile,
            tooltip: "Sélectionner un fichier",
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (receivedFiles.isEmpty) {
      return const Center(child: Text("Aucun fichier reçu"));
    }

    return ListView.builder(
      itemCount: receivedFiles.length,
      itemBuilder: (context, index) {
        final file = receivedFiles[index];
        return ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: Text(file["name"]),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () => _openFile(file),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteFile(file),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class StorageManager {
  // Stockage temporaire pour le Web
  static final List<Map<String, dynamic>> _webFiles = [];

  /// Créer un fichier exemple
  static Future<dynamic> createSampleFile() async {
    if (kIsWeb) {
      final file = {
        'name': 'exemple.txt',
        'bytes': Uint8List.fromList('Ceci est un fichier exemple'.codeUnits),
      };
      _webFiles.add(file);
      return file;
    } else {
      // logiques existantes pour desktop/mobile
      throw UnimplementedError('Version desktop/mobile non incluse ici');
    }
  }

  /// Lister les fichiers reçus
  static Future<List<dynamic>> listReceivedFiles() async {
    if (kIsWeb) {
      return List.from(_webFiles);
    } else {
      throw UnimplementedError('Version desktop/mobile non incluse ici');
    }
  }

  /// Sauvegarder un fichier reçu
  static Future<dynamic> saveReceivedFile(
      Uint8List data, String fileName) async {
    if (kIsWeb) {
      final file = {'name': fileName, 'bytes': data};
      _webFiles.add(file);
      return file;
    } else {
      throw UnimplementedError('Version desktop/mobile non incluse ici');
    }
  }
}

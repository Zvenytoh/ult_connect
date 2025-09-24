import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:open_file/open_file.dart';

class PdfConverterPage extends StatefulWidget {
  const PdfConverterPage({super.key});

  @override
  State<PdfConverterPage> createState() => _PdfConverterPageState();
}

class _PdfConverterPageState extends State<PdfConverterPage> {
  Uint8List? selectedFileBytes;
  String? selectedFileName;
  String? convertedPdfPath;
  bool isConverting = false;
  bool isConverted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Convertisseur PDF'),
        backgroundColor: Colors.purple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Section d'information
            Card(
              color: Colors.purple[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      size: 50,
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Convertissez vos fichiers en PDF',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      selectedFileName ?? 'Aucun fichier sélectionné',
                      style: TextStyle(
                        fontSize: 14,
                        color: selectedFileName != null ? Colors.black : Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Bouton de sélection de fichier
            ElevatedButton(
              onPressed: isConverting ? null : _pickFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                minimumSize: const Size(200, 50),
              ), 
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.attach_file),
                  SizedBox(width: 10),
                  Text('Sélectionner un fichier'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Informations du fichier sélectionné
            if (selectedFileName != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, color: Colors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedFileName!,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Taille: ${selectedFileBytes != null ? (selectedFileBytes!.length / 1024).toStringAsFixed(2) : 0} KB',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: _clearSelectedFile,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Bouton de conversion
            if (selectedFileBytes != null && !isConverted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isConverting ? null : _convertToPdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: isConverting
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Conversion en cours...'),
                          ],
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.picture_as_pdf),
                            SizedBox(width: 10),
                            Text('Convertir en PDF'),
                          ],
                        ),
                ),
              ),

            const SizedBox(height: 30),

            // Résultat de la conversion
            if (isConverted && convertedPdfPath != null)
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 50,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Conversion réussie !',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Fichier PDF créé avec succès',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _openPdfFile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.open_in_new),
                                  SizedBox(width: 8),
                                  Text('Ouvrir le PDF'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _resetConverter,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh),
                                  SizedBox(width: 8),
                                  Text('Nouveau fichier'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Informations sur les formats supportés
            const Expanded(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Formats supportés:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text('• Documents texte (.txt, .doc, .docx)'),
                      Text('• Images (.jpg, .jpeg, .png, .gif)'),
                      Text('• Fichiers HTML (.html, .htm)'),
                      Text('• Fichiers PDF (recréation)'),
                      SizedBox(height: 15),
                      Text(
                        'Le fichier original sera converti en document PDF avec son contenu préservé.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'gif', 'html', 'htm', 'pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        PlatformFile platformFile = result.files.first;
        
        if (platformFile.bytes != null) {
          setState(() {
            selectedFileBytes = platformFile.bytes!;
            selectedFileName = platformFile.name;
            isConverted = false;
            convertedPdfPath = null;
          });
        } else {
          _showError('Impossible de lire le fichier sélectionné');
        }
      }
    } catch (e) {
      _showError('Erreur lors de la sélection: ${e.toString()}');
    }
  }

  Future<void> _convertToPdf() async {
    if (selectedFileBytes == null || selectedFileName == null) return;

    setState(() {
      isConverting = true;
    });

    try {
      String pdfPath = await _createPdfDocument(selectedFileBytes!, selectedFileName!);
      
      setState(() {
        convertedPdfPath = pdfPath;
        isConverting = false;
        isConverted = true;
      });

      _showSuccessMessage('Fichier converti avec succès!');

    } catch (e) {
      setState(() {
        isConverting = false;
      });
      _showError('Erreur lors de la conversion: ${e.toString()}');
    }
  }

  Future<String> _createPdfDocument(Uint8List fileBytes, String fileName) async {
    final PdfDocument document = PdfDocument();
    final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 12);
    final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 16, style: PdfFontStyle.bold);
    
    String fileExtension = fileName.toLowerCase().split('.').last;

    // Page d'accueil avec informations générales
    final PdfPage firstPage = document.pages.add();
    final PdfGraphics graphics = firstPage.graphics;

    // En-tête
    graphics.drawString(
      'Document PDF Généré',
      titleFont,
      bounds: Rect.fromLTWH(50, 50, firstPage.size.width - 100, 30),
    );

    // Informations du fichier
    graphics.drawString(
      'Nom du fichier original: $fileName',
      font,
      bounds: Rect.fromLTWH(50, 100, firstPage.size.width - 100, 20),
    );

    graphics.drawString(
      'Type: ${_getFileTypeDescription(fileExtension)}',
      font,
      bounds: Rect.fromLTWH(50, 125, firstPage.size.width - 100, 20),
    );

    graphics.drawString(
      'Taille: ${fileBytes.length} octets (${(fileBytes.length / 1024).toStringAsFixed(2)} KB)',
      font,
      bounds: Rect.fromLTWH(50, 150, firstPage.size.width - 100, 20),
    );

    graphics.drawString(
      'Date de conversion: ${DateTime.now().toString().split(' ')[0]}',
      font,
      bounds: Rect.fromLTWH(50, 175, firstPage.size.width - 100, 20),
    );

    // Contenu selon le type de fichier
    if (fileExtension == 'txt' || fileExtension == 'html' || fileExtension == 'htm') {
      await _addTextContent(document, fileBytes, fileName);
    } else if (fileExtension == 'jpg' || fileExtension == 'jpeg' || fileExtension == 'png' || fileExtension == 'gif') {
      await _addImageContent(document, fileBytes, fileName);
    } else {
      _addGenericContent(document, fileName, fileBytes.length, fileExtension);
    }

    // Sauvegarde du document
    List<int> pdfBytes = await document.save();
    document.dispose();

    // Création du fichier physique
    final Directory directory = await getApplicationDocumentsDirectory();
    final String outputPath = '${directory.path}/converted_${DateTime.now().millisecondsSinceEpoch}.pdf';
    
    final File outputFile = File(outputPath);
    await outputFile.writeAsBytes(pdfBytes);

    return outputPath;
  }

  String _getFileTypeDescription(String extension) {
    switch (extension) {
      case 'txt': return 'Document texte';
      case 'html': case 'htm': return 'Fichier HTML';
      case 'jpg': case 'jpeg': return 'Image JPEG';
      case 'png': return 'Image PNG';
      case 'gif': return 'Image GIF';
      case 'pdf': return 'Document PDF';
      default: return 'Fichier $extension';
    }
  }

  Future<void> _addTextContent(PdfDocument document, Uint8List fileBytes, String fileName) async {
    try {
      String content = String.fromCharCodes(fileBytes);
      
      // Limiter la taille pour les très gros fichiers
      if (content.length > 100000) {
        content = content.substring(0, 100000) + '\n\n... (contenu tronqué)';
      }

      final PdfPage contentPage = document.pages.add();
      final PdfGraphics graphics = contentPage.graphics;
      final PdfFont contentFont = PdfStandardFont(PdfFontFamily.helvetica, 10);

      graphics.drawString(
        'Contenu du fichier: $fileName',
        PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(50, 50, contentPage.size.width - 100, 20),
      );

      // Dessiner le contenu texte
      graphics.drawString(
        content,
        contentFont,
        bounds: Rect.fromLTWH(50, 80, contentPage.size.width - 100, contentPage.size.height - 120),
      );

    } catch (e) {
      // En cas d'erreur, ajouter une page d'information
      _addErrorPage(document, 'Erreur lors de la conversion du texte: $e');
    }
  }

  Future<void> _addImageContent(PdfDocument document, Uint8List fileBytes, String fileName) async {
    try {
      final PdfPage imagePage = document.pages.add();
      final PdfGraphics graphics = imagePage.graphics;
      final PdfBitmap image = PdfBitmap(fileBytes);

      // Calcul des dimensions pour adapter l'image à la page
      double aspectRatio = image.width / image.height;
      double maxWidth = imagePage.size.width - 100;
      double maxHeight = imagePage.size.height - 100;

      double width = maxWidth;
      double height = width / aspectRatio;

      if (height > maxHeight) {
        height = maxHeight;
        width = height * aspectRatio;
      }

      // Centrer l'image
      double x = (imagePage.size.width - width) / 2;
      double y = (imagePage.size.height - height) / 2;

      graphics.drawString(
        'Image: $fileName',
        PdfStandardFont(PdfFontFamily.helvetica, 12, style: PdfFontStyle.bold),
        bounds: Rect.fromLTWH(50, 30, imagePage.size.width - 100, 20),
      );

      graphics.drawImage(image, Rect.fromLTWH(x, 60, width, height - 30));

    } catch (e) {
      _addErrorPage(document, 'Erreur lors de la conversion de l\'image: $e');
    }
  }

  void _addGenericContent(PdfDocument document, String fileName, int fileSize, String extension) {
    final PdfPage page = document.pages.add();
    final PdfGraphics graphics = page.graphics;

    graphics.drawString(
      'Fichier: $fileName',
      PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(50, 100, page.size.width - 100, 30),
    );

    graphics.drawString(
      'Type: $extension',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(50, 140, page.size.width - 100, 20),
    );

    graphics.drawString(
      'Taille: ${(fileSize / 1024).toStringAsFixed(2)} KB',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(50, 165, page.size.width - 100, 20),
    );

    graphics.drawString(
      'Le contenu de ce type de fichier ne peut pas être affiché directement dans le PDF.',
      PdfStandardFont(PdfFontFamily.helvetica, 10),
      bounds: Rect.fromLTWH(50, 200, page.size.width - 100, 40),
    );
  }

  void _addErrorPage(PdfDocument document, String errorMessage) {
    final PdfPage page = document.pages.add();
    final PdfGraphics graphics = page.graphics;

    graphics.drawString(
      'Erreur de conversion',
      PdfStandardFont(PdfFontFamily.helvetica, 14, style: PdfFontStyle.bold),
      bounds: Rect.fromLTWH(50, 100, page.size.width - 100, 30),
    );

    graphics.drawString(
      errorMessage,
      PdfStandardFont(PdfFontFamily.helvetica, 10),
      bounds: Rect.fromLTWH(50, 140, page.size.width - 100, 100),
    );
  }

  Future<void> _openPdfFile() async {
    if (convertedPdfPath != null) {
      try {
        await OpenFile.open(convertedPdfPath!);
      } catch (e) {
        _showError('Impossible d\'ouvrir le fichier PDF: $e');
      }
    }
  }

  void _resetConverter() {
    setState(() {
      selectedFileBytes = null;
      selectedFileName = null;
      convertedPdfPath = null;
      isConverting = false;
      isConverted = false;
    });
  }

  void _clearSelectedFile() {
    setState(() {
      selectedFileBytes = null;
      selectedFileName = null;
      isConverted = false;
      convertedPdfPath = null;
    });
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
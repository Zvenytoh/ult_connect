import 'dart:io';

Future<void> testConnection(String ip, int port) async {
  try {
    final uri = Uri.parse("http://$ip:$port/");
    final request = await HttpClient().getUrl(uri);
    final response = await request.close();

    if (response.statusCode == 200) {
      print("✅ Serveur disponible !");
      final body = await response.transform(SystemEncoding().decoder).join();
      print("Réponse: $body");
    } else {
      print("❌ Serveur indisponible (${response.statusCode})");
    }
  } catch (e) {
    print("⚠️ Erreur connexion: $e");
  }
}

import 'package:flutter/material.dart';
import 'home_page.dart';

void main() async {
  // 🔑 Nécessaire pour initialiser les plugins (path_provider, file_picker, etc.)
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ult Connect',
      debugShowCheckedModeBanner: false, // ✅ pour enlever le bandeau "Debug"
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

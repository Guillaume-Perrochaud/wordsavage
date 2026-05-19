import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/welcome_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock the entire app to portrait mode
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const WordSavageApp());
}

class WordSavageApp extends StatelessWidget {
  const WordSavageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WordSavage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}
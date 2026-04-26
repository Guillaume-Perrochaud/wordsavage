import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';

void main() {
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
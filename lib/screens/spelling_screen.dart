import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SpellingScreen extends StatefulWidget {
  const SpellingScreen({super.key});

  @override
  State<SpellingScreen> createState() => _SpellingScreenState();
}

class _SpellingScreenState extends State<SpellingScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _textController = TextEditingController();

  final List<String> _wordList = [
    "apple", "banana", "elephant", "rhythm", "xylophone",
    "pneumonia", "supercalifragilisticexpialidocious", "onomatopoeia"
  ];

  int _currentIndex = 0;
  String _feedback = "";
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    Future.delayed(const Duration(milliseconds: 500), _speakCurrentWord);
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-GB");
    await _flutterTts.setSpeechRate(0.65);     // Even slower
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
    
    // These settings help reduce cracking
    await _flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _speakCurrentWord() async {
    setState(() => _isSpeaking = true);
    await _flutterTts.speak(_wordList[_currentIndex]);
    setState(() => _isSpeaking = false);
  }

  void _checkSpelling() {
    String correctWord = _wordList[_currentIndex].toLowerCase();
    String userAnswer = _textController.text.trim().toLowerCase();

    if (userAnswer == correctWord) {
      setState(() => _feedback = "✅ Savage! Correct!");
      Future.delayed(const Duration(milliseconds: 1000), _nextWord);
    } else {
      setState(() {
        _feedback = "❌ Nope. The word was: ${_wordList[_currentIndex]}";
      });
    }
  }

  void _nextWord() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _wordList.length;
      _feedback = "";
    });
    _textController.clear();
    _speakCurrentWord();
  }

  @override
  void dispose() {
    _textController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Spelling Challenge"),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              "Word ${_currentIndex + 1} / ${_wordList.length}",
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            
            const SizedBox(height: 40),

            Card(
              color: Colors.deepOrange.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      _isSpeaking ? "🔊 Speaking..." : "Listen carefully",
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _speakCurrentWord,
                      icon: const Icon(Icons.volume_up),
                      label: const Text("Repeat Word"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: "Type what you heard",
                border: OutlineInputBorder(),
                hintText: "Spell it here...",
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24),
              autofocus: true,
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _checkSpelling,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
              ),
              child: const Text("SUBMIT ANSWER", style: TextStyle(fontSize: 18)),
            ),

            const SizedBox(height: 30),

            Text(
              _feedback,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
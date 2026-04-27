import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

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
  Timer? _timer;
  int _timeLeft = 0;

  @override
  void initState() {
    super.initState();
    _initTts();
    _startNewWord();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-GB");
    await _flutterTts.setSpeechRate(0.65);
    await _flutterTts.setPitch(1.0);
  }

  void _startNewWord() {
    _textController.clear();
    _feedback = "";
    _timeLeft = _calculateTimeForWord(_wordList[_currentIndex]);
    _startTimer();
    _speakCurrentWord();
  }

  int _calculateTimeForWord(String word) {
    return 8 + (word.length * 1.2).round();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timeUp();
      }
    });
  }

  void _timeUp() {
    _timer?.cancel();
    setState(() {
      _feedback = "⏰ Time's up, mortal. The word was: ${_wordList[_currentIndex]}";
    });
    Future.delayed(const Duration(seconds: 2), _nextWord);
  }

  Future<void> _speakCurrentWord() async {
    setState(() => _isSpeaking = true);
    await _flutterTts.speak(_wordList[_currentIndex]);
    setState(() => _isSpeaking = false);
  }

  void _checkSpelling() {
    _timer?.cancel();
    String correctWord = _wordList[_currentIndex].toLowerCase();
    String userAnswer = _textController.text.trim().toLowerCase();

    if (userAnswer == correctWord) {
      setState(() => _feedback = "✅ Finally... Correct. Don't get cocky.");
      Future.delayed(const Duration(milliseconds: 1200), _nextWord);
    } else {
      setState(() {
        _feedback = "❌ Pathetic. It's spelled: ${_wordList[_currentIndex]}";
      });
      Future.delayed(const Duration(seconds: 2), _nextWord);
    }
  }

  void _nextWord() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _wordList.length;
    });
    _startNewWord();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Spell or Spit"),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Word ${_currentIndex + 1} / ${_wordList.length}",
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _timeLeft < 6 ? Colors.red : Colors.deepOrange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "⏱ $_timeLeft s",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Card(
              color: Colors.deepOrange.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      _isSpeaking ? "🔊 Speaking..." : "Listen, peasant",
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _speakCurrentWord,
                      icon: const Icon(Icons.volume_up),
                      label: const Text("Repeat"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: "Type your answer",
                border: OutlineInputBorder(),
                hintText: "Spell it here...",
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26),
              autofocus: true,
              onSubmitted: (_) => _checkSpelling(),   // Enter key support
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
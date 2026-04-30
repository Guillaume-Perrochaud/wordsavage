import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

enum InputMode { keyboard, microphone }

class SpellingScreen extends StatefulWidget {
  const SpellingScreen({super.key});

  @override
  State<SpellingScreen> createState() => _SpellingScreenState();
}

class _SpellingScreenState extends State<SpellingScreen> {
  FlutterTts? _flutterTts;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<String> _wordList = [
    "apple", "banana", "elephant", "rhythm", "xylophone",
    "pneumonia", "onomatopoeia", "quizzical", "floccinaucinihilipilification"
  ];

  int _currentIndex = 0;
  String _feedback = "";
  bool _isSpeaking = false;
  bool _isListening = false;
  Timer? _timer;
  int _timeLeft = 0;
  InputMode _mode = InputMode.keyboard;
  Timer? _micRestartTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showModeSelection());
  }

  void _showModeSelection() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("🎮 Spelling Challenge"),
        content: const Text("How savage do you want to play?"),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _mode = InputMode.keyboard);
              Navigator.pop(context);
              _showInstructions();
            },
            child: const Text("⌨️ Keyboard"),
          ),
          TextButton(
            onPressed: () {
              setState(() => _mode = InputMode.microphone);
              Navigator.pop(context);
              _showInstructions();
            },
            child: const Text("🎤 Microphone"),
          ),
        ],
      ),
    );
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("How to Play"),
        content: Text(_mode == InputMode.keyboard
            ? "Type the word **exactly** as you hear it.\nNo autocorrect allowed!"
            : "Speak **each letter** clearly one by one.\nExample: A ... P ... P ... L ... E"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewWord();
            },
            child: const Text("READY TO GET ROASTED! 🔥"),
          )
        ],
      ),
    );
  }

  Future<void> _initTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts!.setLanguage("en-GB");
    await _flutterTts!.setPitch(1.1);
    await _flutterTts!.setSpeechRate(0.7);
  }

  void _startNewWord() {
    _textController.clear();
    _feedback = "";
    _timeLeft = _calculateTimeForWord(_wordList[_currentIndex]);

    _initTts().then((_) {
      _speakCurrentWord().then((_) {
        if (!mounted) return;
        _startTimer();
        if (_mode == InputMode.keyboard) _focusNode.requestFocus();
        if (_mode == InputMode.microphone) _startPersistentListening();
      });
    });
  }

  Future<void> _speakCurrentWord() async {
    setState(() => _isSpeaking = true);
    try {
      await _flutterTts?.speak(_wordList[_currentIndex]);
    } finally {
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  int _calculateTimeForWord(String word) => 10 + (word.length * 1.2).round();

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timeUp();
      }
    });
  }

  void _timeUp() {
    _timer?.cancel();
    _flutterTts?.stop();
    if (_mode == InputMode.microphone) _stopListening();
    setState(() {
      _feedback = "⏰ Time's up! It was '${_wordList[_currentIndex]}'";
    });
    Future.delayed(const Duration(seconds: 2), _nextWord);
  }

  // === MICROPHONE PERSISTENT LISTENING ===
  void _startPersistentListening() async {
    await Permission.microphone.request();
    bool available = await _speech.initialize();
    if (!available) return;

    setState(() => _isListening = true);
    _listenOnce();

    // Auto-restart if it stops
    _micRestartTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_isListening && mounted && !_speech.isListening) {
        _listenOnce();
      }
    });
  }

  void _listenOnce() {
    _speech.listen(
      onResult: (result) {
        setState(() => _textController.text = result.recognizedWords);
      },
      listenOptions: stt.SpeechListenOptions(partialResults: true),
      listenFor: const Duration(seconds: 30),
    );
  }

  void _stopListening() {
    _micRestartTimer?.cancel();
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _checkSpelling() {
    _timer?.cancel();
    _micRestartTimer?.cancel();
    _flutterTts?.stop();
    if (_mode == InputMode.microphone) _stopListening();

    String correct = _wordList[_currentIndex].toLowerCase();
    String answer = _textController.text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');

    // Improved check - must be close but not just repeating the word
    bool isCorrect = answer == correct;
    bool isJustRepeatingWord = answer == correct && _textController.text.length <= correct.length + 3;

    setState(() {
      _feedback = isCorrect
          ? "✅ Not bad... for a human. +10 points 🔥"
          : "❌ Brutal. It's spelled: ${_wordList[_currentIndex]}";
    });

    Future.delayed(const Duration(milliseconds: 1600), _nextWord);
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
    _micRestartTimer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    _flutterTts?.stop();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("🦍 Spelling Challenge"),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          children: [
            // Timer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Text("$_timeLeft s", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),

            const SizedBox(height: 30),

            Text("Spell:", style: const TextStyle(fontSize: 22)),
            Text(
              _wordList[_currentIndex].toUpperCase(),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 6),
            ),

            const SizedBox(height: 40),

            // Input Area
            if (_mode == InputMode.keyboard)
              TextField(
                controller: _textController,
                focusNode: _focusNode,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Type here",
                ),
                style: const TextStyle(fontSize: 28),
                textCapitalization: TextCapitalization.none,
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.deepOrange, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _textController.text.isEmpty ? "🎤 Speak letters one by one..." : _textController.text,
                  style: const TextStyle(fontSize: 32),
                  textAlign: TextAlign.center,
                ),
              ),

            const Spacer(),

            // Submit Button
            ElevatedButton(
              onPressed: _checkSpelling,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(vertical: 22),
                minimumSize: const Size(double.infinity, 75),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                "SUBMIT ANSWER",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 20),
            Text(_feedback, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
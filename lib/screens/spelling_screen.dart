import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:async';

enum InputMode { keyboard, microphone }

class SpellingScreen extends StatefulWidget {
  const SpellingScreen({super.key});

  @override
  State<SpellingScreen> createState() => _SpellingScreenState();
}

class _SpellingScreenState extends State<SpellingScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechReady = false;
  bool _isListening = false;

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  final List<String> _wordList = [
    "apple", "banana", "elephant", "rhythm", "xylophone",
    "pneumonia", "onomatopoeia", "quizzical", "floccinaucinihilipilification"
  ];

  int _currentIndex = 0;
  bool _isSpeaking = false;
  Timer? _timer;
  int _timeLeft = 0;
  InputMode _mode = InputMode.keyboard;
  bool _challengeComplete = false;

  @override
  void initState() {
    super.initState();
    _configureTts();
    _initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showStartDialog());
  }

  Future<void> _configureTts() async {
    await _flutterTts.setLanguage("en-GB");
    await _flutterTts.setPitch(1.1);
    await _flutterTts.setSpeechRate(0.65);
  }

  Future<void> _initSpeech() async {
    final available = await _speechToText.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );

    if (available) {
      setState(() => _speechReady = true);
      debugPrint('✅ Speech-to-text initialized successfully');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition is not available on this device')),
      );
    }
  }

  void _showStartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("🎮 Spelling Challenge"),
        content: const Text("Choose your weapon:\n\n⌨️ Keyboard — Type exactly\n🎤 Microphone — Speak letters one by one"),
        actions: [
          TextButton(onPressed: () { setState(() => _mode = InputMode.keyboard); Navigator.pop(context); Future.delayed(const Duration(seconds: 2), _startNewWord); }, child: const Text("⌨️ Keyboard")),
          TextButton(onPressed: () { setState(() => _mode = InputMode.microphone); Navigator.pop(context); Future.delayed(const Duration(seconds: 2), _startNewWord); }, child: const Text("🎤 Microphone")),
        ],
      ),
    );
  }

  void _startNewWord() {
    if (_currentIndex >= _wordList.length) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _challengeComplete = true);
      });
      return;
    }

    _textController.clear();
    _timeLeft = _calculateTimeForWord(_wordList[_currentIndex]);

    _flutterTts.speak("Next word:").then((_) async {
      await Future.delayed(const Duration(milliseconds: 1200));
      await _speakCurrentWord();

      if (!mounted) return;
      _startTimer();
      if (_mode == InputMode.keyboard) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) _focusNode.requestFocus();
        });
      } else if (_speechReady) {
        _startListening();
      }
    });
  }

  Future<void> _speakCurrentWord() async {
    setState(() => _isSpeaking = true);
    final word = _wordList[_currentIndex];
    final rate = word.length > 12 ? 0.55 : 0.7;
    await _flutterTts.setSpeechRate(rate);
    await _flutterTts.speak(word);
    setState(() => _isSpeaking = false);
  }

  int _calculateTimeForWord(String word) => 12 + (word.length * 1.4).round();

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

  void _timeUp() => _endRound(isTimeUp: true);

  Future<void> _endRound({bool isTimeUp = false}) async {
    _timer?.cancel();
    _stopListening();

    final correctWord = _wordList[_currentIndex];
    final answer = _textController.text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final isCorrect = answer == correctWord.toLowerCase();

    String message = isTimeUp
        ? "Time's up! Better luck next time, champ."
        : isCorrect
            ? "Correct! Not too bad... for a human."
            : "Roasted! You really thought that was right?";

    await _flutterTts.setSpeechRate(0.65);
    await _flutterTts.speak(message);

    await Future.delayed(const Duration(seconds: 2));

    setState(() => _currentIndex++);
    _startNewWord();
  }

  Future<void> _startListening() async {
    if (_isListening || !_speechReady) return;

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required for speech mode')),
        );
      }
      return;
    }

    final initialized = await _speechToText.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );

    if (!initialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition is not available')),
        );
      }
      return;
    }

    setState(() => _isListening = true);

    _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: 'en_GB',
      listenOptions: SpeechListenOptions(listenMode: ListenMode.confirmation),
    );
  }

  void _stopListening() {
    if (_speechToText.isListening) {
      _speechToText.stop();
    }

    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final spoken = result.recognizedWords.toLowerCase();
    final normalized = spoken.replaceAll(RegExp(r'[^a-z]'), '');
    setState(() => _textController.text = normalized);
  }

  void _onSpeechStatus(String status) {
    if (status == 'notListening' || status == 'done') {
      if (mounted) setState(() => _isListening = false);
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    debugPrint('Speech error: ${error.errorMsg}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech error: ${error.errorMsg}')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    _flutterTts.stop();
    _speechToText.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_challengeComplete) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("🎉 Challenge Complete!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                    _challengeComplete = false;
                  });
                  _startNewWord();
                },
                child: const Text("Restart Challenge"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Back to Main Screen")),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text("🦍 Spelling Challenge"), backgroundColor: Colors.deepOrange),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer, color: Colors.deepOrange, size: 32),
                const SizedBox(width: 12),
                Text("$_timeLeft s", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _isSpeaking ? null : _speakCurrentWord,
              icon: const Icon(Icons.replay),
              label: const Text("Repeat Word"),
            ),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepOrange, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _mode == InputMode.keyboard
                  ? TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 32),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Type your spelling...',
                      ),
                      textCapitalization: TextCapitalization.none,
                      autocorrect: false,
                      enableSuggestions: false,
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: Colors.deepOrange,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _textController.text.isEmpty
                              ? '🎤 Speak each letter clearly...'
                              : _textController.text.toUpperCase(),
                          style: const TextStyle(fontSize: 32),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _endRound,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(vertical: 22),
                minimumSize: const Size(double.infinity, 70),
              ),
              child: const Text("SUBMIT ANSWER", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
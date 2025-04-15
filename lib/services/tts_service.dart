import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _flutterTts.setLanguage('id-ID');
    await _flutterTts.setSpeechRate(0.5); // Kecepatan bicara
    await _flutterTts.setVolume(1.0); // Volume
    await _flutterTts.setPitch(1.0); // Nada suara
    
    // Set engine ke Google TTS
      await _flutterTts.setEngine('com.google.android.tts');
      
      _isInitialized = true;
    } catch (e) {
      print('Error initializing TTS: $e');
      rethrow;
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print('Error speaking text: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('Error stopping TTS: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('Error disposing TTS: $e');
    }
  }
} 
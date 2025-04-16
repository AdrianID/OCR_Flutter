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
      // Set engine to Google TTS first
      await _flutterTts.setEngine('com.google.android.tts');
      
      // Get available languages
      final languages = await _flutterTts.getLanguages;
      
      // Force Indonesian language
      await _flutterTts.setLanguage('id-ID');
      
      // Get available voices
      final voices = await _flutterTts.getVoices;
     
      // Check for Indonesian voice
      if (voices != null) {
        for (final voice in voices) {
          final locale = voice['locale']?.toString().toLowerCase();
          if (locale != null && (locale.startsWith('id-') || locale == 'id')) {
           
            final Map<String, String> voiceMap = {
              'name': voice['name']?.toString() ?? '',
              'locale': voice['locale']?.toString() ?? '',
            };

            await _flutterTts.setVoice(voiceMap);
            
            break;
          }
        }
      }

      // Set voice parameters
      await _flutterTts.setSpeechRate(0.5); // Kecepatan bicara lebih lambat
      await _flutterTts.setVolume(1.0);      // Volume maksimal untuk kejelasan
      await _flutterTts.setPitch(1);       // Pitch sedikit diturunkan agar lebih nyaman
      
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
      // Ensure Indonesian language is set before speaking
      await _flutterTts.setLanguage('id-ID');
      await _flutterTts.speak(text);
    } catch (e) {
      print('Error speaking text: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('Error stopping TTS: $e');
      rethrow;
    }
  }

  Future<void> dispose() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('Error disposing TTS: $e');
      rethrow;
    }
  }
} 
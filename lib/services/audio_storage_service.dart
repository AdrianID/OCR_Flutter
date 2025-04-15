import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/audio_book.dart';
import 'tts_service.dart';

class AudioStorageService {
  static final AudioStorageService _instance = AudioStorageService._internal();
  factory AudioStorageService() => _instance;
  AudioStorageService._internal();

  static const String _audioBooksKey = 'audio_books';
  late SharedPreferences _prefs;
  final _ttsService = TTSService();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _ttsService.initialize();
  }

  Future<void> saveAudioBook(AudioBook audioBook) async {
    final audioBooks = await getAudioBooks();
    audioBooks.add(audioBook);
    await _saveAudioBooks(audioBooks);
  }

  Future<List<AudioBook>> getAudioBooks() async {
    try {
      final audioBooksJson = _prefs.getStringList(_audioBooksKey) ?? [];
      return audioBooksJson
          .map((json) => AudioBook.fromMap(jsonDecode(json)))
          .toList();
    } catch (e) {
      print('Error getting audio books: $e');
      return [];
    }
  }

  Future<void> deleteAudioBook(String id) async {
    final audioBooks = await getAudioBooks();
    audioBooks.removeWhere((book) => book.id == id);
    await _saveAudioBooks(audioBooks);
  }

  Future<void> _saveAudioBooks(List<AudioBook> audioBooks) async {
    try {
      final audioBooksJson = audioBooks
          .map((book) => jsonEncode(book.toMap()))
          .toList();
      await _prefs.setStringList(_audioBooksKey, audioBooksJson);
    } catch (e) {
      print('Error saving audio books: $e');
      rethrow;
    }
  }
} 
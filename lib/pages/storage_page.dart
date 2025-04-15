import 'package:flutter/material.dart';
import '../services/audio_storage_service.dart';
import '../services/tts_service.dart';
import '../models/audio_book.dart';

class StoragePage extends StatefulWidget {
  const StoragePage({super.key});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> {
  final _audioStorageService = AudioStorageService();
  final _ttsService = TTSService();
  List<AudioBook> _audioBooks = [];
  bool _isLoading = true;
  String? _currentlyPlayingId;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _audioStorageService.init();
    await _ttsService.initialize();
    _loadAudioBooks();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _loadAudioBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final books = await _audioStorageService.getAudioBooks();
      setState(() {
        _audioBooks = books;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat daftar buku: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAudioBook(String id) async {
    try {
      await _audioStorageService.deleteAudioBook(id);
      await _loadAudioBooks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Buku berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus buku: $e')),
        );
      }
    }
  }

  Future<void> _playAudio(AudioBook book) async {
    try {
      if (_currentlyPlayingId == book.id && _isPlaying) {
        // Jika buku yang sama sedang diputar, pause
        await _ttsService.stop();
        setState(() {
          _isPlaying = false;
        });
        return;
      }

      setState(() {
        _currentlyPlayingId = book.id;
        _isPlaying = true;
      });

      await _ttsService.speak(book.text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memutar audio: $e')),
        );
        setState(() {
          _currentlyPlayingId = null;
          _isPlaying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penyimpanan Buku'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _audioBooks.isEmpty
              ? const Center(
                  child: Text('Belum ada buku yang tersimpan'),
                )
              : ListView.builder(
                  itemCount: _audioBooks.length,
                  itemBuilder: (context, index) {
                    final book = _audioBooks[index];
                    final isPlaying = _currentlyPlayingId == book.id && _isPlaying;

                    return ListTile(
                      title: Text(book.title),
                      subtitle: Text(
                        'Dibuat pada: ${book.createdAt.toString()}',
                      ),
                      leading: IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: isPlaying ? Colors.blue : null,
                        ),
                        onPressed: () => _playAudio(book),
                        tooltip: isPlaying ? 'Jeda' : 'Putar',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteAudioBook(book.id),
                        tooltip: 'Hapus Buku',
                      ),
                    );
                  },
                ),
    );
  }
} 
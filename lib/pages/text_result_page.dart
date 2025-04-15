import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/volume_button_service.dart';
import '../services/tts_service.dart';
import '../services/audio_storage_service.dart';
import '../models/audio_book.dart';

class TextResultPage extends StatefulWidget {
  final String scannedText;

  const TextResultPage({
    super.key,
    required this.scannedText,
  });

  @override
  State<TextResultPage> createState() => _TextResultPageState();
}

class _TextResultPageState extends State<TextResultPage> {
  final _volumeButtonService = VolumeButtonService();
  final _ttsService = TTSService();
  final _audioStorageService = AudioStorageService();
  bool _isSpeaking = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _setupVolumeButtons();
    _audioStorageService.init();
    _ttsService.initialize();
  }

  void _setupVolumeButtons() {
    _volumeButtonService.onVolumeUp = () {
      if (_isSpeaking) {
        _ttsService.stop();
        setState(() {
          _isSpeaking = false;
        });
      } else {
        _readText();
      }
    };
    _volumeButtonService.onVolumeDown = () {
      if (_isSpeaking) {
        _ttsService.stop();
      }
      Navigator.of(context).pop();
    };
    _volumeButtonService.startListening();
  }

  Future<void> _readText() async {
    setState(() {
      _isSpeaking = true;
    });
    await _ttsService.speak(widget.scannedText);
    setState(() {
      _isSpeaking = false;
    });
  }

  Future<void> _saveAudioBook() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final title = 'Buku ${DateTime.now().toString()}';
      
      final audioBook = AudioBook(
        id: const Uuid().v4(),
        title: title,
        text: widget.scannedText,
        createdAt: DateTime.now(),
      );

      await _audioStorageService.saveAudioBook(audioBook);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Buku berhasil disimpan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan buku: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _volumeButtonService.stopListening();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Pemindaian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveAudioBook,
            tooltip: 'Simpan Buku',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Semantics(
                  label: 'Hasil pemindaian teks',
                  hint: 'Gunakan tombol volume atas untuk mendengarkan teks, tombol volume bawah untuk kembali',
                  child: Text(
                    widget.scannedText,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
            if (_isSpeaking || _isSaving)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
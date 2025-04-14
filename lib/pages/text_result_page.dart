import 'package:flutter/material.dart';
import '../services/volume_button_service.dart';
import '../services/tts_service.dart';

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
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _setupVolumeButtons();
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
            if (_isSpeaking)
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
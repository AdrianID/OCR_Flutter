import 'package:flutter/material.dart';
import '../services/volume_button_service.dart';

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

  @override
  void initState() {
    super.initState();
    _setupVolumeButtons();
  }

  void _setupVolumeButtons() {
    _volumeButtonService.onVolumeUp = () {
      // Volume up untuk membaca teks
      _readText();
    };
    _volumeButtonService.onVolumeDown = () {
      // Volume down untuk kembali ke halaman sebelumnya
      Navigator.of(context).pop();
    };
    _volumeButtonService.startListening();
  }

  void _readText() {
    // TODO: Implementasi text-to-speech
    // Untuk sementara kita hanya akan menampilkan snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur text-to-speech akan segera hadir'),
      ),
    );
  }

  @override
  void dispose() {
    _volumeButtonService.stopListening();
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
          ],
        ),
      ),
    );
  }
}
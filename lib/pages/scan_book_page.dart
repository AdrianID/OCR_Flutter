import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/volume_button_service.dart';

class ScanBookPage extends StatefulWidget {
  const ScanBookPage({super.key});

  @override
  State<ScanBookPage> createState() => _ScanBookPageState();
}

class _ScanBookPageState extends State<ScanBookPage> with WidgetsBindingObserver {
  bool _isPermissionGranted = false;
  late final Future<void> _future;
  CameraController? _cameraController;
  final textRecognizer = TextRecognizer();
  final _volumeButtonService = VolumeButtonService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _future = _requestCameraPermission();
    print('Babayo');
    _setupVolumeButtons();
  }

  void _setupVolumeButtons() {
    debugPrint('Setting up volume buttons...');
    _volumeButtonService.onVolumeUp = () {
      debugPrint('Volume up callback triggered');
      _scanImage();
    };
    _volumeButtonService.onVolumeDown = () {
      debugPrint('Volume down callback triggered');
      Navigator.of(context).pop();
    };
    _volumeButtonService.startListening();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    textRecognizer.close();
    _volumeButtonService.stopListening();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      _startCamera();
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    _isPermissionGranted = status == PermissionStatus.granted;
  }

  Future<void> _startCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    setState(() {});
  }

  Future<void> _stopCamera() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
    }
  }

  Future<void> _scanImage() async {
    if (_cameraController == null) return;

    try {
      final picture = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(picture.path);
      final recognizedText = await textRecognizer.processImage(inputImage);

      if (!mounted) return;

      // Navigate to result page with the recognized text
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TextResultPage(
            scannedText: recognizedText.text,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scanning text: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        return Stack(
          children: [
            if (_isPermissionGranted)
              FutureBuilder(
                future: availableCameras(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    if (_cameraController?.value.isInitialized ?? false) {
                      return CameraPreview(_cameraController!);
                    } else {
                      _startCamera();
                      return const Center(child: CircularProgressIndicator());
                    }
                  } else {
                    return const Center(
                      child: Text('No camera found'),
                    );
                  }
                },
              ),
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: const Text('Scan Buku'),
                backgroundColor: Colors.transparent,
              ),
              body: _isPermissionGranted
                  ? Column(
                      children: [
                        Expanded(
                          child: Container(),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Semantics(
                                button: true,
                                label: 'Tombol untuk memindai teks',
                                hint: 'Tekan untuk memulai pemindaian teks dari kamera atau gunakan tombol volume atas',
                                child: ElevatedButton(
                                  onPressed: _scanImage,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(16),
                                  ),
                                  child: const Text(
                                    'Pindai Teks',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        child: const Text(
                          'Camera permission is required',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class TextResultPage extends StatelessWidget {
  final String scannedText;

  const TextResultPage({
    super.key,
    required this.scannedText,
  });

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
                  child: Text(
                    scannedText,
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
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/volume_button_service.dart';
import 'text_result_page.dart';
import '../services/voice_command_service.dart';
import 'dart:io';
import 'dart:async';

class ScanBookPage extends StatefulWidget {
  const ScanBookPage({super.key});

  @override
  State<ScanBookPage> createState() => _ScanBookPageState();

  static _ScanBookPageState? of(BuildContext context) {
    final state = context.findAncestorStateOfType<_ScanBookPageState>();
    debugPrint('ScanBookPage.of result: $state');
    return state;
  }
}

class _ScanBookPageState extends State<ScanBookPage> with WidgetsBindingObserver {
  CameraController? _controller;
  final _textRecognizer = TextRecognizer();
  final _volumeButtonService = VolumeButtonService();
  final _voiceCommandService = VoiceCommandService();
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _cameraMounted = false;
  
  // Timer to periodically check and turn off flash
  Timer? _flashCheckTimer;
  
  void _startFlashCheckTimer() {
    _flashCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_controller != null && _isInitialized) {
        try {
          _controller!.setFlashMode(FlashMode.off);
          debugPrint('Periodic flash check: turned off flash');
        } catch (e) {
          debugPrint('Error in periodic flash check: $e');
        }
      }
    });
  }

  // Add public method to trigger capture
  void captureImage() {
    debugPrint('captureImage called!');
    if (_isProcessing) {
      debugPrint('Skipping capture - already processing');
      return;
    }
    _captureImage();
  }

  @override
  void initState() {
    super.initState();
    debugPrint('ScanBookPage initialized');
    // Register for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _setupVolumeButtons();
    _setupVoiceCommand();
    
    // Periodically ensure flash is off
    _startFlashCheckTimer();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      debugPrint('ScanBookPage route name: ${route.settings.name}');
    }
    
    // Always restart services when dependencies change (including when returning from another screen)
    if (mounted && _isInitialized) {
      _restartServices();
    }
    
    // Only check for auto-capture after camera is properly mounted and initialized
    if (_isInitialized && _cameraMounted && VoiceCommandService.shouldCaptureAfterNavigation) {
      debugPrint('Auto-capturing image based on flag');
      // Reset the flag
      VoiceCommandService.shouldCaptureAfterNavigation = false;
      // Give more time for the camera to fully stabilize
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted && !_isProcessing) {
          captureImage();
        }
      });
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('App lifecycle state changed to: $state');
    if (state == AppLifecycleState.resumed) {
      // The page is visible again, restart services
      _restartServices();
    }
  }
  
  // Also add a method to handle returning from other pages
  void onResumed() {
    debugPrint('ScanBookPage onResumed called');
    _restartServices();
  }

  void _restartServices() {
    debugPrint('Restarting services in ScanBookPage');
    // Only attempt to restart if initialized
    if (!_isInitialized) {
      debugPrint('Cannot restart services - not initialized yet');
      return;
    }
    
    _setupVolumeButtons();
    _setupVoiceCommand();
    _voiceCommandService.restart();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras available');
        return;
      }

      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high, // Back to high resolution for better image quality
        enableAudio: false,
      );

      await _controller!.initialize();
      
      // Explicitly turn off flash after initialization
      try {
        await _controller!.setFlashMode(FlashMode.off);
        debugPrint('Flash turned off successfully');
      } catch (e) {
        debugPrint('Error turning off flash: $e');
      }
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        
        // Give time for camera to stabilize before allowing capture
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              _cameraMounted = true;
            });
            
            // Check if we should capture after camera is initialized and stable
            if (VoiceCommandService.shouldCaptureAfterNavigation) {
              debugPrint('Camera initialized and mounted, preparing for auto-capture');
              // We'll do the actual capture in didChangeDependencies after the camera is proven stable
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _setupVolumeButtons() {
    _volumeButtonService.onVolumeUp = _captureImage;
    _volumeButtonService.onVolumeDown = () {
      Navigator.of(context).pop();
    };
    _volumeButtonService.startListening();
  }

  void _setupVoiceCommand() {
    // Register this page to the voice command service
    // This helps ensure voice commands are directed to this page
    debugPrint('Registering ScanBookPage for voice commands');
    
    // Make sure voice command service is listening
    _voiceCommandService.initialize();
    
    // Register this state instance with the voice command service
    _voiceCommandService.registerScanBookPage(this);
  }

  Future<void> _captureImage() async {
    if (_isProcessing || !_isInitialized || !_cameraMounted || _controller == null) {
      debugPrint('Cannot capture: processing=$_isProcessing, initialized=$_isInitialized, mounted=$_cameraMounted, controller=${_controller != null}');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Make sure flash is off before taking picture
      try {
        await _controller!.setFlashMode(FlashMode.off);
      } catch (e) {
        debugPrint('Error turning off flash before capture: $e');
      }
      
      debugPrint('Taking picture...');
      
      final image = await _controller!.takePicture();
      debugPrint('Picture taken: ${image.path}');
      
      debugPrint('Processing with OCR...');
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      debugPrint('OCR complete, text length: ${recognizedText.text.length}');
      if (recognizedText.text.isNotEmpty) {
        debugPrint('First 100 chars: ${recognizedText.text.substring(0, recognizedText.text.length > 100 ? 100 : recognizedText.text.length)}');
      }

      if (!mounted) return;
      
      // First properly clean up all services before navigating
      _volumeButtonService.stopListening();
      _voiceCommandService.unregisterScanBookPage();
      
      // Reset flag to ensure clean state
      _isInitialized = false;
      
      // Navigate to results page
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TextResultPage(
            scannedText: recognizedText.text,
          ),
        ),
      );
      
      // When we return to this page, forcefully recreate services
      if (mounted) {
        debugPrint('Returned from TextResultPage, forcefully recreating services');
        
        // Force recreation of services
        await _forceRecreateServices();
        
        // Reset the processing flag to allow new captures
        setState(() {
          _isProcessing = false;
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses gambar: $e')),
        );
      }
    }
  }
  
  // New method to forcefully recreate services
  Future<void> _forceRecreateServices() async {
    debugPrint('Forcefully recreating services');
    
    // First ensure all services are fully reset
    await _volumeButtonService.forceReset();
    await _voiceCommandService.forceReset();
    
    // Wait a moment to ensure clean state
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Recreate the services
    _setupVolumeButtons();
    _setupVoiceCommand();
    
    // Debug log to verify buttons are working
    debugPrint('Volume button callback set? ${_volumeButtonService.onVolumeUp != null}');
    debugPrint('ScanBookPage registered? ${VoiceCommandService.isOnScanBookPage}');
    
    // Force initialize voice command
    await _voiceCommandService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scan Buku'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Buku'),
      ),
      body: GestureDetector(
        // Add tap detection to restart services as a failsafe
        onTap: () {
          // Add a subtle tap feedback
          HapticFeedback.lightImpact();
        },
        onDoubleTap: () {
          // Force service recreation on double tap as emergency measure
          debugPrint('Double tap detected - forcing service recreation');
          _forceRecreateServices();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service diperbarui'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        child: Stack(
          children: [
            CameraPreview(_controller!),
            if (_isProcessing)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _volumeButtonService.stopListening();
    _controller?.dispose();
    _textRecognizer.close();
    
    // Cancel flash check timer
    _flashCheckTimer?.cancel();
    
    // Unregister this state from the voice command service
    _voiceCommandService.unregisterScanBookPage();
    
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    super.dispose();
  }
}
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../pages/scan_book_page.dart';
import '../services/volume_button_service.dart';

class VoiceCommandService {
  static final VoiceCommandService _instance = VoiceCommandService._internal();
  factory VoiceCommandService() => _instance;
  VoiceCommandService._internal();

  final SpeechToText _speech = SpeechToText();
  final _volumeButtonService = VolumeButtonService();
  bool _isInitialized = false;
  bool _isProcessingCommand = false;

  // Flag to indicate if we should capture after navigation
  static bool shouldCaptureAfterNavigation = false;
  
  // Flag to know if we're on ScanBookPage
  static bool isOnScanBookPage = false;
  
  // Flag to know if we're on TextResultPage
  static bool isOnTextResultPage = false;

  // Direct reference to the ScanBookPage state
  static dynamic scanBookPageState;

  // Callbacks for different commands
  VoidCallback? onScanBook;
  VoidCallback? onSaveResult;
  VoidCallback? onViewResults;
  
  // Callbacks for voice recognition status
  VoidCallback? onStartListening;
  VoidCallback? onFinishListening;

  // Method to register ScanBookPage state
  void registerScanBookPage(dynamic state) {
    scanBookPageState = state;
    isOnScanBookPage = true;
    debugPrint('ScanBookPage state registered');
  }

  // Method to unregister ScanBookPage state
  void unregisterScanBookPage() {
    scanBookPageState = null;
    isOnScanBookPage = false;
    debugPrint('ScanBookPage state unregistered');
  }
  
  // Methods for TextResultPage registration
  void registerTextResultPage() {
    isOnTextResultPage = true;
    debugPrint('TextResultPage registered');
  }
  
  void unregisterTextResultPage() {
    isOnTextResultPage = false;
    debugPrint('TextResultPage unregistered');
  }

  // Public method to start voice recognition
  Future<void> startListening() async {
    debugPrint('Manually starting voice command listening');
    
    // Make sure to trigger onStartListening before actually starting recognition
    if (onStartListening != null) {
      debugPrint('Triggering onStartListening callback before speech recognition starts');
      onStartListening!();
      
      // Longer delay to ensure TTS properly stops before starting voice recognition
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // Try a second time in case there was a callback timing issue
    if (onStartListening != null) {
      debugPrint('Triggering onStartListening callback again to ensure TTS stopped');
      onStartListening!();
      
      // Additional delay
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    await _startListening();
  }

  Future<void> initialize() async {
    // If we're already in the process of initializing, force a reset first
    if (_isInitialized) {
      debugPrint('Voice command already initialized, forcing a reset first');
      await forceReset();
    }

    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        debugPrint('Microphone permission denied');
        return;
      }

      // Initialize speech recognition
      _isInitialized = await _speech.initialize(
        onError: (error) => debugPrint('Speech recognition error: $error'),
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          // Also detect "done" or "notListening" status to trigger onFinishListening
          if (status == 'done' || status == 'notListening') {
            if (onFinishListening != null) {
              debugPrint('Triggering onFinishListening callback on $status status');
              onFinishListening!();
            }
          }
        },
      );

      if (_isInitialized) {
        _setupVolumeButtons();
        debugPrint('Voice command service successfully initialized');
      } else {
        debugPrint('Failed to initialize voice command service');
      }
    } catch (e) {
      debugPrint('Error initializing voice command: $e');
    }
  }

  void _setupVolumeButtons() {
    _volumeButtonService.onVolumeBoth = _startListening;
    _volumeButtonService.startListening();
  }

  Future<void> _startListening() async {
    if (!_isInitialized || _speech.isListening) return;

    try {
      // Call onStartListening callback if available
      if (onStartListening != null) {
        debugPrint('Triggering onStartListening callback');
        onStartListening!();
      }
      
      // Small delay to ensure any audio outputs are fully stopped 
      // before activating the microphone
      await Future.delayed(const Duration(milliseconds: 150));
      
      await _speech.listen(
        localeId: 'id_ID',
        onResult: (result) {
          if (result.finalResult) {
            _handleSpeechResult(result.recognizedWords.toLowerCase());
            
            // Call onFinishListening callback when we get final result
            if (onFinishListening != null) {
              debugPrint('Triggering onFinishListening callback after final result');
              onFinishListening!();
            }
            
            // Restart listening after processing the command with a small delay
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (_isInitialized && !_speech.isListening && !_isProcessingCommand) {
                debugPrint('Auto-restarting voice recognition after command');
                _startListening();
              }
            });
          }
        },
        cancelOnError: true,
        // ListenMode.confirmation = menunggu konfirmasi kata-kata yang lengkap
        // ListenMode.dictation = mode dikte yang lebih cocok untuk teks panjang
        listenMode: ListenMode.dictation, // Menggunakan mode dikte untuk mengenali lebih banyak kata
        pauseFor: const Duration(milliseconds: 3000), // Jeda lebih lama sebelum menganggap bicara selesai
        listenFor: const Duration(seconds: 30),     // Mendengarkan hingga 30 detik
      );
    } catch (e) {
      debugPrint('Error in speech recognition: $e');
      // Call onFinishListening even on error
      if (onFinishListening != null) {
        debugPrint('Triggering onFinishListening callback after error');
        onFinishListening!();
      }
      
      // Try to restart listening after error
      Future.delayed(const Duration(seconds: 2), () {
        if (_isInitialized && !_speech.isListening) {
          debugPrint('Trying to restart voice recognition after error');
          _startListening();
        }
      });
    }
  }

  void _handleSpeechResult(String text) async {
    debugPrint('Recognized text: $text');
    
    // Cek berbagai kemungkinan variasi kata kunci untuk trigger
    bool isTriggered = false;
    
    // Variasi kata kunci yang mungkin dikenali
    final List<String> possibleTriggers = [
      'halo nara',
      'halo nada',
      'halo nala',
      'halonara',
      'halo ara',
      'halo lara',
      'alo nara',
      'halo nara',
      'hello nara',
      'hallo nara',
    ];
    
    String commandText = text;
    
    // Cek apakah ada trigger yang terdeteksi
    for (final trigger in possibleTriggers) {
      if (text.toLowerCase().contains(trigger.toLowerCase())) {
        isTriggered = true;
        // Jika ditemukan trigger, hapus dari teks untuk mendapatkan perintah
        commandText = text.toLowerCase().replaceFirst(trigger.toLowerCase(), '').trim();
        debugPrint('Trigger "$trigger" terdeteksi, command: "$commandText"');
        break;
      }
    }
    
    // Jika tidak ada trigger yang terdeteksi, restart speech recognition
    if (!isTriggered) {
      debugPrint('Tidak ada trigger terdeteksi, restarting speech recognition');
      
      // Tunggu sebentar sebelum restart
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_isInitialized && !_speech.isListening && !_isProcessingCommand) {
          _startListening();
        }
      });
      return;
    }

    if (_isProcessingCommand) {
      return;
    }

    _isProcessingCommand = true;
    
    debugPrint('Recognized command: "$commandText"');
    
    // Get the current context using navigator key
    final context = navigatorKey.currentContext;
    if (context == null) {
      _isProcessingCommand = false;
      return;
    }

    // Handle commands
    await _executeCommand(commandText, context);

    // Reset processing flag after a short delay
    await Future.delayed(const Duration(seconds: 1));
    _isProcessingCommand = false;
  }

  Future<void> _executeCommand(String command, BuildContext context) async {
    // First, log the command and context
    debugPrint('Executing command: "$command", on ScanBookPage: $isOnScanBookPage, on TextResultPage: $isOnTextResultPage');
    
    // Check for common speech recognition variations of "pindai"
    if (command == 'pindai' || command == 'pinda' || command == 'pindi' || 
        command.contains('pindai') || command.contains('scan')) {
      try {
        debugPrint('Executing pindai command, on ScanBookPage: $isOnScanBookPage, state: $scanBookPageState');
        
        if (isOnScanBookPage && scanBookPageState != null) {
          // We're on ScanBookPage and have a valid state reference
          debugPrint('Using direct state reference to capture image');
          _showFeedback(context, 'Memindai dokumen...');
          scanBookPageState!.captureImage();
        } else {
          // Not on ScanBookPage or state is null, navigate there first
          debugPrint('Not on ScanBookPage or state is null, navigating to camera');
          shouldCaptureAfterNavigation = true;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const ScanBookPage(),
            ),
          );
          _showFeedback(context, 'Membuka kamera untuk pindai');
        }
        return;
      } catch (e) {
        debugPrint('Error executing pindai command: $e');
        _showFeedback(context, 'Terjadi kesalahan saat memindai');
        return;
      }
    }

    // Handle "simpan hasil" command
    if (command == 'simpan hasil' || command.contains('simpan')) {
      if (onSaveResult != null) {
        debugPrint('Executing save result callback');
        _showFeedback(context, 'Menyimpan hasil...');
        onSaveResult!();
      } else {
        if (isOnTextResultPage) {
          _showFeedback(context, 'Tidak dapat menyimpan saat ini');
        } else {
          _showFeedback(context, 'Tidak ada hasil untuk disimpan');
        }
      }
      return;
    } 
    
    // Handle "lihat hasil" command 
    if (command == 'lihat hasil' || command.contains('lihat') || command == 'penyimpanan') {
      if (onViewResults != null) {
        debugPrint('Executing view results callback');
        _showFeedback(context, 'Membuka penyimpanan...');
        onViewResults!();
      } else {
        _showFeedback(context, 'Tidak dapat membuka penyimpanan saat ini');
      }
      return;
    } 
    
    // Handle "buka kamera" command
    if (command == 'buka kamera') {
      // Navigate to ScanBookPage using pushReplacement to ensure it's the top route
      debugPrint('Navigating to ScanBookPage');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const ScanBookPage(),
        ),
      );
      _showFeedback(context, 'Membuka kamera');
      return;
    } 
    
    // If no command matched
    _showFeedback(context, 'Perintah tidak dikenali: $command');
  }

  void _showFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> dispose() async {
    _isInitialized = false;
    _speech.cancel();
  }

  // Restart functions - call this when returning to an app
  Future<void> restart() async {
    debugPrint('Restarting voice command service');
    // Make sure volume buttons are listening
    _volumeButtonService.startListening();
    
    // Re-register with volume button service
    _setupVolumeButtons();
  }
  
  // Force reset method to completely reset the service state
  Future<void> forceReset() async {
    debugPrint('Force resetting voice command service');
    
    // Clear callbacks
    onScanBook = null;
    onSaveResult = null;
    onViewResults = null;
    onStartListening = null;
    onFinishListening = null;
    
    // Reset flags
    isOnScanBookPage = false;
    isOnTextResultPage = false;
    shouldCaptureAfterNavigation = false;
    
    // Clear state reference
    scanBookPageState = null;
    
    // Cancel any active speech recognition
    if (_speech.isListening) {
      await _speech.cancel();
    }
    
    // Reset initialization flag to force complete reinitialization
    _isInitialized = false;
    _isProcessingCommand = false;
    
    // Wait a moment to ensure cleanup
    await Future.delayed(const Duration(milliseconds: 200));
    
    debugPrint('Voice command service has been forcefully reset');
  }
}

// Global navigator key for accessing context anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(); 
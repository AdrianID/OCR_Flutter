import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/volume_button_service.dart';
import '../services/tts_service.dart';
import '../services/audio_storage_service.dart';
import '../services/gemini_service.dart';
import '../models/audio_book.dart';
import '../services/voice_command_service.dart';
import 'storage_page.dart';

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
  final _geminiService = GeminiService(apiKey: 'AIzaSyDEXS5QZR0854kHrVZOxe8Yivh-K79W9IU');
  final _voiceCommandService = VoiceCommandService();
  bool _isSpeaking = false;
  bool _isSaving = false;
  bool _isPaused = false;
  bool _isSummarizing = false;
  String? _summarizedText;
  
  // Track TTS state during voice recognition
  bool _wasReadingBeforeVoiceCommand = false;
  bool _isListeningToVoiceCommand = false;

  @override
  void initState() {
    super.initState();
    _setupVolumeButtons();
    _setupVoiceCommands();
    _audioStorageService.init();
    _ttsService.initialize();
    _startAutoReading();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check if we've returned from another route
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      debugPrint('TextResultPage is now the current route, reinitializing services');
      _forceRecreateServices();
    }
  }

  void _setupVoiceCommands() {
    // First, ensure services are fully reset
    _forceRecreateServices();
    
    // Register save result callback
    _voiceCommandService.onSaveResult = _saveAudioBook;
    _voiceCommandService.onViewResults = _navigateToStoragePage;
    
    // Register voice recognition callbacks
    _voiceCommandService.onStartListening = _pauseReadingForVoiceCommand;
    _voiceCommandService.onFinishListening = _resumeReadingAfterVoiceCommand;
    
    // Register this page with voice command service
    _voiceCommandService.registerTextResultPage();
    
    // Make sure voice command service is listening
    _voiceCommandService.initialize();
    
    // Set up the volume buttons to trigger voice commands
    _setupVolumeButtonsForVoiceCommand();
  }
  
  void _setupVolumeButtonsForVoiceCommand() {
    // Set onVolumeBoth to start voice recognition
    _volumeButtonService.onVolumeBoth = () {
      debugPrint('Volume buttons pressed simultaneously in TextResultPage, triggering voice recognition');
      _voiceCommandService.startListening();
    };
  }
  
  // New method to forcefully recreate services
  Future<void> _forceRecreateServices() async {
    debugPrint('Forcefully recreating services in TextResultPage');
    
    // First ensure all services are fully reset
    await _volumeButtonService.forceReset();
    await _voiceCommandService.forceReset();
    
    // Wait a moment to ensure clean state
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Re-setup the volume buttons
    _setupVolumeButtons();
    
    // Register this page with voice command service
    _voiceCommandService.registerTextResultPage();
    
    // Initialize voice command service
    await _voiceCommandService.initialize();
    
    // Set up volume buttons for voice commands
    _setupVolumeButtonsForVoiceCommand();
    
    // Debug log to verify buttons are working
    debugPrint('Volume button service reset completed and reinitialized');
    debugPrint('Voice command service reset completed and reinitialized');
    debugPrint('TextResultPage registration status: ${VoiceCommandService.isOnTextResultPage}');
  }
  
  void _navigateToStoragePage() async {
    if (_isSpeaking) {
      _ttsService.stop();
      setState(() {
        _isSpeaking = false;
        _isPaused = false;
      });
    }
    
    // Temporarily pause voice command and volume button services
    _volumeButtonService.stopListening();
    
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const StoragePage()),
      );
      
      // Restart services when returning from StoragePage
      if (mounted) {
        debugPrint('Returned from StoragePage, restarting services');
        _setupVolumeButtons();
        _setupVoiceCommands();
      }
    } catch (e) {
      debugPrint('Error navigating to StoragePage: $e');
    }
  }

  void _startAutoReading() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && !_isSpeaking && !_isPaused) {
        _readText();
      }
    });
  }

  void _setupVolumeButtons() {
    _volumeButtonService.onVolumeUp = () {
      if (_isSpeaking) {
        if (_isPaused) {
          // Resume reading
          _readText();
        } else {
          // Pause reading
          _ttsService.stop();
          setState(() {
            _isPaused = true;
          });
        }
      } else {
        // Start reading
        _readText();
      }
    };
    _volumeButtonService.onVolumeDown = () {
      if (_isSpeaking) {
        _ttsService.stop();
        setState(() {
          _isSpeaking = false;
          _isPaused = false;
        });
      }
      _navigateBack();
    };
    _volumeButtonService.startListening();
  }

  void _navigateBack() {
    debugPrint('Navigating back from TextResultPage');
    
    // Do cleanup before popping
    _ttsService.stop();
    
    // Unregister callbacks gracefully
    _voiceCommandService.onSaveResult = null;
    _voiceCommandService.onViewResults = null;
    
    // Force reset voice command service to ensure clean state
    _voiceCommandService.forceReset();
    _voiceCommandService.unregisterTextResultPage();
    
    // Stop volume button service
    _volumeButtonService.stopListening();
    
    // Now navigate back (without result, let the previous page handle its own state)
    Navigator.of(context).pop();
  }

  Future<void> _readText() async {
    setState(() {
      _isSpeaking = true;
      _isPaused = false;
    });
    await _ttsService.speak(widget.scannedText);
    if (mounted) {
      setState(() {
        _isSpeaking = false;
        _isPaused = false;
      });
    }
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

  Future<void> _summarizeText() async {
    if (_isSummarizing) return;

    setState(() {
      _isSummarizing = true;
    });

    try {
      final summary = await _geminiService.summarizeText(widget.scannedText);
      if (mounted) {
        setState(() {
          _summarizedText = summary;
        });
        // Automatically read the summary
        _ttsService.stop();
        await _ttsService.speak(summary);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal meringkas teks: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSummarizing = false;
        });
      }
    }
  }

  // Method to pause reading when voice command starts
  void _pauseReadingForVoiceCommand() {
    debugPrint('Pausing reading for voice command');
    
    // Always stop TTS first to ensure mic is free
    if (_isSpeaking) {
      _ttsService.stop();
      debugPrint('TTS was active, forcefully stopping it');
    }
    
    setState(() {
      _isListeningToVoiceCommand = true;
      
      // Only save state if currently speaking and not paused
      if (_isSpeaking && !_isPaused) {
        _wasReadingBeforeVoiceCommand = true;
        _isPaused = true;
      } else {
        _wasReadingBeforeVoiceCommand = false;
      }
    });
    
    // Show a feedback notification 
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mendengarkan perintah suara...'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  // Method to resume reading when voice command finishes
  void _resumeReadingAfterVoiceCommand() {
    debugPrint('Voice command finished, resuming reading if needed');
    
    // Set a longer delay to ensure the command processing is complete
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isListeningToVoiceCommand = false;
        });
        
        // Only resume if it was previously reading
        if (_wasReadingBeforeVoiceCommand) {
          debugPrint('Resuming TTS after voice command with delay');
          // Additional delay to ensure UI updates first
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              // Menampilkan feedback bahwa sedang melanjutkan pembacaan
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Melanjutkan pembacaan...'),
                  duration: Duration(seconds: 1),
                  backgroundColor: Colors.green,
                ),
              );
              _readText();
            }
          });
        } else {
          // Show feedback that voice command ended
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selesai mendengarkan'),
              duration: Duration(milliseconds: 800),
            ),
          );
        }
        
        // Reset the flag
        _wasReadingBeforeVoiceCommand = false;
      }
    });
  }

  @override
  void dispose() {
    _ttsService.stop();
    _ttsService.dispose();
    
    // Unregister callbacks gracefully
    _voiceCommandService.onSaveResult = null;
    _voiceCommandService.onViewResults = null;
    _voiceCommandService.onStartListening = null;
    _voiceCommandService.onFinishListening = null;
    _voiceCommandService.unregisterTextResultPage();
    
    // Stop volume button service
    _volumeButtonService.stopListening();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Pemindaian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.summarize),
            onPressed: _isSummarizing ? null : _summarizeText,
            tooltip: 'Ringkas Teks',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveAudioBook,
            tooltip: 'Simpan Buku',
          ),
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: _navigateToStoragePage,
            tooltip: 'Lihat Penyimpanan',
          ),
        ],
      ),
      body: GestureDetector(
        // Add double tap detection to force service reset as a failsafe
        onDoubleTap: () async {
          // Force service recreation on double tap as emergency measure
          debugPrint('Double tap detected - forcing service recreation in TextResultPage');
          await _forceRecreateServices();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service diperbarui'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_summarizedText != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.auto_stories),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _summarizedText!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                ],
                Text(
                  widget.scannedText,
                  style: const TextStyle(fontSize: 18),
                ),
                if (_isSpeaking || _isSaving || _isSummarizing || _isListeningToVoiceCommand)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isSpeaking)
                          Icon(
                            _isPaused ? Icons.play_arrow : Icons.pause,
                            size: 24,
                            color: Theme.of(context).primaryColor,
                          ),
                        if (_isSpeaking)
                          const SizedBox(width: 8),
                        if (_isListeningToVoiceCommand)
                          Icon(
                            Icons.mic,
                            size: 24,
                            color: Colors.red,
                          ),
                        if (_isListeningToVoiceCommand)
                          const SizedBox(width: 8),
                        const CircularProgressIndicator(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isListeningToVoiceCommand 
                    ? null 
                    : (_isSpeaking
                      ? (_isPaused ? () => _readText() : () {
                          _ttsService.stop();
                          setState(() {
                            _isPaused = true;
                          });
                        })
                      : () => _readText()),
                  icon: _isListeningToVoiceCommand 
                    ? const Icon(Icons.mic) 
                    : Icon(_isSpeaking && !_isPaused ? Icons.pause : Icons.play_arrow),
                  label: _isListeningToVoiceCommand 
                    ? const Text('Mendengarkan...') 
                    : Text(_isSpeaking && !_isPaused ? 'Jeda' : 'Baca'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: _isListeningToVoiceCommand ? Colors.red.shade100 : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isListeningToVoiceCommand ? null : () {
                    _voiceCommandService.startListening();
                  },
                  icon: const Icon(Icons.mic_none),
                  label: const Text('Perintah Suara'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.purple.shade100,
                    foregroundColor: Colors.purple.shade900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving || _isListeningToVoiceCommand ? null : _saveAudioBook,
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isListeningToVoiceCommand ? null : _navigateToStoragePage,
                  icon: const Icon(Icons.storage),
                  label: const Text('Lihat'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VolumeButtonService {
  static final VolumeButtonService _instance = VolumeButtonService._internal();
  factory VolumeButtonService() => _instance;
  VolumeButtonService._internal();

  static const platform = MethodChannel('volume_button_channel');
  bool _isListening = false;

  // Callback untuk volume up
  VoidCallback? onVolumeUp;
  // Callback untuk volume down
  VoidCallback? onVolumeDown;
  // Callback untuk volume buttons pressed simultaneously
  VoidCallback? onVolumeBoth;
  
  // Helper method to log the current state
  void logState() {
    debugPrint('VolumeButtonService state: listening=$_isListening, callbacks set: '
        'up=${onVolumeUp != null}, down=${onVolumeDown != null}, both=${onVolumeBoth != null}');
  }

  Future<void> startListening() async {
    logState();
    
    if (_isListening) {
      debugPrint('Already listening to volume buttons');
      
      // Even if we're already listening, forcefully renew the method call handler
      // This helps in cases where the app has come back from a background state
      platform.setMethodCallHandler((call) async {
        debugPrint('Method call received: ${call.method}');
        switch (call.method) {
          case 'volumeUp':
            debugPrint('Volume Up double-click detected - Executing callback');
            HapticFeedback.mediumImpact();
            if (onVolumeUp != null) {
              onVolumeUp!();
            } else {
              debugPrint('No callback registered for volume up');
            }
            break;
          case 'volumeDown':
            debugPrint('Volume Down double-click detected - Executing callback');
            HapticFeedback.lightImpact();
            if (onVolumeDown != null) {
              onVolumeDown!();
            } else {
              debugPrint('No callback registered for volume down');
            }
            break;
          case 'volumeBoth':
            debugPrint('Volume buttons pressed simultaneously - Executing callback');
            HapticFeedback.heavyImpact();
            if (onVolumeBoth != null) {
              onVolumeBoth!();
            } else {
              debugPrint('No callback registered for volume both');
            }
            break;
        }
      });
      
      return;
    }
    
    try {
      debugPrint('Starting to listen to volume buttons...');
      await platform.invokeMethod('startListening');
      _isListening = true;
      debugPrint('Successfully started listening to volume buttons');
      debugPrint('Double-click volume up/down to trigger actions');
      debugPrint('Press both volume buttons simultaneously to trigger microphone');
      
      // Set up method call handler
      platform.setMethodCallHandler((call) async {
        debugPrint('Method call received: ${call.method}');
        switch (call.method) {
          case 'volumeUp':
            debugPrint('Volume Up double-click detected - Executing callback');
            HapticFeedback.mediumImpact();
            if (onVolumeUp != null) {
              onVolumeUp!();
            } else {
              debugPrint('No callback registered for volume up');
            }
            break;
          case 'volumeDown':
            debugPrint('Volume Down double-click detected - Executing callback');
            HapticFeedback.lightImpact();
            if (onVolumeDown != null) {
              onVolumeDown!();
            } else {
              debugPrint('No callback registered for volume down');
            }
            break;
          case 'volumeBoth':
            debugPrint('Volume buttons pressed simultaneously - Executing callback');
            HapticFeedback.heavyImpact();
            if (onVolumeBoth != null) {
              onVolumeBoth!();
            } else {
              debugPrint('No callback registered for volume both');
            }
            break;
        }
      });
    } on PlatformException catch (e) {
      debugPrint('Failed to start listening: ${e.message}');
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) {
      debugPrint('Not currently listening to volume buttons');
      return;
    }
    
    try {
      debugPrint('Stopping volume button listener...');
      await platform.invokeMethod('stopListening');
      _isListening = false;
      platform.setMethodCallHandler(null);
      // Clear callbacks
      onVolumeUp = null;
      onVolumeDown = null;
      onVolumeBoth = null;
      debugPrint('Successfully stopped listening to volume buttons');
    } on PlatformException catch (e) {
      debugPrint('Failed to stop listening: ${e.message}');
    }
  }
  
  // Force reset method - call when the service seems stuck
  Future<void> forceReset() async {
    debugPrint('Force resetting volume button service...');
    logState();
    
    // Clean up platform channel handler
    platform.setMethodCallHandler(null);
    
    // Clear callbacks first to prevent any lingering calls
    onVolumeUp = null;
    onVolumeDown = null;
    onVolumeBoth = null;
    
    // Force stop listening
    try {
      await platform.invokeMethod('stopListening');
    } catch (e) {
      debugPrint('Error stopping native listener: $e');
    }
    
    // Reset the listening flag to force a complete restart
    _isListening = false;
    
    // Wait a moment to ensure native side has time to clean up
    await Future.delayed(const Duration(milliseconds: 300));
    
    debugPrint('Volume button service has been forcefully reset');
    logState();
    
    // Try to restart the native side forcefully
    try {
      // First make sure it's stopped
      await platform.invokeMethod('stopListening');
      // Then restart with delay
      await Future.delayed(const Duration(milliseconds: 200));
      await platform.invokeMethod('startListening');
      debugPrint('Native volume button service restarted');
    } catch (e) {
      debugPrint('Error resetting native service: $e');
    }
  }
} 
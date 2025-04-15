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

  Future<void> startListening() async {
    if (_isListening) {
      debugPrint('Already listening to volume buttons');
      return;
    }
    
    try {
      debugPrint('Starting to listen to volume buttons...');
      await platform.invokeMethod('startListening');
      _isListening = true;
      debugPrint('Successfully started listening to volume buttons');
      debugPrint('Double-click volume up/down to trigger actions');
      
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
      debugPrint('Successfully stopped listening to volume buttons');
    } on PlatformException catch (e) {
      debugPrint('Failed to stop listening: ${e.message}');
    }
  }
} 
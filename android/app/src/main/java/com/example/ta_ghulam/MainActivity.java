package com.example.ta_ghulam;

import android.util.Log;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String TAG = "MainActivity";
    private static final String CHANNEL = "volume_button_channel";
    private MethodChannel methodChannel;
    
    // Variables for double-click detection
    private long lastVolumeUpClickTime = 0;
    private long lastVolumeDownClickTime = 0;
    private static final long DOUBLE_CLICK_TIME_DELTA = 300; // milliseconds

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        methodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        methodChannel.setMethodCallHandler((call, result) -> {
            Log.d(TAG, "Method call received: " + call.method);
            if (call.method.equals("startListening")) {
                Log.d(TAG, "Start listening to volume buttons");
                result.success(null);
            } else if (call.method.equals("stopListening")) {
                Log.d(TAG, "Stop listening to volume buttons");
                result.success(null);
            } else {
                result.notImplemented();
            }
        });
    }

    @Override
    public boolean onKeyDown(int keyCode, android.view.KeyEvent event) {
        Log.d(TAG, "Key down event: " + keyCode);
        long currentTime = System.currentTimeMillis();
        
        if (keyCode == android.view.KeyEvent.KEYCODE_VOLUME_UP) {
            if (currentTime - lastVolumeUpClickTime < DOUBLE_CLICK_TIME_DELTA) {
                // Double click detected
                Log.d(TAG, "Volume up double click detected");
                if (methodChannel != null) {
                    methodChannel.invokeMethod("volumeUp", null);
                }
                lastVolumeUpClickTime = 0; // Reset to prevent triple click
            } else {
                // First click
                lastVolumeUpClickTime = currentTime;
                return false; // Allow normal volume up
            }
            return true;
        } else if (keyCode == android.view.KeyEvent.KEYCODE_VOLUME_DOWN) {
            if (currentTime - lastVolumeDownClickTime < DOUBLE_CLICK_TIME_DELTA) {
                // Double click detected
                Log.d(TAG, "Volume down double click detected");
                if (methodChannel != null) {
                    methodChannel.invokeMethod("volumeDown", null);
                }
                lastVolumeDownClickTime = 0; // Reset to prevent triple click
            } else {
                // First click
                lastVolumeDownClickTime = currentTime;
                return false; // Allow normal volume down
            }
            return true;
        }
        return super.onKeyDown(keyCode, event);
    }

    @Override
    public boolean onKeyUp(int keyCode, android.view.KeyEvent event) {
        Log.d(TAG, "Key up event: " + keyCode);
        if (keyCode == android.view.KeyEvent.KEYCODE_VOLUME_UP || 
            keyCode == android.view.KeyEvent.KEYCODE_VOLUME_DOWN) {
            return true;
        }
        return super.onKeyUp(keyCode, event);
    }
} 
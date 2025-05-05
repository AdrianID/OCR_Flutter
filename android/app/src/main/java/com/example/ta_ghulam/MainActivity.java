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
    
    // Variables for simultaneous press detection
    private boolean volumeUpPressed = false;
    private boolean volumeDownPressed = false;
    private static final long SIMULTANEOUS_PRESS_TIME_DELTA = 1000; // milliseconds

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

        flutterEngine.getPlugins().add(new VolumeButtonPlugin());
    }

    @Override
    public boolean onKeyDown(int keyCode, android.view.KeyEvent event) {
        Log.d(TAG, "Key down event: " + keyCode);
        long currentTime = System.currentTimeMillis();
        
        if (keyCode == android.view.KeyEvent.KEYCODE_VOLUME_UP) {
            volumeUpPressed = true;
            Log.d(TAG, "Volume up pressed, up: " + volumeUpPressed + ", down: " + volumeDownPressed);
            
            if (volumeDownPressed) {
                Log.d(TAG, "Volume buttons pressed simultaneously");
                if (methodChannel != null) {
                    methodChannel.invokeMethod("volumeBoth", null);
                }
                volumeUpPressed = false;
                volumeDownPressed = false;
                return true;
            }
            
            if (currentTime - lastVolumeUpClickTime < DOUBLE_CLICK_TIME_DELTA) {
                Log.d(TAG, "Volume up double click detected");
                if (methodChannel != null) {
                    methodChannel.invokeMethod("volumeUp", null);
                }
                lastVolumeUpClickTime = 0;
            } else {
                lastVolumeUpClickTime = currentTime;
                return false;
            }
            return true;
        } else if (keyCode == android.view.KeyEvent.KEYCODE_VOLUME_DOWN) {
            volumeDownPressed = true;
            Log.d(TAG, "Volume down pressed, up: " + volumeUpPressed + ", down: " + volumeDownPressed);
            
            if (volumeUpPressed) {
                Log.d(TAG, "Volume buttons pressed simultaneously");
                if (methodChannel != null) {
                    methodChannel.invokeMethod("volumeBoth", null);
                }
                volumeUpPressed = false;
                volumeDownPressed = false;
                return true;
            }
            
            if (currentTime - lastVolumeDownClickTime < DOUBLE_CLICK_TIME_DELTA) {
                Log.d(TAG, "Volume down double click detected");
                if (methodChannel != null) {
                    methodChannel.invokeMethod("volumeDown", null);
                }
                lastVolumeDownClickTime = 0;
            } else {
                lastVolumeDownClickTime = currentTime;
                return false;
            }
            return true;
        }
        return super.onKeyDown(keyCode, event);
    }

    @Override
    public boolean onKeyUp(int keyCode, android.view.KeyEvent event) {
        Log.d(TAG, "Key up event: " + keyCode);
        if (keyCode == android.view.KeyEvent.KEYCODE_VOLUME_UP) {
            volumeUpPressed = false;
            Log.d(TAG, "Volume up released, up: " + volumeUpPressed + ", down: " + volumeDownPressed);
            return true;
        } else if (keyCode == android.view.KeyEvent.KEYCODE_VOLUME_DOWN) {
            volumeDownPressed = false;
            Log.d(TAG, "Volume down released, up: " + volumeUpPressed + ", down: " + volumeDownPressed);
            return true;
        }
        return super.onKeyUp(keyCode, event);
    }
} 
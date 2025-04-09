package com.example.ta_ghulam;

import android.util.Log;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String TAG = "MainActivity";
    private static final String CHANNEL = "volume_button_channel";
    private MethodChannel methodChannel;

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
        if (keyCode == android.view.KeyEvent.KEYCODE_VOLUME_UP) {
            Log.d(TAG, "Volume up pressed");
            if (methodChannel != null) {
                methodChannel.invokeMethod("volumeUp", null);
            }
            return true;
        } else if (keyCode == android.view.KeyEvent.KEYCODE_VOLUME_DOWN) {
            Log.d(TAG, "Volume down pressed");
            if (methodChannel != null) {
                methodChannel.invokeMethod("volumeDown", null);
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
package com.example.ta_ghulam;

import android.util.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class VolumeButtonPlugin implements FlutterPlugin, MethodCallHandler {
    private static final String TAG = "VolumeButtonPlugin";
    private static final String CHANNEL = "volume_button_channel";
    private MethodChannel channel;

    public VolumeButtonPlugin() {
    }

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
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
    }

    public void invokeMethod(String method, Object arguments) {
        if (channel != null) {
            channel.invokeMethod(method, arguments);
        }
    }
} 
package com.example.ta_ghulam;

import android.app.Activity;
import android.util.Log;
import android.view.KeyEvent;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class VolumeButtonPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
    private static final String TAG = "VolumeButtonPlugin";
    private static final String CHANNEL = "volume_button_channel";
    private MethodChannel channel;
    private Activity activity;
    private boolean isListening = false;

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        Log.d(TAG, "Method call received: " + call.method);
        if (call.method.equals("startListening")) {
            isListening = true;
            result.success(null);
        } else if (call.method.equals("stopListening")) {
            isListening = false;
            result.success(null);
        } else {
            result.notImplemented();
        }
    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivity() {
        activity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity();
    }
} 
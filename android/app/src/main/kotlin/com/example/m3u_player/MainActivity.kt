package com.example.m3u_player

import android.app.PictureInPictureParams
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.m3u_player/pip"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "enterPiP") {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val builder = PictureInPictureParams.Builder()
                    enterPictureInPictureMode(builder.build())
                    result.success(null)
                } else {
                    result.error("NOT_SUPPORTED", "PiP not supported", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}

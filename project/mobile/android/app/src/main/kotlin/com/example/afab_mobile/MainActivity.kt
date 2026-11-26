package com.example.afab_mobile

import android.app.UiModeManager
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "afab/theme",
        ).setMethodCallHandler { call, result ->
            if (call.method == "setThemeMode") {
                val mode = call.argument<String>("mode") ?: "system"
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val nightMode = when (mode) {
                        "light" -> UiModeManager.MODE_NIGHT_NO
                        "dark" -> UiModeManager.MODE_NIGHT_YES
                        else -> UiModeManager.MODE_NIGHT_AUTO
                    }
                    getSystemService(UiModeManager::class.java)
                        ?.setApplicationNightMode(nightMode)
                }
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}

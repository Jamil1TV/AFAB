package com.example.afab_mobile

import android.app.UiModeManager
import android.content.ComponentName
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

open class MainActivity : FlutterFragmentActivity() {
    private var pendingLauncherMode: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "afab/theme",
        ).setMethodCallHandler { call, result ->
            if (call.method == "setThemeMode") {
                val mode = call.argument<String>("mode") ?: "system"
                syncUiModeManager(mode)
                pendingLauncherMode = mode
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onStop() {
        super.onStop()
        val mode = pendingLauncherMode ?: return
        pendingLauncherMode = null
        applyLauncherComponent(mode)
    }

    private fun syncUiModeManager(mode: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val nightMode = when (mode) {
                "light" -> UiModeManager.MODE_NIGHT_NO
                "dark" -> UiModeManager.MODE_NIGHT_YES
                else -> UiModeManager.MODE_NIGHT_AUTO
            }
            getSystemService(UiModeManager::class.java)
                ?.setApplicationNightMode(nightMode)
        }
    }

    private fun applyLauncherComponent(mode: String) {
        val pm = packageManager
        val systemComp = ComponentName(this, MainActivity::class.java.name)
        val lightComp = ComponentName(this, LightMainActivity::class.java.name)
        val darkComp = ComponentName(this, DarkMainActivity::class.java.name)

        val targetComp = when (mode) {
            "light" -> lightComp
            "dark" -> darkComp
            else -> systemComp
        }
        val others = listOf(systemComp, lightComp, darkComp).filter { it != targetComp }

        val targetAlreadyEnabled =
            pm.getComponentEnabledSetting(targetComp) == PackageManager.COMPONENT_ENABLED_STATE_ENABLED
        val othersAlreadyDisabled = others.all {
            pm.getComponentEnabledSetting(it) == PackageManager.COMPONENT_ENABLED_STATE_DISABLED
        }
        if (targetAlreadyEnabled && othersAlreadyDisabled) return

        // Enable target BEFORE disabling others so Android never removes the launcher entry.
        pm.setComponentEnabledSetting(
            targetComp,
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP,
        )
        for (other in others) {
            pm.setComponentEnabledSetting(
                other,
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP,
            )
        }
    }
}

class LightMainActivity : MainActivity()

class DarkMainActivity : MainActivity()

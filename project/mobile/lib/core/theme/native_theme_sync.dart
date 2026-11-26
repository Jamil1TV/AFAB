import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Synchronizes the user's in-app [ThemeMode] with Android 12+
/// (`UiModeManager.setApplicationNightMode`) so the cold-start native splash
/// screen and Day/Night resources match the chosen theme.
abstract final class NativeThemeSync {
  static const _channel = MethodChannel('afab/theme');

  static Future<void> sync(ThemeMode mode) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('setThemeMode', {'mode': mode.name});
    } on MissingPluginException {
      // Safe no-op in widget tests or platforms without the native handler.
    } catch (_) {
      // Never block theme changes on platform channel errors.
    }
  }
}

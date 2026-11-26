import 'package:flutter/foundation.dart';

/// Application logger that redacts secrets, Bearer tokens, and emails.
abstract final class AppLogger {
  static void debug(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] ${_sanitize(message)}');
    }
  }

  static void warn(String tag, String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('[$tag][WARN] ${_sanitize(message)}'
          '${error != null ? ' (${_sanitize(error.toString())})' : ''}');
    }
  }

  static String _sanitize(String input) {
    var out = input.replaceAll(
      RegExp(r'Bearer\s+[A-Za-z0-9._-]+', caseSensitive: false),
      'Bearer <REDACTED>',
    );
    out = out.replaceAll(
      RegExp(r'refreshToken=[^;\s]+', caseSensitive: false),
      'refreshToken=<REDACTED>',
    );
    out = out.replaceAll(
      RegExp(r'afab_csrf=[^;\s]+', caseSensitive: false),
      'afab_csrf=<REDACTED>',
    );
    out = out.replaceAll(
      RegExp(r'eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'),
      '<JWT_REDACTED>',
    );
    out = out.replaceAll(
      RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'),
      '<EMAIL_REDACTED>',
    );
    return out;
  }

  @visibleForTesting
  static String sanitizeForTest(String input) => _sanitize(input);
}

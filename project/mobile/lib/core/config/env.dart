import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime environment configuration supplied via `--dart-define` or `.env`.
abstract final class AppEnv {
  static const String _definedApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String _definedWebAppUrl = String.fromEnvironment(
    'WEB_APP_URL',
  );
  static const String _definedEnvironment = String.fromEnvironment(
    'ENVIRONMENT',
  );

  /// Loads `.env` if bundled; fails gracefully when absent (e.g. unit tests).
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Fall back cleanly to --dart-define or platform defaults.
    }
    if (kDebugMode) {
      debugPrint('[AppEnv] API_BASE_URL=$apiBaseUrl (env=$environment)');
    }
  }

  /// Normalizes a backend host or base URL so it always targets `/api/v1`.
  static String normalizeApiBaseUrl(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'/+$'), '');
    if (trimmed.isEmpty) return '';
    if (trimmed.endsWith('/api/v1')) return trimmed;
    if (trimmed.endsWith('/api')) return '$trimmed/v1';
    return '$trimmed/api/v1';
  }

  static String? _envValue(String key) {
    if (!dotenv.isInitialized) return null;
    final val = dotenv.maybeGet(key)?.trim();
    return (val != null && val.isNotEmpty) ? val : null;
  }

  static String get webAppUrl {
    if (_definedWebAppUrl.isNotEmpty) return _definedWebAppUrl.trim();
    return _envValue('WEB_APP_URL') ?? 'http://localhost:3000';
  }

  static String get environment {
    if (_definedEnvironment.isNotEmpty) return _definedEnvironment.trim();
    return _envValue('ENVIRONMENT') ?? 'local';
  }

  /// Resolves the backend `/api/v1` base URL:
  /// 1. `--dart-define=API_BASE_URL=...`
  /// 2. `.env` `API_BASE_URL`
  /// 3. Platform local default (`10.0.2.2` for Android emulator, `127.0.0.1` elsewhere).
  static String get apiBaseUrl {
    if (_definedApiBaseUrl.isNotEmpty) {
      return normalizeApiBaseUrl(_definedApiBaseUrl);
    }
    final fromDotEnv = _envValue('API_BASE_URL');
    if (fromDotEnv != null) {
      return normalizeApiBaseUrl(fromDotEnv);
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api/v1';
    }
    return 'http://127.0.0.1:8080/api/v1';
  }

  static bool get isLocal => environment == 'local';
}

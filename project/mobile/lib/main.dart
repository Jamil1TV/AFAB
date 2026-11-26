import 'package:afab_mobile/app/afab_app.dart';
import 'package:afab_mobile/core/config/env.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/core/utils/app_logger.dart';
import 'package:afab_mobile/features/app_states/error_and_not_found_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    AppLogger.warn('FlutterError', details.exceptionAsString());
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.warn('PlatformError', error.toString());
    return true;
  };
  ErrorWidget.builder = (details) => AfabSafeErrorCard(
        debugDetails: kDebugMode ? details.exceptionAsString() : null,
      );

  await AppEnv.init();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AfabApp(),
    ),
  );
}

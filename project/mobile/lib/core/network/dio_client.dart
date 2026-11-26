import 'package:afab_mobile/core/config/env.dart';
import 'package:afab_mobile/core/network/auth_interceptor.dart';
import 'package:afab_mobile/core/network/error_interceptor.dart';
import 'package:afab_mobile/core/network/global_events.dart';
import 'package:afab_mobile/core/network/tenant_interceptor.dart';
import 'package:afab_mobile/core/storage/encrypted_cookie_storage.dart';
import 'package:afab_mobile/core/storage/prefs_store.dart';
import 'package:afab_mobile/core/storage/session_token_holder.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden at app bootstrap (`main.dart`) or in tests.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final prefsStoreProvider = Provider<PrefsStore>((ref) {
  return PrefsStore(ref.watch(sharedPreferencesProvider));
});

final sessionTokenHolderProvider = Provider<SessionTokenHolder>((ref) {
  return SessionTokenHolder();
});

final activeBusinessHolderProvider = Provider<ActiveBusinessHolder>((ref) {
  final prefs = ref.watch(prefsStoreProvider);
  final holder = ActiveBusinessHolder();
  holder.setBusinessId(prefs.getActiveBusinessId());
  return holder;
});

final globalEventBusProvider = Provider<GlobalEventBus>((ref) {
  final bus = GlobalEventBus();
  ref.onDispose(bus.dispose);
  return bus;
});

final encryptedCookieStorageProvider = Provider<EncryptedCookieStorage>((ref) {
  return EncryptedCookieStorage();
});

final cookieJarProvider = Provider<PersistCookieJar>((ref) {
  return PersistCookieJar(
    ignoreExpires: false,
    storage: ref.watch(encryptedCookieStorageProvider),
  );
});

final refreshDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppEnv.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {'Accept': 'application/json'},
    ),
  );
  if (!kIsWeb) {
    dio.interceptors.add(CookieManager(ref.watch(cookieJarProvider)));
  }
  return dio;
});

final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  final retryDio = Dio(
    BaseOptions(
      baseUrl: AppEnv.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {'Accept': 'application/json'},
    ),
  );
  retryDio.interceptors.addAll([
    if (!kIsWeb) CookieManager(ref.watch(cookieJarProvider)),
    TenantInterceptor(ref.watch(activeBusinessHolderProvider)),
    ErrorInterceptor(
      eventBus: ref.watch(globalEventBusProvider),
      businessHolder: ref.watch(activeBusinessHolderProvider),
      prefsStore: ref.watch(prefsStoreProvider),
    ),
  ]);

  return AuthInterceptor(
    retryDio: retryDio,
    refreshDio: ref.watch(refreshDioProvider),
    cookieJar: ref.watch(cookieJarProvider),
    cookieStorage: ref.watch(encryptedCookieStorageProvider),
    tokenHolder: ref.watch(sessionTokenHolderProvider),
    eventBus: ref.watch(globalEventBusProvider),
  );
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppEnv.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.addAll([
    if (!kIsWeb) CookieManager(ref.watch(cookieJarProvider)),
    ref.watch(authInterceptorProvider),
    TenantInterceptor(ref.watch(activeBusinessHolderProvider)),
    ErrorInterceptor(
      eventBus: ref.watch(globalEventBusProvider),
      businessHolder: ref.watch(activeBusinessHolderProvider),
      prefsStore: ref.watch(prefsStoreProvider),
    ),
  ]);
  return dio;
});

/// Dedicated Dio instance with extended timeouts for SSE AI Copilot streaming
/// (`POST /api/v1/ai/chat/stream`), keeping 130s receiveTimeout across GPU warmup.
final sseDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppEnv.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 130),
      headers: const {'Accept': 'text/event-stream'},
    ),
  );
  dio.interceptors.addAll([
    if (!kIsWeb) CookieManager(ref.watch(cookieJarProvider)),
    ref.watch(authInterceptorProvider),
    TenantInterceptor(ref.watch(activeBusinessHolderProvider)),
    ErrorInterceptor(
      eventBus: ref.watch(globalEventBusProvider),
      businessHolder: ref.watch(activeBusinessHolderProvider),
      prefsStore: ref.watch(prefsStoreProvider),
    ),
  ]);
  return dio;
});

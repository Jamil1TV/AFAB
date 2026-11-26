import 'dart:async';

import 'package:afab_mobile/core/config/env.dart';
import 'package:afab_mobile/core/network/global_events.dart';
import 'package:afab_mobile/core/storage/encrypted_cookie_storage.dart';
import 'package:afab_mobile/core/storage/session_token_holder.dart';
import 'package:afab_mobile/core/utils/app_logger.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';

/// Attaches Bearer JWT + CSRF double-submit header and performs single-flight
/// refresh rotation via HttpOnly cookie + `X-CSRF-Token` without sending an
/// `Origin` header (satisfying `AuthCookieService.verifyCsrfAndOrigin()`).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.retryDio,
    required this.refreshDio,
    required this.cookieJar,
    required this.cookieStorage,
    required this.tokenHolder,
    required this.eventBus,
  });

  final Dio retryDio;
  final Dio refreshDio;
  final PersistCookieJar cookieJar;
  final EncryptedCookieStorage cookieStorage;
  final SessionTokenHolder tokenHolder;
  final GlobalEventBus eventBus;

  Completer<bool>? _inFlightRefresh;

  bool _isAuthRoute(String path) => path.contains('/auth/');

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Ensure native clients never send a spoofed Origin header.
    options.headers.remove('Origin');

    final requiresAuth = options.extra['requireAuth'] as bool? ?? true;
    if (requiresAuth && !_isAuthRoute(options.path)) {
      if (!tokenHolder.hasAccessToken) {
        final ok = await tryRefreshToken();
        if (!ok && !tokenHolder.hasAccessToken) {
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: options,
                statusCode: 401,
                data: const {
                  'code': 'UNAUTHORIZED',
                  'message': 'Authentication required. Please sign in again.',
                },
              ),
            ),
          );
        }
      }
      final token = tokenHolder.accessToken;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } else if (options.path.contains('/auth/change-password')) {
      final token = tokenHolder.accessToken;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    if (options.path.contains('/auth/refresh') ||
        options.path.contains('/auth/logout')) {
      final csrf = await resolveCsrfToken();
      if (csrf != null && csrf.isNotEmpty) {
        options.headers['X-CSRF-Token'] = csrf;
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final options = err.requestOptions;
    final requiresAuth = options.extra['requireAuth'] as bool? ?? true;
    final alreadyRetried = options.extra['_retriedAfterRefresh'] as bool? ?? false;

    if (status == 401 &&
        requiresAuth &&
        !alreadyRetried &&
        !_isAuthRoute(options.path)) {
      final refreshed = await tryRefreshToken();
      if (refreshed && tokenHolder.hasAccessToken) {
        try {
          options.extra['_retriedAfterRefresh'] = true;
          options.headers['Authorization'] =
              'Bearer ${tokenHolder.accessToken}';
          final response = await retryDio.fetch<dynamic>(options);
          return handler.resolve(response);
        } on DioException catch (retryErr) {
          return handler.next(retryErr);
        }
      } else {
        eventBus.emit(const SessionExpiredEvent(reason: 'REFRESH_FAILED'));
      }
    }

    handler.next(err);
  }

  /// Resolves `afab_csrf` from the persistent cookie jar or RAM fallback.
  Future<String?> resolveCsrfToken() async {
    try {
      final baseUri = Uri.parse(AppEnv.apiBaseUrl);
      final cookies = await cookieJar.loadForRequest(baseUri);
      for (final cookie in cookies) {
        if (cookie.name == 'afab_csrf' && cookie.value.isNotEmpty) {
          return Uri.decodeComponent(cookie.value);
        }
      }
    } catch (e) {
      AppLogger.warn('AuthInterceptor', 'Failed loading CSRF cookie', e);
    }
    return tokenHolder.csrfToken;
  }

  /// Single-flight refresh lock so parallel 401 calls share ONE `/auth/refresh`
  /// and never trigger backend `REFRESH_TOKEN_REUSE` token-family revocation.
  Future<bool> tryRefreshToken() async {
    final existing = _inFlightRefresh;
    if (existing != null) {
      return existing.future;
    }

    final completer = Completer<bool>();
    _inFlightRefresh = completer;

    try {
      final csrf = await resolveCsrfToken();
      final headers = <String, dynamic>{
        'Content-Type': 'application/json',
      };
      if (csrf != null && csrf.isNotEmpty) {
        headers['X-CSRF-Token'] = csrf;
      }

      final response = await refreshDio.post<dynamic>(
        '/auth/refresh',
        options: Options(
          headers: headers,
          extra: const {'requireAuth': false},
        ),
      );

      final data = response.data;
      if (data is Map) {
        final accessToken = data['accessToken']?.toString();
        final csrfToken = data['csrfToken']?.toString();
        if (accessToken != null && accessToken.isNotEmpty) {
          tokenHolder.setTokens(
            accessToken: accessToken,
            csrfToken: csrfToken,
          );
          completer.complete(true);
          return true;
        }
      }
      completer.complete(false);
      return false;
    } on DioException catch (err) {
      final status = err.response?.statusCode;
      if (status == 401 || status == 403) {
        AppLogger.warn(
          'AuthInterceptor',
          'Refresh rejected with status $status; clearing local session.',
        );
        await clearLocalSession();
      } else {
        AppLogger.warn(
          'AuthInterceptor',
          'Refresh failed due to network/server error ($status).',
        );
      }
      completer.complete(false);
      return false;
    } catch (e) {
      AppLogger.warn('AuthInterceptor', 'Unexpected refresh error', e);
      completer.complete(false);
      return false;
    } finally {
      _inFlightRefresh = null;
    }
  }

  Future<void> clearLocalSession() async {
    tokenHolder.clear();
    await cookieJar.deleteAll();
    await cookieStorage.clearAllCookies();
  }
}

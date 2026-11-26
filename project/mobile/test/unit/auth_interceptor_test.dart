import 'dart:convert';
import 'dart:typed_data';

import 'package:afab_mobile/core/network/auth_interceptor.dart';
import 'package:afab_mobile/core/network/global_events.dart';
import 'package:afab_mobile/core/storage/encrypted_cookie_storage.dart';
import 'package:afab_mobile/core/storage/session_token_holder.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _InMemorySecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> store = {};

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return Map<String, String>.from(store);
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return store[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      store.remove(key);
    } else {
      store[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    store.remove(key);
  }
}

typedef _AdapterHandler = Future<ResponseBody> Function(RequestOptions options);

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.handler);

  final _AdapterHandler handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonBody(Map<String, dynamic> json, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(json),
    statusCode,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

void main() {
  group('AuthInterceptor single-flight refresh & CSRF', () {
    late SessionTokenHolder tokenHolder;
    late GlobalEventBus eventBus;
    late _InMemorySecureStorage secureStorage;
    late EncryptedCookieStorage cookieStorage;
    late PersistCookieJar cookieJar;
    late Dio retryDio;
    late Dio refreshDio;
    late Dio mainDio;

    setUp(() async {
      tokenHolder = SessionTokenHolder();
      eventBus = GlobalEventBus();
      secureStorage = _InMemorySecureStorage();
      cookieStorage = EncryptedCookieStorage(secureStorage: secureStorage);
      cookieJar = PersistCookieJar(storage: cookieStorage);
      await cookieJar.saveFromResponse(
        Uri.parse('http://127.0.0.1:8080/api/v1'),
        [Cookie('afab_csrf', 'csrf-secret-value')],
      );

      retryDio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8080/api/v1'));
      refreshDio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8080/api/v1'));
      mainDio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8080/api/v1'));

      final interceptor = AuthInterceptor(
        retryDio: retryDio,
        refreshDio: refreshDio,
        cookieJar: cookieJar,
        cookieStorage: cookieStorage,
        tokenHolder: tokenHolder,
        eventBus: eventBus,
      );
      mainDio.interceptors.add(interceptor);
    });

    tearDown(() {
      eventBus.dispose();
    });

    test('coalesces parallel 401 responses into a single /auth/refresh call',
        () async {
      tokenHolder.setTokens(
        accessToken: 'expired-jwt',
        csrfToken: 'csrf-secret-value',
      );

      var refreshCalls = 0;
      String? capturedCsrf;
      bool refreshHadOrigin = true;

      refreshDio.httpClientAdapter = _StubAdapter((options) async {
        refreshCalls++;
        capturedCsrf = options.headers['X-CSRF-Token']?.toString();
        refreshHadOrigin = options.headers.containsKey('Origin');
        await Future<void>.delayed(const Duration(milliseconds: 25));
        return _jsonBody(
          {'accessToken': 'fresh-jwt', 'csrfToken': 'next-csrf'},
          200,
        );
      });

      mainDio.httpClientAdapter = _StubAdapter((options) async {
        return _jsonBody({'code': 'UNAUTHORIZED'}, 401);
      });

      final retriedTokens = <String?>[];
      retryDio.httpClientAdapter = _StubAdapter((options) async {
        retriedTokens.add(options.headers['Authorization']?.toString());
        return _jsonBody({'ok': true, 'path': options.path}, 200);
      });

      final responses = await Future.wait([
        mainDio.get<dynamic>('/dashboard/summary'),
        mainDio.get<dynamic>('/notifications'),
      ]);

      expect(refreshCalls, 1);
      expect(capturedCsrf, 'csrf-secret-value');
      expect(refreshHadOrigin, isFalse);
      expect(tokenHolder.accessToken, 'fresh-jwt');
      expect(retriedTokens, ['Bearer fresh-jwt', 'Bearer fresh-jwt']);
      expect(responses[0].data['ok'], isTrue);
      expect(responses[1].data['ok'], isTrue);
    });

    test('clears session and emits SessionExpiredEvent when refresh returns 401',
        () async {
      tokenHolder.setTokens(
        accessToken: 'stale-jwt',
        csrfToken: 'csrf-secret-value',
      );

      final emitted = <GlobalApiEvent>[];
      final sub = eventBus.stream.listen(emitted.add);

      refreshDio.httpClientAdapter = _StubAdapter((_) async {
        return _jsonBody({'code': 'REFRESH_TOKEN_REUSE'}, 401);
      });
      mainDio.httpClientAdapter = _StubAdapter((_) async {
        return _jsonBody({'code': 'UNAUTHORIZED'}, 401);
      });

      await expectLater(
        mainDio.get<dynamic>('/transactions'),
        throwsA(isA<DioException>()),
      );

      await Future<void>.delayed(Duration.zero);
      expect(tokenHolder.hasAccessToken, isFalse);
      expect(emitted.whereType<SessionExpiredEvent>().length, 1);
      await sub.cancel();
    });

    test('proactively refreshes missing access token on request', () async {
      var refreshCalls = 0;
      refreshDio.httpClientAdapter = _StubAdapter((_) async {
        refreshCalls++;
        return _jsonBody({'accessToken': 'bootstrapped-jwt'}, 200);
      });
      mainDio.httpClientAdapter = _StubAdapter((options) async {
        return _jsonBody(
          {'authHeader': options.headers['Authorization']},
          200,
        );
      });

      final res = await mainDio.get<dynamic>('/user/me');
      expect(refreshCalls, 1);
      expect(res.data['authHeader'], 'Bearer bootstrapped-jwt');
    });
  });
}

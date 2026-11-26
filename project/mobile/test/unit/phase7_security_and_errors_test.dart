import 'dart:typed_data';

import 'package:afab_mobile/app/router/app_router.dart';
import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/error/error_mapper.dart';
import 'package:afab_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/core/network/error_interceptor.dart';
import 'package:afab_mobile/core/network/global_events.dart';
import 'package:afab_mobile/core/network/tenant_interceptor.dart';
import 'package:afab_mobile/core/storage/encrypted_cookie_storage.dart';
import 'package:afab_mobile/core/storage/prefs_store.dart';
import 'package:afab_mobile/core/utils/app_logger.dart';
import 'package:afab_mobile/features/auth/data/auth_dtos.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/auth/domain/session_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _TestHandler extends ErrorInterceptorHandler {
  bool nextCalled = false;

  @override
  void next(DioException err) {
    nextCalled = true;
  }
}

class _SyncNoopAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('/subscription/plans')) {
      return ResponseBody.fromString('{"plans":[]}', 200, headers: {
        Headers.contentTypeHeader: ['application/json'],
      });
    }
    return ResponseBody.fromString('{}', 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }
}

class _UnauthNotifier extends AuthNotifier {
  @override
  SessionState build() =>
      const SessionState(status: SessionStatus.unauthenticated);

  @override
  Future<void> restoreSession() async {}

  @override
  Future<void> refreshProfile() async {}
}

class _AuthedNotifier extends AuthNotifier {
  @override
  SessionState build() => const SessionState(
        status: SessionStatus.authenticated,
        user: UserProfile(
          id: 'u-1',
          firstName: 'Youssef',
          lastName: 'Trabelsi',
          email: 'youssef@carthage.tn',
          emailVerified: true,
          onboardingComplete: true,
          businessId: 'biz-1',
          businessName: 'Carthage Labs',
          currency: 'USD',
        ),
      );

  @override
  Future<void> restoreSession() async {}

  @override
  Future<void> refreshProfile() async {}
}

void main() {
  group('Phase 7 Security, Logging, Interceptors & Routing', () {
    test('AppLogger.sanitizeForTest redacts JWTs, cookies, and emails', () {
      const sample = 'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjMifQ.sig '
          'raw=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1IjoidTEifQ.abc_123 '
          'refreshToken=sec_tok_999; afab_csrf=csrf_888 user=youssef@carthage.tn';

      final sanitized = AppLogger.sanitizeForTest(sample);
      expect(sanitized, contains('Bearer <REDACTED>'));
      expect(sanitized, contains('<JWT_REDACTED>'));
      expect(sanitized, contains('refreshToken=<REDACTED>'));
      expect(sanitized, contains('afab_csrf=<REDACTED>'));
      expect(sanitized, contains('<EMAIL_REDACTED>'));
      expect(sanitized, isNot(contains('youssef@carthage.tn')));
      expect(sanitized, isNot(contains('sec_tok_999')));
      expect(sanitized, isNot(contains('csrf_888')));
    });

    test('ErrorInterceptor differentiates 403/503/429 and clears READ_ONLY workspace', () async {
      SharedPreferences.setMockInitialValues({'active_business_id': 'biz-ro'});
      final prefs = await SharedPreferences.getInstance();
      final prefsStore = PrefsStore(prefs);
      final holder = ActiveBusinessHolder()..setBusinessId('biz-ro');
      final bus = GlobalEventBus();
      final events = <GlobalApiEvent>[];
      final sub = bus.stream.listen(events.add);

      final interceptor = ErrorInterceptor(
        eventBus: bus,
        businessHolder: holder,
        prefsStore: prefsStore,
      );

      DioException dioErr(int status, dynamic data, {Headers? headers}) {
        final req = RequestOptions(path: '/transactions');
        return DioException(
          requestOptions: req,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: req,
            statusCode: status,
            data: data,
            headers: headers ?? Headers(),
          ),
        );
      }

      // 403 PLAN_LIMIT_REACHED
      await interceptor.onError(
        dioErr(403, {
          'code': 'PLAN_LIMIT_REACHED',
          'feature': 'business.max',
          'limit': 1,
          'used': 1,
          'upgradeTo': 'plus',
          'message': 'Limit reached',
        }),
        _TestHandler(),
      );

      // 403 BUSINESS_READ_ONLY clears active business
      await interceptor.onError(
        dioErr(403, {
          'code': 'BUSINESS_READ_ONLY',
          'businessId': 'biz-ro',
          'businessName': 'Locked Corp',
          'message': 'Locked',
        }),
        _TestHandler(),
      );
      expect(holder.businessId, isNull);
      expect(prefsStore.getActiveBusinessId(), isNull);

      // 403 Forbidden (role denial) emits nothing global
      await interceptor.onError(
        dioErr(403, {'code': 'FORBIDDEN', 'message': 'Owners only'}),
        _TestHandler(),
      );

      // Domain 503 codes must NOT trigger MaintenanceDetectedEvent
      for (final domainCode in [
        'AI_SERVICE_UNAVAILABLE',
        'EMAIL_DELIVERY_FAILED',
        'RATE_LIMIT_UNAVAILABLE',
        'BILLING_NOT_CONFIGURED',
      ]) {
        await interceptor.onError(
          dioErr(503, {'code': domainCode, 'message': 'Domain 503'}),
          _TestHandler(),
        );
      }

      // Proxy/infrastructure 503 MUST trigger MaintenanceDetectedEvent
      await interceptor.onError(
        dioErr(503, '<html>Service Unavailable</html>'),
        _TestHandler(),
      );

      await pumpEventQueue();
      expect(events, hasLength(3));
      expect(events[0], isA<PlanLimitReachedEvent>());
      expect(events[1], isA<BusinessReadOnlyEvent>());
      expect(events[2], isA<MaintenanceDetectedEvent>());

      // Verify 429 Retry-After parsing & connection timeout mapping via ErrorMapper
      final rateErr = ErrorMapper.fromDio(
        dioErr(
          429,
          {'code': 'RATE_LIMITED', 'message': 'Slow down'},
          headers: Headers.fromMap({
            'Retry-After': ['45'],
          }),
        ),
      );
      expect(rateErr, isA<RateLimitedFailure>());
      expect((rateErr as RateLimitedFailure).retryAfterSeconds, 45);

      final timeoutErr = ErrorMapper.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/health'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(timeoutErr, isA<NetworkFailure>());

      await sub.cancel();
      bus.dispose();
    });

    test('EncryptedCookieStorage persists and clears cookies via FlutterSecureStorage', () async {
      final storage = _MockSecureStorage();
      final mem = <String, String>{};

      when(() => storage.readAll()).thenAnswer((_) async => Map.from(mem));
      when(() => storage.read(key: any(named: 'key'))).thenAnswer(
        (inv) async => mem[inv.namedArguments[#key] as String],
      );
      when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((inv) async {
        mem[inv.namedArguments[#key] as String] =
            inv.namedArguments[#value] as String;
      });
      when(() => storage.delete(key: any(named: 'key'))).thenAnswer((inv) async {
        mem.remove(inv.namedArguments[#key] as String);
      });

      final cookieStore = EncryptedCookieStorage(secureStorage: storage);
      await cookieStore.init(true, false);
      expect(await cookieStore.hasAnyPersistedCookies(), isFalse);

      await cookieStore.write('afab_host', 'refreshToken=abc; afab_csrf=xyz');
      expect(await cookieStore.read('afab_host'), contains('refreshToken=abc'));
      expect(await cookieStore.hasAnyPersistedCookies(), isTrue);

      await cookieStore.clearAllCookies();
      expect(await cookieStore.hasAnyPersistedCookies(), isFalse);
      expect(mem, isEmpty);
    });

    testWidgets('GoRouter strips /en and /ar locale prefixes while keeping query params intact', (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final noopDio = Dio()..httpClientAdapter = _SyncNoopAdapter();

      // Unauthenticated reset-password deep link with underscore in token
      final unauthContainer = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          dioProvider.overrideWithValue(noopDio),
          authNotifierProvider.overrideWith(_UnauthNotifier.new),
        ],
      );
      try {
        final unauthRouter = unauthContainer.read(appRouterProvider);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: unauthContainer,
            child: MaterialApp.router(
              routerConfig: unauthRouter,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
            ),
          ),
        );
        unauthRouter.go('/en/reset-password?token=tok_abc_123-XYZ');
        await tester.pump();
        await tester.pump();
        expect(
          unauthRouter.routerDelegate.currentConfiguration.uri.toString(),
          '/reset-password?token=tok_abc_123-XYZ',
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        unauthContainer.dispose();
      }

      // Authenticated Stripe return deep link under /ar/dashboard/plans
      final authedContainer = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          dioProvider.overrideWithValue(noopDio),
          authNotifierProvider.overrideWith(_AuthedNotifier.new),
        ],
      );
      try {
        final authedRouter = authedContainer.read(appRouterProvider);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: authedContainer,
            child: MaterialApp.router(
              routerConfig: authedRouter,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
            ),
          ),
        );
        authedRouter.go('/ar/dashboard/plans?checkout=success&session_id=cs_1');
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(
          authedRouter.routerDelegate.currentConfiguration.uri.toString(),
          '/plans?checkout=success&session_id=cs_1',
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        authedContainer.dispose();
      }
    });
  });
}

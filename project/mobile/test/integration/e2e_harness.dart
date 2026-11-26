import 'dart:convert';
import 'dart:typed_data';

import 'package:afab_mobile/app/afab_app.dart';
import 'package:afab_mobile/app/router/app_router.dart';
import 'package:afab_mobile/core/config/env.dart';
import 'package:afab_mobile/core/network/auth_interceptor.dart';
import 'package:afab_mobile/core/network/connectivity_provider.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/core/network/error_interceptor.dart';
import 'package:afab_mobile/core/network/global_events.dart';
import 'package:afab_mobile/core/network/tenant_interceptor.dart';
import 'package:afab_mobile/core/storage/encrypted_cookie_storage.dart';
import 'package:afab_mobile/core/storage/prefs_store.dart';
import 'package:afab_mobile/core/storage/session_token_holder.dart';
import 'package:afab_mobile/features/ai/domain/speech_dictation_service.dart';
import 'package:afab_mobile/features/settings/domain/biometric_lock_service.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InMemorySecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      Map<String, String>.from(_data);

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _data[key];

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
      _data.remove(key);
    } else {
      _data[key] = value;
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
  }) async =>
      _data.remove(key);
}

class StubBiometricService implements BiometricLockService {
  @override
  Future<bool> authenticate(String reason) async => true;
  @override
  Future<void> clearFlag() async {}
  @override
  Future<bool> isEnabled() async => false;
  @override
  Future<bool> isSupportedAndEnrolled() async => true;
  @override
  Future<void> setEnabled(bool enabled) async {}
}

class StubSpeechService implements SpeechDictationService {
  @override
  Future<void> cancel() async {}
  @override
  Future<bool> startListening({
    required DictationLocaleOption locale,
    required void Function(String text, bool isFinal) onResult,
    required void Function(String status) onStatus,
    required void Function(String message, bool permissionDenied) onError,
  }) async =>
      true;
  @override
  Future<void> stop() async {}
}

class MockSpringBootAdapter implements HttpClientAdapter {
  bool healthUp = true;
  bool requireTwoFactor = true;
  int healthCallCount = 0;

  static const _userJson = {
    'id': 'user-e2e-1',
    'firstName': 'Youssef',
    'lastName': 'Trabelsi',
    'email': 'youssef@carthage.tn',
    'emailVerified': true,
    'onboardingComplete': true,
    'businessId': 'biz-e2e-1',
    'businessName': 'Carthage Labs',
    'currency': 'TND',
    'country': 'TN',
    'twoFactorEnabled': true,
    'enableAiInsights': true,
    'planTier': 'PLUS',
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;

    ResponseBody jsonResp(Object body, {int status = 200, Map<String, List<String>>? headers}) {
      return ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
          ...?headers,
        },
      );
    }

    if (path.endsWith('/health')) {
      healthCallCount++;
      if (!healthUp) {
        return jsonResp({'status': 'DOWN'}, status: 503);
      }
      return jsonResp({
        'status': 'UP',
        'service': 'afab-backend',
        'mail': {'status': 'UP'},
      });
    }

    if (path.endsWith('/auth/login')) {
      if (requireTwoFactor) {
        return jsonResp({
          'requiresTwoFactor': true,
          'twoFactorToken': 'e2e-2fa-token',
        });
      }
      return jsonResp({
        'accessToken': 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.e2e.sig',
        'csrfToken': 'csrf-e2e',
        'user': _userJson,
      });
    }

    if (path.endsWith('/auth/2fa/verify-login')) {
      return jsonResp(
        {
          'accessToken': 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.e2e.sig',
          'csrfToken': 'csrf-e2e',
          'user': _userJson,
        },
        headers: {
          'set-cookie': [
            'refreshToken=rt-e2e-1; Path=/; HttpOnly',
            'afab_csrf=csrf-e2e; Path=/',
          ],
        },
      );
    }

    if (path.endsWith('/auth/refresh')) {
      return jsonResp({
        'accessToken': 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.e2e_refreshed.sig',
        'csrfToken': 'csrf-e2e',
        'user': _userJson,
      });
    }

    if (path.endsWith('/auth/logout')) {
      return jsonResp({'success': true});
    }

    if (path.endsWith('/user/me')) {
      return jsonResp(_userJson);
    }

    if (path.endsWith('/business') && options.method == 'GET') {
      return jsonResp([
        {
          'id': 'biz-e2e-1',
          'name': 'Carthage Labs',
          'country': 'TN',
          'currency': 'TND',
          'timezone': 'Africa/Tunis',
          'fiscalYearStartMonth': 1,
          'industry': 'technology',
          'userRole': 'OWNER',
          'active': true,
          'accessMode': 'EDITABLE',
          'editable': true,
          'primary': true,
        },
      ]);
    }

    if (path.endsWith('/subscription/me')) {
      return jsonResp({
        'planSlug': 'plus',
        'planName': 'Plus',
        'status': 'ACTIVE',
        'currency': 'USD',
        'editableBusinessLimit': 3,
        'editableBusinessCount': 1,
        'totalBusinessCount': 1,
        'hasStripeCustomer': true,
        'hasActiveStripeSubscription': true,
        'stripeConfigured': true,
      });
    }

    if (path.endsWith('/dashboard/summary')) {
      return jsonResp({
        'currency': 'TND',
        'businessName': 'Carthage Labs',
        'kpiData': {
          'revenue': {'value': 'DT 12,450.000', 'change': '+12%', 'isPositive': true, 'rawValue': 12450, 'rawChange': 12},
          'expenses': {'value': 'DT 3,200.000', 'change': '-4%', 'isPositive': false, 'rawValue': 3200, 'rawChange': -4},
          'profit': {'value': 'DT 9,250.000', 'change': '+18%', 'isPositive': true, 'rawValue': 9250, 'rawChange': 18},
          'cashFlow': {'value': 'DT 8,900.000', 'change': '+9%', 'isPositive': true, 'rawValue': 8900, 'rawChange': 9},
        },
        'revenueData': [
          {'month': 'Nov', 'name': 'Nov', 'revenue': 12450, 'expenses': 3200},
        ],
        'transactions': [
          {
            'id': 'tx-e2e-1',
            'name': 'Cloud Retainer',
            'description': 'Monthly SaaS Invoice',
            'rawAmount': 2500,
            'date': '2026-11-20',
            'type': 'INCOME',
            'status': 'COMPLETED',
            'initials': 'CR',
            'isCredit': true,
          },
        ],
        'expenseCategories': [],
        'reminders': [],
        'customers': [],
        'budgets': {
          'currency': 'TND',
          'activeBudgetCount': 0,
          'approachingCount': 0,
          'overBudgetCount': 0,
          'budgets': [],
        },
      });
    }

    if (path.endsWith('/ai/pulse')) {
      return jsonResp({'currency': 'TND', 'alerts': []});
    }

    if (path.endsWith('/notifications')) {
      return jsonResp({'unreadCount': 0, 'notifications': []});
    }

    if (path.endsWith('/categories')) {
      return jsonResp([]);
    }

    if (path.endsWith('/transactions')) {
      return jsonResp({
        'content': [
          {
            'id': 'tx-e2e-1',
            'type': 'INCOME',
            'amount': '2500.000',
            'currency': 'TND',
            'description': 'Monthly SaaS Invoice',
            'transactionDate': '2026-11-20',
            'paymentMethod': 'BANK_TRANSFER',
            'status': 'COMPLETED',
          },
        ],
        'pageNumber': 0,
        'pageSize': 15,
        'totalElements': 1,
        'totalPages': 1,
        'totalInflow': 2500,
        'totalOutflow': 0,
        'netBalance': 2500,
        'currency': 'TND',
      });
    }

    if (path.endsWith('/invoices/summary')) {
      return jsonResp({
        'totalInvoices': 1,
        'draftInvoices': 0,
        'sentInvoices': 1,
        'paidInvoices': 0,
        'pendingInvoices': 1,
        'overdueInvoices': 0,
        'totalInvoiceAmount': 2500,
        'paidAmount': 0,
        'pendingAmount': 2500,
        'overdueAmount': 0,
        'currency': 'TND',
        'statusBreakdown': [],
        'upcomingDueList': [],
      });
    }

    if (path.endsWith('/invoices')) {
      return jsonResp({
        'content': [
          {
            'id': 'inv-e2e-1',
            'businessId': 'biz-e2e-1',
            'invoiceNumber': 'INV-2026-E2E',
            'customerName': 'Medina Partners',
            'status': 'SENT',
            'storedStatus': 'SENT',
            'overdue': false,
            'issueDate': '2026-11-15',
            'dueDate': '2026-12-15',
            'currency': 'TND',
            'subtotal': '2500.000',
            'discountAmount': '0.000',
            'taxAmount': '0.000',
            'totalAmount': '2500.000',
            'paidAmount': '0.000',
            'outstandingBalance': '2500.000',
          },
        ],
        'pageNumber': 0,
        'pageSize': 15,
        'totalElements': 1,
        'totalPages': 1,
        'totalInvoiced': 2500,
        'totalPaid': 0,
        'totalOutstanding': 2500,
        'currency': 'TND',
      });
    }

    if (path.endsWith('/customers')) {
      return jsonResp({
        'content': [],
        'totalElements': 0,
        'totalPages': 0,
        'pageNumber': 0,
        'pageSize': 15,
      });
    }

    if (path.endsWith('/ai/status')) {
      return jsonResp({
        'health': {
          'enabled': true,
          'ollamaReachable': true,
          'chatModel': 'gemma4:e4b',
          'chatModelReady': true,
          'chatModelLoaded': true,
          'embedModel': 'embeddinggemma-2:270m',
          'embedModelReady': true,
          'busy': false,
        },
        'indexedChunks': 5,
        'approvedMemories': 1,
        'quota': {
          'monthlyTokensUsed': 100,
          'monthlyTokensLimit': 10000,
          'monthlyTokensRemaining': 9900,
          'monthlyQueriesUsed': 1,
          'monthlyQueriesLimit': 50,
          'monthlyQueriesRemaining': 49,
          'planSlug': 'plus',
          'planName': 'Plus',
        },
      });
    }

    if (path.endsWith('/ai/health')) {
      return jsonResp({
        'enabled': true,
        'ollamaReachable': true,
        'chatModel': 'gemma4:e4b',
        'chatModelReady': true,
      });
    }

    if (path.endsWith('/ai/conversations')) {
      return jsonResp([]);
    }

    if (path.endsWith('/billing/history')) {
      return jsonResp({'paymentHistory': [], 'subscriptionHistory': []});
    }

    if (path.endsWith('/business/allocations')) {
      return jsonResp({
        'currentPlanSlug': 'plus',
        'currentPlanName': 'Plus',
        'editableLimit': 3,
        'editableCount': 1,
        'readOnlyCount': 0,
        'totalOwnedCount': 1,
        'allocationAttentionRequired': false,
        'businesses': [
          {
            'id': 'biz-e2e-1',
            'name': 'Carthage Labs',
            'currency': 'TND',
            'editable': true,
            'primary': true,
            'active': true,
          },
        ],
      });
    }

    return jsonResp({});
  }

  @override
  void close({bool force = false}) {}
}

Future<
    ({
      GlobalEventBus bus,
      MockSpringBootAdapter adapter,
      ProviderContainer container,
      Future<void> Function() dispose,
    })> pumpAfabE2eApp(
  WidgetTester tester, {
  bool withPersistedRefreshCookie = false,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final secure = InMemorySecureStorage();
  if (withPersistedRefreshCookie) {
    await secure.write(
      key: 'afab_e2e_seed',
      value: 'refreshToken=seeded-rt; afab_csrf=seeded-csrf',
    );
  }
  final cookieStorage = EncryptedCookieStorage(secureStorage: secure);
  final cookieJar = PersistCookieJar(ignoreExpires: false, storage: cookieStorage);
  final tokenHolder = SessionTokenHolder();
  final bus = GlobalEventBus();
  final adapter = MockSpringBootAdapter();
  final prefsStore = PrefsStore(prefs);
  final bizHolder = ActiveBusinessHolder();

  Dio makeDio() {
    final dio = Dio(BaseOptions(baseUrl: AppEnv.apiBaseUrl))
      ..httpClientAdapter = adapter;
    return dio;
  }

  final refreshDio = makeDio()..interceptors.add(CookieManager(cookieJar));
  final retryDio = makeDio()
    ..interceptors.addAll([
      CookieManager(cookieJar),
      TenantInterceptor(bizHolder),
      ErrorInterceptor(eventBus: bus, businessHolder: bizHolder, prefsStore: prefsStore),
    ]);
  final authInterceptor = AuthInterceptor(
    retryDio: retryDio,
    refreshDio: refreshDio,
    cookieJar: cookieJar,
    cookieStorage: cookieStorage,
    tokenHolder: tokenHolder,
    eventBus: bus,
  );
  final mainDio = makeDio()
    ..interceptors.addAll([
      CookieManager(cookieJar),
      authInterceptor,
      TenantInterceptor(bizHolder),
      ErrorInterceptor(eventBus: bus, businessHolder: bizHolder, prefsStore: prefsStore),
    ]);
  final sseDio = makeDio()
    ..interceptors.addAll([
      CookieManager(cookieJar),
      authInterceptor,
      TenantInterceptor(bizHolder),
      ErrorInterceptor(eventBus: bus, businessHolder: bizHolder, prefsStore: prefsStore),
    ]);

  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      encryptedCookieStorageProvider.overrideWithValue(cookieStorage),
      cookieJarProvider.overrideWithValue(cookieJar),
      sessionTokenHolderProvider.overrideWithValue(tokenHolder),
      activeBusinessHolderProvider.overrideWithValue(bizHolder),
      globalEventBusProvider.overrideWithValue(bus),
      refreshDioProvider.overrideWithValue(refreshDio),
      authInterceptorProvider.overrideWithValue(authInterceptor),
      dioProvider.overrideWithValue(mainDio),
      sseDioProvider.overrideWithValue(sseDio),
      isOnlineProvider.overrideWithValue(true),
      biometricLockServiceProvider.overrideWithValue(StubBiometricService()),
      speechDictationServiceProvider.overrideWithValue(StubSpeechService()),
    ],
  );

  var disposed = false;
  Future<void> dispose() async {
    if (disposed) return;
    disposed = true;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    container.dispose();
    bus.dispose();
  }

  addTearDown(() async {
    if (!disposed) {
      disposed = true;
      container.dispose();
      bus.dispose();
    }
  });

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const AfabApp(),
    ),
  );
  await tester.pumpAndSettle();

  return (bus: bus, adapter: adapter, container: container, dispose: dispose);
}

Future<void> signInThrough2FaToDashboard(WidgetTester tester) async {
  expect(find.text('Log in to your account'), findsOneWidget);
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'youssef@carthage.tn');
  await tester.enterText(fields.at(1), 'SecurePass!2026');
  await tester.pumpAndSettle();

  final loginBtn = find.widgetWithText(AfabButton, 'Log In');
  await tester.ensureVisible(loginBtn);
  await tester.tap(loginBtn);
  await tester.pumpAndSettle();

  expect(find.widgetWithText(AfabButton, 'Verify & Sign In'), findsOneWidget);
  await tester.enterText(find.byType(TextFormField).first, '123456');
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(AfabButton, 'Verify & Sign In'));
  await tester.pumpAndSettle();

  expect(find.text('DT 12,450.000'), findsOneWidget);
}

Future<void> runAllAfabE2eJourneys(WidgetTester tester) async {
  // Journey 1: Cold-start Splash -> Login -> 2FA -> Dashboard
  final harness = await pumpAfabE2eApp(tester);
  try {
    await signInThrough2FaToDashboard(tester);
    expect(tester.takeException(), isNull);

    // Journey 2: Bottom navigation shell tabs + deep link 404 recovery
    await tester.tap(find.text('Finance').last);
    await tester.pumpAndSettle();
    expect(find.text('Monthly SaaS Invoice'), findsOneWidget);

    await tester.tap(find.text('Invoices').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('INV-2026-E2E'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('INV-2026-E2E'), findsOneWidget);

    // Scroll back up to reveal the auto-hiding bottom navigation bar before switching tabs
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 350));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Copilot').last);
    await tester.pumpAndSettle();
    expect(find.text('Morning CFO Brief'), findsOneWidget);

    await tester.tap(find.text('More').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Settings'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Settings'), findsWidgets);

    // Navigate to unknown route -> NotFoundScreen -> recover back to Dashboard
    final router = harness.container.read(appRouterProvider);
    router.go('/unknown-deep-link');
    await tester.pumpAndSettle();
    expect(find.text('404'), findsOneWidget);
    await tester.tap(find.text('Go to Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('DT 12,450.000'), findsOneWidget);

    // Journey 3: Maintenance outage + health check recovery, and Session Expiry -> Login
    harness.adapter.healthUp = false;
    harness.bus.emit(const MaintenanceDetectedEvent());
    await tester.pumpAndSettle();
    expect(find.text("We're Under Maintenance"), findsOneWidget);

    harness.adapter.healthUp = true;
    await tester.tap(find.text('Check Server Health'));
    await tester.pumpAndSettle();
    expect(harness.adapter.healthCallCount, greaterThanOrEqualTo(1));

    harness.bus.emit(const SessionExpiredEvent(reason: 'TEST_EXPIRED'));
    await tester.pumpAndSettle();
    expect(find.text('Log in to your account'), findsOneWidget);
    expect(tester.takeException(), isNull);
  } finally {
    await harness.dispose();
  }
}

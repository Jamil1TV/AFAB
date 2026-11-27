import 'dart:convert';
import 'dart:typed_data';

import 'package:afab_mobile/app/afab_app.dart';
import 'package:afab_mobile/app/shell/afab_floating_nav_dock.dart';
import 'package:afab_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/core/network/global_events.dart';
import 'package:afab_mobile/core/theme/appearance_settings.dart';
import 'package:afab_mobile/core/theme/appearance_theme_builder.dart';
import 'package:afab_mobile/features/app_states/error_and_not_found_screen.dart';
import 'package:afab_mobile/features/app_states/maintenance_screen.dart';
import 'package:afab_mobile/features/auth/data/auth_dtos.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/auth/domain/session_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _HealthAdapter implements HttpClientAdapter {
  _HealthAdapter(this.healthy);
  bool healthy;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (!healthy) {
      return ResponseBody.fromString(
        'Down',
        503,
        headers: {
          Headers.contentTypeHeader: ['text/plain'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({
        'status': 'UP',
        'service': 'afab-backend',
        'mail': {'status': 'UP'},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this._initial);
  final SessionState _initial;

  @override
  SessionState build() => _initial;

  @override
  Future<void> restoreSession() async {}
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _wrapRouter({
  required SharedPreferences prefs,
  required Widget home,
  SessionState session = const SessionState(status: SessionStatus.unauthenticated),
  Dio? dio,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
}) {
  final router = GoRouter(
    initialLocation: '/target',
    routes: [
      GoRoute(path: '/target', builder: (_, _) => home),
      GoRoute(path: '/splash', builder: (_, _) => const Scaffold(body: Text('SPLASH_OK'))),
      GoRoute(path: '/login', builder: (_, _) => const Scaffold(body: Text('LOGIN_OK'))),
      GoRoute(path: '/dashboard', builder: (_, _) => const Scaffold(body: Text('DASHBOARD_OK'))),
      GoRoute(path: '/plans', builder: (_, _) => const Scaffold(body: Text('PLANS_OK'))),
    ],
  );

  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authNotifierProvider.overrideWith(() => _StubAuthNotifier(session)),
      if (dio != null) dioProvider.overrideWithValue(dio),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppearanceThemeBuilder.build(
        settings: const AppearanceSettings(),
        brightness: brightness,
        locale: locale,
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Phase 7 Global App States Screens & Modals', () {
    testWidgets('MaintenanceScreen probes /health and recovers cleanly on 200 UP', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final adapter = _HealthAdapter(false);
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'))
        ..httpClientAdapter = adapter;

      _setViewport(tester, const Size(320, 568));
      await tester.pumpWidget(
        _wrapRouter(
          prefs: prefs,
          dio: dio,
          home: const MaintenanceScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AfabFloatingNavDock), findsNothing);
      await tester.ensureVisible(find.text('Check Server Health'));
      await tester.tap(find.text('Check Server Health'));
      await tester.pumpAndSettle();
      expect(find.text('Backend Unreachable'), findsOneWidget);
      expect(tester.takeException(), isNull);

      adapter.healthy = true;
      await tester.tap(find.text('Check Server Health'));
      await tester.pumpAndSettle();
      expect(find.text('SPLASH_OK'), findsOneWidget);

      // Tablet 768x1024 Dark AR RTL check
      _setViewport(tester, const Size(768, 1024));
      await tester.pumpWidget(
        _wrapRouter(
          prefs: prefs,
          dio: dio,
          locale: const Locale('ar'),
          brightness: Brightness.dark,
          home: const MaintenanceScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ErrorAndNotFoundScreen is auth-aware and AfabSafeErrorCard works standalone', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Unauthenticated -> routes to /login
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _wrapRouter(
          prefs: prefs,
          home: const ErrorAndNotFoundScreen(isNotFound: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('404'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();
      expect(find.text('LOGIN_OK'), findsOneWidget);

      // Authenticated error mode with retry
      var retried = false;
      await tester.pumpWidget(
        _wrapRouter(
          prefs: prefs,
          session: const SessionState(
            status: SessionStatus.authenticated,
            user: UserProfile(
              id: 'u1',
              firstName: 'Youssef',
              lastName: 'Trabelsi',
              email: 'youssef@carthage.tn',
              emailVerified: true,
              onboardingComplete: true,
              currency: 'USD',
            ),
          ),
          home: ErrorAndNotFoundScreen(
            isNotFound: false,
            onRetry: () => retried = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Go to Dashboard'), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      expect(retried, isTrue);

      // Standalone safe error card without MaterialApp ancestor
      await tester.pumpWidget(
        const AfabSafeErrorCard(debugDetails: 'Sanitized test trace'),
      );
      expect(find.text('Unable to display this section'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('PlanLimitSheet & BusinessReadOnlySheet render & AfabApp deduplicates bursts', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final bus = GlobalEventBus();
      addTearDown(bus.dispose);

      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            globalEventBusProvider.overrideWithValue(bus),
            authNotifierProvider.overrideWith(
              () => _StubAuthNotifier(
                const SessionState(status: SessionStatus.unauthenticated),
              ),
            ),
          ],
          child: const AfabApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Emit 3 bursts of PlanLimitReachedEvent -> only 1 sheet opens
      for (var i = 0; i < 3; i++) {
        bus.emit(
          const PlanLimitReachedEvent(
            feature: 'business.max',
            limit: 1,
            used: 1,
            upgradeTo: 'plus',
            message: 'Upgrade required',
          ),
        );
      }
      await tester.pumpAndSettle();
      expect(find.text('Plan Limit Reached'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.textContaining('Workspaces'), findsOneWidget);

      // Close sheet, then verify ReadOnlySheet
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      bus.emit(
        const BusinessReadOnlyEvent(
          businessId: 'b2',
          businessName: 'Locked Branch',
          message: 'Locked',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Workspace is Read-Only'), findsOneWidget);
      expect(find.textContaining('Locked Branch'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

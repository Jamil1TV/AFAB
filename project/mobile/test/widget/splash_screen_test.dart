import 'package:afab_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/core/theme/appearance_settings.dart';
import 'package:afab_mobile/core/theme/appearance_theme_builder.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/auth/domain/session_state.dart';
import 'package:afab_mobile/features/auth/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SplashAuthStub extends AuthNotifier {
  _SplashAuthStub(this._initial);

  final SessionState _initial;
  int restoreCalls = 0;

  @override
  SessionState build() => _initial;

  @override
  Future<void> restoreSession() async {
    restoreCalls++;
  }
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _wrapSplash({
  required SharedPreferences prefs,
  required _SplashAuthStub authStub,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
}) {
  const settings = AppearanceSettings();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authNotifierProvider.overrideWith(() => authStub),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppearanceThemeBuilder.build(
        settings: settings,
        brightness: brightness,
        locale: locale,
      ),
      home: const SplashScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Branded SplashScreen widget tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets(
        'renders AFAB logo, wordmark, tagline, and progress indicator without overflow',
        (tester) async {
      _setViewport(tester, const Size(390, 844));
      final stub = _SplashAuthStub(
        const SessionState(status: SessionStatus.restoring),
      );

      await tester.pumpWidget(
        _wrapSplash(prefs: prefs, authStub: stub, brightness: Brightness.dark),
      );
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('AFAB'), findsOneWidget);
      expect(find.text('AI Finance Assistant for Business'), findsOneWidget);
      expect(stub.restoreCalls, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on Arabic RTL short landscape (860x320)',
        (tester) async {
      _setViewport(tester, const Size(860, 320));
      final stub = _SplashAuthStub(
        const SessionState(status: SessionStatus.restoring),
      );

      await tester.pumpWidget(
        _wrapSplash(
          prefs: prefs,
          authStub: stub,
          locale: const Locale('ar'),
          brightness: Brightness.light,
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('AFAB'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('offlineError state shows retry card and re-invokes restore',
        (tester) async {
      _setViewport(tester, const Size(390, 844));
      final stub = _SplashAuthStub(
        const SessionState(status: SessionStatus.offlineError),
      );

      await tester.pumpWidget(_wrapSplash(prefs: prefs, authStub: stub));
      await tester.pump();

      expect(find.text('Connection Issue'), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      await tester.pump();

      expect(stub.restoreCalls, 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'selects splash_logo_light.png in Light Mode and splash_logo_dark.png in Dark Mode',
      (tester) async {
        _setViewport(tester, const Size(390, 844));
        final stubLight = _SplashAuthStub(
          const SessionState(status: SessionStatus.restoring),
        );

        await tester.pumpWidget(
          _wrapSplash(
            prefs: prefs,
            authStub: stubLight,
            brightness: Brightness.light,
          ),
        );
        await tester.pump(const Duration(milliseconds: 700));
        final lightImage = tester.widget<Image>(find.byType(Image).first);
        expect(
          (lightImage.image as AssetImage).assetName,
          'assets/branding/splash_logo_light.png',
        );

        final stubDark = _SplashAuthStub(
          const SessionState(status: SessionStatus.restoring),
        );
        await tester.pumpWidget(
          _wrapSplash(
            prefs: prefs,
            authStub: stubDark,
            brightness: Brightness.dark,
          ),
        );
        await tester.pump(const Duration(milliseconds: 700));
        final darkImage = tester.widget<Image>(find.byType(Image).first);
        expect(
          (darkImage.image as AssetImage).assetName,
          'assets/branding/splash_logo_dark.png',
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}

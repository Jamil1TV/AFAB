import 'package:afab_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/core/theme/appearance_settings.dart';
import 'package:afab_mobile/core/theme/appearance_theme_builder.dart';
import 'package:afab_mobile/features/auth/data/auth_dtos.dart';
import 'package:afab_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/auth/domain/session_state.dart';
import 'package:afab_mobile/features/auth/presentation/email_verification_screen.dart';
import 'package:afab_mobile/features/auth/presentation/forgot_password_screen.dart';
import 'package:afab_mobile/features/auth/presentation/login_screen.dart';
import 'package:afab_mobile/features/auth/presentation/onboarding_screen.dart';
import 'package:afab_mobile/features/auth/presentation/reset_password_screen.dart';
import 'package:afab_mobile/features/auth/presentation/signup_screen.dart';
import 'package:afab_mobile/features/auth/presentation/two_factor_challenge_screen.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthRepository extends Fake implements AuthRepository {
  @override
  Future<void> validateResetToken({required String token}) async {}
}

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this._initial);

  final SessionState _initial;

  @override
  SessionState build() => _initial;
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _wrapScreen({
  required SharedPreferences prefs,
  required Widget child,
  SessionState initialSession = const SessionState(
    status: SessionStatus.unauthenticated,
  ),
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
}) {
  const settings = AppearanceSettings();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      authNotifierProvider.overrideWith(() => _StubAuthNotifier(initialSession)),
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
      home: child,
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Phase 1 Auth & Onboarding widget tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('LoginScreen renders and validates empty submission in Light EN',
        (tester) async {
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _wrapScreen(prefs: prefs, child: const LoginScreen()),
      );
      await tester.pumpAndSettle();

      final logInButtons = find.widgetWithText(AfabButton, 'Log In');
      expect(logInButtons, findsOneWidget);
      await tester.ensureVisible(logInButtons);
      await tester.tap(logInButtons);
      await tester.pumpAndSettle();

      expect(find.text('Email address is required.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('LoginScreen renders cleanly in Arabic RTL Dark Mode',
        (tester) async {
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _wrapScreen(
          prefs: prefs,
          locale: const Locale('ar'),
          brightness: Brightness.dark,
          child: const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TwoFactorChallengeScreen toggles TOTP and backup code mode',
        (tester) async {
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _wrapScreen(
          prefs: prefs,
          initialSession: const SessionState(
            status: SessionStatus.requiresTwoFactor,
            twoFactorToken: 'two-fa-token',
          ),
          child: const TwoFactorChallengeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Use emergency backup recovery code'), findsOneWidget);
      await tester.tap(find.text('Use emergency backup recovery code'));
      await tester.pumpAndSettle();

      expect(find.text('Use 6-digit authenticator code'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SignUpScreen renders live 5-rule password checklist',
        (tester) async {
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _wrapScreen(prefs: prefs, child: const SignUpScreen()),
      );
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.last, 'Afab!2026');
      await tester.pumpAndSettle();

      expect(find.text('At least 8 characters'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'EmailVerificationScreen, ForgotPasswordScreen, ResetPasswordScreen render',
        (tester) async {
      _setViewport(tester, const Size(390, 844));
      const unverifiedUser = UserProfile(
        id: 'u1',
        firstName: 'Youssef',
        lastName: 'Ben',
        email: 'youssef@afab.ai',
        emailVerified: false,
        onboardingComplete: false,
      );

      await tester.pumpWidget(
        _wrapScreen(
          prefs: prefs,
          initialSession: const SessionState(
            status: SessionStatus.authenticated,
            user: unverifiedUser,
            devOtp: '123456',
          ),
          child: const EmailVerificationScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('123456'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        _wrapScreen(prefs: prefs, child: const ForgotPasswordScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Forgot your password?'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        _wrapScreen(
          prefs: prefs,
          child: const ResetPasswordScreen(initialToken: 'abc_123-XYZ'),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('OnboardingScreen renders cleanly', (tester) async {
      _setViewport(tester, const Size(390, 844));
      const pendingOnboarding = UserProfile(
        id: 'u1',
        firstName: 'Youssef',
        lastName: 'Ben',
        email: 'youssef@afab.ai',
        emailVerified: true,
        businessId: 'biz-1',
        businessName: 'Carthage Labs',
        onboardingComplete: false,
      );

      await tester.pumpWidget(
        _wrapScreen(
          prefs: prefs,
          initialSession: const SessionState(
            status: SessionStatus.authenticated,
            user: pendingOnboarding,
          ),
          child: const OnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Continue'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'LoginScreen renders without RenderFlex overflow on wide short landscape (860x320) & split panel (860x530)',
        (tester) async {
      _setViewport(tester, const Size(860, 320));
      await tester.pumpWidget(
        _wrapScreen(prefs: prefs, child: const LoginScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      _setViewport(tester, const Size(860, 530));
      await tester.pumpWidget(
        _wrapScreen(prefs: prefs, child: const LoginScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

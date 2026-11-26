import 'package:afab_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/core/theme/appearance_settings.dart';
import 'package:afab_mobile/core/theme/appearance_theme_builder.dart';
import 'package:afab_mobile/features/auth/data/auth_dtos.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/auth/domain/session_state.dart';
import 'package:afab_mobile/features/business/data/business_dto.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/calendar/presentation/financial_calendar_screen.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:afab_mobile/features/transactions/data/transaction_repository.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AuthStub extends AuthNotifier {
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
          currency: 'TND',
        ),
      );
}

class _FakeTxRepo extends TransactionRepository {
  _FakeTxRepo() : super(Dio());

  final List<(String?, String?)> requestedWindows = [];

  @override
  Future<TransactionPageDto> getTransactions({
    TransactionType? type,
    String? categoryId,
    TransactionStatus? status,
    PaymentMethod? paymentMethod,
    bool? taxDeductible,
    String? startDate,
    String? endDate,
    String? search,
    int page = 0,
    int size = 15,
    CancelToken? cancelToken,
  }) async {
    requestedWindows.add((startDate, endDate));
    final now = DateTime.now();
    final day10 =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-10';
    return TransactionPageDto(
      content: [
        TransactionDto(
          id: 'tx-cal-1',
          type: TransactionType.income,
          amount: Decimal.parse('500.000'),
          currency: 'TND',
          description: 'Client Milestone',
          transactionDate: day10,
          paymentMethod: PaymentMethod.bankTransfer,
          status: TransactionStatus.completed,
        ),
      ],
      pageNumber: 0,
      pageSize: 100,
      totalElements: 1,
      totalPages: 1,
      totalInflow: Decimal.parse('500.000'),
      totalOutflow: Decimal.zero,
      netBalance: Decimal.parse('500.000'),
      currency: 'TND',
    );
  }
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _wrap({
  required SharedPreferences prefs,
  required _FakeTxRepo txRepo,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
}) {
  const settings = AppearanceSettings();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authNotifierProvider.overrideWith(_AuthStub.new),
      businessListProvider.overrideWith(
        (ref) async => const [
          BusinessDto(
            id: 'biz-1',
            name: 'Carthage Labs',
            currency: 'TND',
            active: true,
          ),
        ],
      ),
      activeBusinessIdProvider.overrideWith(ActiveBusinessIdNotifier.new),
      transactionRepositoryProvider.overrideWithValue(txRepo),
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
      home: const FinancialCalendarScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('FinancialCalendarScreen widget tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets(
        'fetches exact month window, steps previous month, opens DayActivitySheet on phone, and renders Dark AR tablet cleanly',
        (tester) async {
      final repo = _FakeTxRepo();
      _setViewport(tester, const Size(390, 844));

      await tester.pumpWidget(_wrap(prefs: prefs, txRepo: repo));
      await tester.pumpAndSettle();

      expect(repo.requestedWindows.length, 1);
      final initialWindow = repo.requestedWindows.first;
      expect(initialWindow.$1, endsWith('-01'));

      // Step to previous month
      await tester.tap(find.byIcon(LucideIcons.chevronLeft));
      await tester.pumpAndSettle();
      expect(repo.requestedWindows.length, 2);
      expect(repo.requestedWindows[1].$1, isNot(initialWindow.$1));

      // Return to Today (where day 10 Client Milestone resides)
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      // Tap day 10 to open DayActivitySheet
      final day10 = find.text('10').first;
      await tester.ensureVisible(day10);
      await tester.pumpAndSettle();
      await tester.tap(day10);
      await tester.pumpAndSettle();
      expect(find.text('Client Milestone'), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);

      // Tablet Dark AR RTL
      _setViewport(tester, const Size(1024, 768));
      await tester.pumpWidget(
        _wrap(
          prefs: prefs,
          txRepo: repo,
          locale: const Locale('ar'),
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

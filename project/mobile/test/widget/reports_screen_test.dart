import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/core/theme/appearance_settings.dart';
import 'package:afab_mobile/core/theme/appearance_theme_builder.dart';
import 'package:afab_mobile/features/auth/data/auth_dtos.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/auth/domain/session_state.dart';
import 'package:afab_mobile/features/business/data/business_dto.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:afab_mobile/features/reports/data/report_dtos.dart';
import 'package:afab_mobile/features/reports/data/reports_repository.dart';
import 'package:afab_mobile/features/reports/presentation/reports_screen.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _FakeReportsRepo extends ReportsRepository {
  _FakeReportsRepo() : super(Dio());

  bool gateComparison = false;
  final List<(String, String)> comparisonCalls = [];

  @override
  Future<ProfitAndLossReportDto> getProfitAndLoss({
    required String period,
    String? startDate,
    String? endDate,
    CancelToken? cancelToken,
  }) async {
    return ProfitAndLossReportDto(
      period: 'November 2026',
      startDate: '2026-11-01T00:00:00Z',
      endDate: '2026-11-30T23:59:59Z',
      currency: 'TND',
      totalRevenue: Decimal.parse('12000.000'),
      totalExpenses: Decimal.parse('4500.000'),
      grossProfit: Decimal.parse('12000.000'),
      netOperatingIncome: Decimal.parse('7500.000'),
      profitMarginPct: 62.5,
      revenueBreakdown: [
        CategoryShareDto(
          categoryName: 'SaaS Sales',
          amount: Decimal.parse('12000.000'),
          percentage: 100.0,
          transactionCount: 5,
        ),
      ],
      expenseBreakdown: [
        CategoryShareDto(
          categoryName: 'Cloud Hosting',
          amount: Decimal.parse('4500.000'),
          percentage: 100.0,
          transactionCount: 2,
        ),
      ],
    );
  }

  @override
  Future<CashFlowReportDto> getCashFlow({
    required String period,
    String? startDate,
    String? endDate,
    CancelToken? cancelToken,
  }) async {
    return CashFlowReportDto(
      period: 'November 2026',
      startDate: '2026-11-01T00:00:00Z',
      endDate: '2026-11-30T23:59:59Z',
      currency: 'TND',
      cashInflow: Decimal.parse('12000.000'),
      cashOutflow: Decimal.parse('4500.000'),
      netCashChange: Decimal.parse('7500.000'),
      monthlyTrend: [
        MonthlyCashFlowDto(
          month: '2026-10',
          inflow: Decimal.parse('8000.000'),
          outflow: Decimal.parse('3000.000'),
          net: Decimal.parse('5000.000'),
        ),
        MonthlyCashFlowDto(
          month: '2026-11',
          inflow: Decimal.parse('12000.000'),
          outflow: Decimal.parse('4500.000'),
          net: Decimal.parse('7500.000'),
        ),
      ],
    );
  }

  @override
  Future<ComparisonReportDto> getComparison({
    required String primaryPeriod,
    required String comparisonPeriod,
    CancelToken? cancelToken,
  }) async {
    comparisonCalls.add((primaryPeriod, comparisonPeriod));
    if (gateComparison) {
      throw const PlanLimitReachedFailure(
        message: 'Period comparison requires Plus or Pro.',
        feature: 'reports.level',
        limit: 0,
        used: 0,
        upgradeTo: 'plus',
      );
    }
    return ComparisonReportDto(
      currency: 'TND',
      primaryPeriodLabel: primaryPeriod,
      primaryRevenue: Decimal.parse('12000.000'),
      primaryExpenses: Decimal.parse('4500.000'),
      primaryNetIncome: Decimal.parse('7500.000'),
      comparisonPeriodLabel: comparisonPeriod,
      comparisonRevenue: Decimal.parse('9000.000'),
      comparisonExpenses: Decimal.parse('5000.000'),
      comparisonNetIncome: Decimal.parse('4000.000'),
      revenueDifference: Decimal.parse('3000.000'),
      revenueDifferencePct: 33.3,
      expensesDifference: Decimal.parse('-500.000'),
      expensesDifferencePct: -10.0,
      netIncomeDifference: Decimal.parse('3500.000'),
      netIncomeDifferencePct: 87.5,
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
  required _FakeReportsRepo repo,
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
      reportsRepositoryProvider.overrideWithValue(repo),
      subscriptionSnapshotProvider.overrideWith(
        (ref) async => const SubscriptionSnapshotDto(
          planSlug: 'plus',
          planName: 'Plus',
          status: 'ACTIVE',
          isTrial: false,
          allocationAttentionRequired: false,
          editableBusinessLimit: 3,
          editableBusinessCount: 1,
          totalBusinessCount: 1,
          entitlements: {'reports.level': 'advanced', 'export.per_month': 15},
          usage: {'export.per_month': 2},
        ),
      ),
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
      home: const ReportsScreen(),
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ReportsScreen widget tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets(
        'renders P&L, Cash Flow, and dynamic Comparison period selector + Arabic PDF warning',
        (tester) async {
      final repo = _FakeReportsRepo();
      _setViewport(tester, const Size(390, 844));

      await tester.pumpWidget(_wrap(prefs: prefs, repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Monthly Exports: 2 / 15'), findsOneWidget);
      expect(find.text('SaaS Sales'), findsOneWidget);

      // Switch to Cash Flow
      await tester.tap(find.text('Cash Flow'));
      await tester.pumpAndSettle();
      expect(
        find.text('6-Month Cash Flow Trend (Trailing 6 Months)'),
        findsOneWidget,
      );

      // Switch to Comparison and change Compare Against period
      final compTab = find.text('Comparison');
      await tester.ensureVisible(compTab);
      await tester.pumpAndSettle();
      await tester.tap(compTab);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last Month').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('This Quarter').last);
      await tester.pumpAndSettle();

      expect(repo.comparisonCalls.last, ('this_month', 'this_quarter'));
      expect(tester.takeException(), isNull);

      // Arabic RTL Dark tablet renders PDF warning cleanly without overflow
      _setViewport(tester, const Size(1024, 768));
      await tester.pumpWidget(
        _wrap(
          prefs: prefs,
          repo: repo,
          locale: const Locale('ar'),
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('UTF-8 BOM'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows inline Upgrade Card on PlanLimitReachedFailure',
        (tester) async {
      final repo = _FakeReportsRepo()..gateComparison = true;
      _setViewport(tester, const Size(390, 844));

      await tester.pumpWidget(_wrap(prefs: prefs, repo: repo));
      await tester.pumpAndSettle();

      final compTab = find.text('Comparison');
      await tester.ensureVisible(compTab);
      await tester.pumpAndSettle();
      await tester.tap(compTab);
      await tester.pumpAndSettle();

      expect(find.text('Advanced Report Requires Upgrade'), findsOneWidget);
      expect(find.text('Upgrade Plan Now'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

import 'package:afab_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/core/theme/appearance_settings.dart';
import 'package:afab_mobile/core/theme/appearance_theme_builder.dart';
import 'package:afab_mobile/features/auth/data/auth_dtos.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/auth/domain/session_state.dart';
import 'package:afab_mobile/features/budgets/data/budget_dtos.dart';
import 'package:afab_mobile/features/budgets/data/budgets_repository.dart';
import 'package:afab_mobile/features/budgets/domain/budgets_providers.dart';
import 'package:afab_mobile/features/budgets/presentation/budgets_screen.dart';
import 'package:afab_mobile/features/budgets/presentation/widgets/create_edit_budget_sheet.dart';
import 'package:afab_mobile/features/business/data/business_dto.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/categories/data/category_dto.dart';
import 'package:afab_mobile/features/categories/domain/category_providers.dart';
import 'package:afab_mobile/features/recurring/data/recurring_dtos.dart';
import 'package:afab_mobile/features/recurring/data/recurring_repository.dart';
import 'package:afab_mobile/features/recurring/domain/recurring_providers.dart';
import 'package:afab_mobile/features/recurring/presentation/recurring_transactions_screen.dart';
import 'package:afab_mobile/features/recurring/presentation/widgets/create_edit_recurring_sheet.dart';
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

class _CategoryStub extends CategoryListNotifier {
  @override
  Future<List<CategoryDto>> build() async => const [
        CategoryDto(
          id: 'cat-exp-1',
          businessId: 'biz-1',
          name: 'Cloud Hosting',
          type: 'EXPENSE',
          systemDefault: false,
        ),
        CategoryDto(
          id: 'cat-inc-1',
          businessId: 'biz-1',
          name: 'SaaS Retainers',
          type: 'INCOME',
          systemDefault: false,
        ),
      ];
}

class _FakeBudgetsRepo extends BudgetsRepository {
  _FakeBudgetsRepo() : super(Dio());

  int archiveCalls = 0;

  @override
  Future<void> archiveBudget(String id) async {
    archiveCalls++;
  }
}

class _FakeRecurringRepo extends RecurringRepository {
  _FakeRecurringRepo() : super(Dio());

  int runDueCalls = 0;
  int deleteCalls = 0;

  @override
  Future<RecurringRunResultDto> runDue(String id) async {
    runDueCalls++;
    return RecurringRunResultDto(
      generatedCount: 1,
      transactionIds: const ['tx-gen-1'],
      rule: RecurringTransactionDto(
        id: id,
        businessId: 'biz-1',
        type: 'EXPENSE',
        description: 'AWS Hosting',
        amount: Decimal.parse('300.000'),
        currency: 'TND',
        paymentMethod: 'CARD',
        frequency: 'MONTHLY',
        startDate: '2026-10-01',
        nextExecutionDate: '2026-12-01',
        active: true,
      ),
    );
  }

  @override
  Future<void> deleteRule(String id) async {
    deleteCalls++;
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
  required _FakeBudgetsRepo budgetsRepo,
  required _FakeRecurringRepo recurringRepo,
  required Widget child,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
}) {
  const settings = AppearanceSettings();
  final sampleBudget = BudgetDto(
    id: 'b-1',
    businessId: 'biz-1',
    name: 'Cloud Spend Cap',
    budgetAmount: Decimal.parse('1000.000'),
    currency: 'TND',
    categoryId: 'cat-exp-1',
    categoryName: 'Cloud Hosting',
    categoryColor: '#10B981',
    periodType: 'MONTHLY',
    startDate: '2026-11-01',
    endDate: '2026-11-30',
    alertThresholdPercent: 80,
    status: 'ACTIVE',
    actualSpending: Decimal.parse('1100.000'),
    remainingAmount: Decimal.zero,
    overBudgetAmount: Decimal.parse('100.000'),
    percentageConsumed: Decimal.parse('110.0'),
    alertLevel: 'OVER_BUDGET',
  );

  final activeRule = RecurringTransactionDto(
    id: 'rec-active',
    businessId: 'biz-1',
    type: 'EXPENSE',
    description: 'AWS Hosting',
    amount: Decimal.parse('300.000'),
    currency: 'TND',
    categoryId: 'cat-exp-1',
    categoryName: 'Cloud Hosting',
    paymentMethod: 'CARD',
    frequency: 'MONTHLY',
    startDate: '2026-10-01',
    nextExecutionDate: '2026-11-26',
    active: true,
    lastExecutedAt: DateTime.utc(2026, 11, 1),
  );
  final pausedRule = RecurringTransactionDto(
    id: 'rec-paused',
    businessId: 'biz-1',
    type: 'INCOME',
    description: 'Paused Retainer',
    amount: Decimal.parse('1200.000'),
    currency: 'TND',
    categoryId: 'cat-inc-1',
    categoryName: 'SaaS Retainers',
    paymentMethod: 'BANK_TRANSFER',
    frequency: 'MONTHLY',
    startDate: '2026-10-01',
    nextExecutionDate: '2026-12-01',
    active: false,
  );

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authNotifierProvider.overrideWith(_AuthStub.new),
      categoryListProvider.overrideWith(_CategoryStub.new),
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
      budgetsRepositoryProvider.overrideWithValue(budgetsRepo),
      budgetOverviewSummaryProvider.overrideWith(
        (ref) async => BudgetOverviewSummaryDto(
          currency: 'TND',
          activeBudgetCount: 1,
          approachingCount: 0,
          overBudgetCount: 1,
          totalBudgeted: Decimal.parse('1000.000'),
          totalSpent: Decimal.parse('1100.000'),
          totalRemaining: Decimal.zero,
          budgets: [sampleBudget],
        ),
      ),
      budgetListProvider.overrideWith((ref) async => [sampleBudget]),
      recurringRepositoryProvider.overrideWithValue(recurringRepo),
      recurringListProvider.overrideWith((ref) async => [activeRule, pausedRule]),
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

  group('Budgets & Recurring screens widget tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets(
        'BudgetsScreen requires archive confirmation dialog and renders Dark AR tablet cleanly',
        (tester) async {
      final bRepo = _FakeBudgetsRepo();
      final rRepo = _FakeRecurringRepo();
      _setViewport(tester, const Size(390, 844));

      await tester.pumpWidget(
        _wrap(
          prefs: prefs,
          budgetsRepo: bRepo,
          recurringRepo: rRepo,
          child: const BudgetsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cloud Spend Cap'), findsOneWidget);
      await tester.tap(find.byTooltip('Archive'));
      await tester.pumpAndSettle();

      expect(find.text('Archive budget?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(bRepo.archiveCalls, 0);

      await tester.tap(find.byTooltip('Archive'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive'));
      await tester.pumpAndSettle();
      expect(bRepo.archiveCalls, 1);

      _setViewport(tester, const Size(1024, 768));
      await tester.pumpWidget(
        _wrap(
          prefs: prefs,
          budgetsRepo: bRepo,
          recurringRepo: rRepo,
          locale: const Locale('ar'),
          brightness: Brightness.dark,
          child: const BudgetsScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'CreateEditBudgetSheet requires CUSTOM start & end dates before submit',
        (tester) async {
      final bRepo = _FakeBudgetsRepo();
      final rRepo = _FakeRecurringRepo();
      _setViewport(tester, const Size(390, 844));

      await tester.pumpWidget(
        _wrap(
          prefs: prefs,
          budgetsRepo: bRepo,
          recurringRepo: rRepo,
          child: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showCreateEditBudgetSheet(ctx),
                child: const Text('New Budget Sheet'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('New Budget Sheet'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Q4 Promo');
      await tester.enterText(fields.at(1), '500');

      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom').last);
      await tester.pumpAndSettle();

      final saveBtn = find.text('Save');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(
        find.text('Start date and end date are required for custom budgets.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'RecurringTransactionsScreen disables Run Due on paused rule & confirms Deactivate-vs-Delete',
        (tester) async {
      final bRepo = _FakeBudgetsRepo();
      final rRepo = _FakeRecurringRepo();
      _setViewport(tester, const Size(390, 844));

      await tester.pumpWidget(
        _wrap(
          prefs: prefs,
          budgetsRepo: bRepo,
          recurringRepo: rRepo,
          child: const RecurringTransactionsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AWS Hosting'), findsOneWidget);
      expect(find.text('Paused Retainer'), findsOneWidget);

      await tester.tap(find.byTooltip('Delete').first);
      await tester.pumpAndSettle();
      expect(find.text('Delete or deactivate schedule?'), findsOneWidget);
      expect(find.textContaining('deactivated (paused)'), findsOneWidget);
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(rRepo.deleteCalls, 1);

      expect(tester.takeException(), isNull);
    });

    testWidgets('CreateEditRecurringSheet clears categoryId when type flips',
        (tester) async {
      final bRepo = _FakeBudgetsRepo();
      final rRepo = _FakeRecurringRepo();
      _setViewport(tester, const Size(390, 844));

      final rule = RecurringTransactionDto(
        id: 'rec-1',
        businessId: 'biz-1',
        type: 'EXPENSE',
        description: 'AWS Hosting',
        amount: Decimal.parse('300'),
        currency: 'TND',
        categoryId: 'cat-exp-1',
        categoryName: 'Cloud Hosting',
        paymentMethod: 'CARD',
        frequency: 'MONTHLY',
        startDate: '2026-10-01',
        nextExecutionDate: '2026-12-01',
        active: true,
      );

      await tester.pumpWidget(
        _wrap(
          prefs: prefs,
          budgetsRepo: bRepo,
          recurringRepo: rRepo,
          child: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () =>
                    showCreateEditRecurringSheet(ctx, editingRule: rule),
                child: const Text('Edit Recurring Sheet'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Recurring Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Cloud Hosting'), findsOneWidget);
      await tester.tap(find.text('Expense'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Income').last);
      await tester.pumpAndSettle();

      expect(find.text('Cloud Hosting'), findsNothing);
      expect(find.text('Uncategorized'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

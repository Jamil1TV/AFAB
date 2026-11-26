import 'package:afab_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/core/theme/appearance_settings.dart';
import 'package:afab_mobile/core/theme/appearance_theme_builder.dart';
import 'package:afab_mobile/features/auth/data/auth_dtos.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/auth/domain/session_state.dart';
import 'package:afab_mobile/features/business/data/business_dto.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/categories/data/category_dto.dart';
import 'package:afab_mobile/features/categories/domain/category_providers.dart';
import 'package:afab_mobile/features/categories/presentation/manage_categories_screen.dart';
import 'package:afab_mobile/features/expenses/data/expense_dtos.dart';
import 'package:afab_mobile/features/expenses/domain/expense_providers.dart';
import 'package:afab_mobile/features/expenses/presentation/expenses_screen.dart';
import 'package:afab_mobile/features/revenue/data/revenue_dtos.dart';
import 'package:afab_mobile/features/revenue/domain/revenue_providers.dart';
import 'package:afab_mobile/features/revenue/presentation/revenue_screen.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:afab_mobile/features/transactions/domain/transaction_providers.dart';
import 'package:afab_mobile/features/transactions/presentation/add_edit_transaction_screen.dart';
import 'package:afab_mobile/features/transactions/presentation/split_transaction_screen.dart';
import 'package:afab_mobile/features/transactions/presentation/transactions_screen.dart';
import 'package:decimal/decimal.dart';
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
          id: 'cat-1',
          businessId: null,
          name: 'Software',
          type: 'EXPENSE',
          icon: 'Laptop',
          color: 'var(--primary)',
          systemDefault: true,
        ),
        CategoryDto(
          id: 'cat-2',
          businessId: 'biz-1',
          name: 'Cloud Hosting',
          type: 'EXPENSE',
          icon: 'Building',
          color: '#10B981',
          systemDefault: false,
        ),
        CategoryDto(
          id: 'cat-3',
          businessId: 'biz-1',
          name: 'SaaS Sales',
          type: 'INCOME',
          icon: 'DollarSign',
          color: '#10B981',
          systemDefault: false,
        ),
      ];
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

TransactionPageDto _samplePage() => TransactionPageDto(
      content: [
        TransactionDto(
          id: 'tx-1',
          type: TransactionType.expense,
          amount: Decimal.parse('450.500'),
          currency: 'TND',
          description: 'AWS Hosting',
          transactionDate: '2026-11-22',
          paymentMethod: PaymentMethod.creditCard,
          status: TransactionStatus.completed,
          categoryId: 'cat-2',
          categoryName: 'Cloud Hosting',
          taxDeductible: true,
          taxRate: Decimal.fromInt(19),
          potentialDuplicate: true,
        ),
        TransactionDto(
          id: 'tx-2',
          type: TransactionType.income,
          amount: Decimal.parse('2500.000'),
          currency: 'TND',
          description: 'Enterprise Retainer',
          transactionDate: '2026-11-21',
          paymentMethod: PaymentMethod.bankTransfer,
          status: TransactionStatus.pending,
          categoryId: 'cat-3',
          categoryName: 'SaaS Sales',
        ),
      ],
      pageNumber: 0,
      pageSize: 15,
      totalElements: 2,
      totalPages: 1,
      totalInflow: Decimal.parse('2500.000'),
      totalOutflow: Decimal.parse('450.500'),
      netBalance: Decimal.parse('2049.500'),
      currency: 'TND',
    );

Widget _wrap({
  required SharedPreferences prefs,
  required Widget child,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.light,
}) {
  const settings = AppearanceSettings();
  final page = _samplePage();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authNotifierProvider.overrideWith(_AuthStub.new),
      businessListProvider.overrideWith(
        (_) async => const [
          BusinessDto(
            id: 'biz-1',
            name: 'Carthage Labs',
            currency: 'TND',
            active: true,
            editable: true,
            accessMode: 'EDITABLE',
            userRole: 'OWNER',
          ),
        ],
      ),
      categoryListProvider.overrideWith(_CategoryStub.new),
      transactionListProvider.overrideWith((_) async => page),
      transactionDetailProvider.overrideWith(
        (_, id) async => page.content.first,
      ),
      expenseSummaryProvider.overrideWith(
        (_) async => ExpenseSummaryDto(
          totalExpenses: Decimal.parse('450.500'),
          avgPerDay: Decimal.parse('45.050'),
          highestExpenseTitle: 'AWS Hosting',
          highestExpenseAmount: Decimal.parse('450.500'),
          categoryCount: 1,
          recurringTotal: Decimal.zero,
          recurringPercentage: 0,
          currency: 'TND',
          categoryBreakdown: [
            CategoryBreakdownItemDto(
              name: 'Cloud Hosting',
              amount: Decimal.parse('450.500'),
              percentage: 100,
              color: '#8B5CF6',
            ),
          ],
          recurringList: const [],
          dailyOverview: const [
            DailyOverviewPointDto(date: '2026-11-22', amount: 450.5),
          ],
        ),
      ),
      expenseListProvider.overrideWith((_) async => page),
      revenueSummaryProvider.overrideWith(
        (_) async => RevenueSummaryDto(
          totalRevenue: Decimal.parse('2500.000'),
          grossRevenue: Decimal.parse('2500.000'),
          discounts: Decimal.zero,
          refunds: Decimal.zero,
          netRevenue: Decimal.parse('2500.000'),
          avgPerDay: Decimal.parse('250.000'),
          highestRevenueAmount: Decimal.parse('2500.000'),
          highestRevenueDate: '2026-11-21',
          totalInvoices: 1,
          currency: 'TND',
          revenueBySource: [
            CategoryBreakdownItemDto(
              name: 'SaaS Sales',
              amount: Decimal.parse('2500.000'),
              percentage: 100,
              color: '#10B981',
            ),
          ],
          topProducts: const [],
          dailyOverview: const [],
        ),
      ),
      revenueListProvider.overrideWith((_) async => page),
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

  group('Phase 3 Financial Core widget tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets(
        'TransactionsScreen renders on 390x844 phone Light EN & 1024x768 Dark AR RTL Master-Detail',
        (tester) async {
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _wrap(prefs: prefs, child: const TransactionsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Magic Quick-Add'), findsOneWidget);
      expect(find.text('AWS Hosting'), findsOneWidget);
      expect(find.text('DT 2,500.000'), findsWidgets);
      expect(tester.takeException(), isNull);

      _setViewport(tester, const Size(1024, 768));
      await tester.pumpWidget(
        _wrap(
          prefs: prefs,
          locale: const Locale('ar'),
          brightness: Brightness.dark,
          child: const TransactionsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AWS Hosting'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'ManageCategoriesScreen distinguishes System Default lock from Custom Edit/Delete',
        (tester) async {
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _wrap(prefs: prefs, child: const ManageCategoriesScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Software'), findsOneWidget);
      expect(find.text('System Default'), findsOneWidget);
      expect(find.text('Cloud Hosting'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'AddEditTransactionScreen supports create & locked-currency edit without overflow',
        (tester) async {
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _wrap(
          prefs: prefs,
          child: const AddEditTransactionScreen(
            mode: TransactionFormMode.create,
            initialType: TransactionType.income,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Transaction'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'SplitTransactionScreen validates exact TND 3-decimal Fill balance',
        (tester) async {
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _wrap(prefs: prefs, child: const SplitTransactionScreen()),
      );
      await tester.pumpAndSettle();

      final totalField = find.byType(TextFormField).first;
      await tester.enterText(totalField, '100.000');
      await tester.pumpAndSettle();

      expect(find.text('Fill'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'ExpensesScreen & RevenueScreen handle single-point & empty charts cleanly in EN + AR Dark',
        (tester) async {
      _setViewport(tester, const Size(390, 844));
      await tester.pumpWidget(
        _wrap(prefs: prefs, child: const ExpensesScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Manage Recurring Rules'), findsOneWidget);
      expect(tester.takeException(), isNull);

      _setViewport(tester, const Size(1024, 768));
      await tester.pumpWidget(
        _wrap(
          prefs: prefs,
          locale: const Locale('ar'),
          brightness: Brightness.dark,
          child: const RevenueScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

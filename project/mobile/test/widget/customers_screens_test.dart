import 'package:afab_mobile/core/l10n/generated/app_localizations.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/core/theme/appearance_settings.dart';
import 'package:afab_mobile/core/theme/appearance_theme_builder.dart';
import 'package:afab_mobile/features/auth/data/auth_dtos.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/auth/domain/session_state.dart';
import 'package:afab_mobile/features/business/data/business_dto.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/customers/data/customer_dtos.dart';
import 'package:afab_mobile/features/customers/data/customers_repository.dart';
import 'package:afab_mobile/features/customers/domain/customers_providers.dart';
import 'package:afab_mobile/features/customers/presentation/customer_details_screen.dart';
import 'package:afab_mobile/features/customers/presentation/customers_screen.dart';
import 'package:afab_mobile/features/customers/presentation/widgets/add_edit_customer_sheet.dart';
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

class _FakeCustomersRepo extends CustomersRepository {
  _FakeCustomersRepo() : super(Dio());

  int getByIdCalls = 0;
  CustomerMutationRequest? lastCreated;

  final _c1 = CustomerDto(
    id: 'cust-1',
    customerCode: 'CUST-0001',
    businessId: 'biz-1',
    name: 'Amine Ben Salem',
    companyName: 'Carthage Tech',
    email: 'amine@carthage.tn',
    phone: '+216 71 000 111',
    group: 'VIP',
    status: 'Active',
    totalRevenue: Decimal.parse('1200.000'),
    invoicedAmount: Decimal.parse('1500.000'),
    outstandingBalance: Decimal.parse('300.000'),
    ordersCount: 2,
    orders: [
      CustomerInvoiceLinkDto(
        id: 'inv-1',
        orderNumber: 'INV-2026-0001',
        customerId: 'cust-1',
        amount: Decimal.parse('1200.000'),
        status: 'SENT',
        orderDate: '2026-11-20',
        description: 'Mobile Advisory',
        paymentMethod: null,
        invoiceNumber: 'INV-2026-0001',
      ),
    ],
  );

  @override
  Future<CustomerDto> getCustomerById(String id) async {
    getByIdCalls++;
    return _c1;
  }

  @override
  Future<CustomerDto> createCustomer(CustomerMutationRequest request) async {
    lastCreated = request;
    return _c1;
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
  required _FakeCustomersRepo repo,
  required Widget child,
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
      customersRepositoryProvider.overrideWithValue(repo),
      customerSummaryProvider.overrideWith(
        (ref) async => CustomerSummaryDto(
          totalCustomers: 12,
          totalCustomersChangePct: 10.0,
          newCustomers: 3,
          newCustomersChangePct: 5.0,
          totalRevenue: Decimal.parse('24500.000'),
          totalRevenueChangePct: 15.2,
          avgRevenuePerCustomer: Decimal.parse('2041.667'),
          avgRevenueChangePct: 4.1,
          repeatCustomersPct: 50.0,
          repeatCustomersChangePct: 2.0,
          currency: 'TND',
          overviewDonut: const CustomerOverviewDonutDto(
            activeCount: 8,
            activePct: 67,
            inactiveCount: 1,
            inactivePct: 8,
            newCount: 3,
            newPct: 25,
          ),
          topCustomers: [
            CustomerTopItemDto(
              id: 'cust-1',
              customerCode: 'CUST-0001',
              name: 'Amine Ben Salem',
              revenue: Decimal.parse('1200.000'),
              ordersCount: 2,
            ),
          ],
          recentActivity: const [],
        ),
      ),
      customersListProvider.overrideWith(
        (ref) async => CustomerPageDto(
          content: [repo._c1],
          totalElements: 1,
          totalPages: 1,
          pageNumber: 0,
          pageSize: 15,
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
      home: child,
    ),
  );
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Customers screens widget tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets(
        'CustomersScreen renders cleanly on phone Light EN and tablet Dark AR RTL without bulk checkboxes',
        (tester) async {
      final repo = _FakeCustomersRepo();
      _setViewport(tester, const Size(390, 844));

      await tester.pumpWidget(
        _wrap(prefs: prefs, repo: repo, child: const CustomersScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Amine Ben Salem'), findsAtLeastNWidgets(1));
      expect(find.byType(Checkbox), findsNothing);
      expect(tester.takeException(), isNull);

      _setViewport(tester, const Size(1024, 768));
      await tester.pumpWidget(
        _wrap(
          prefs: prefs,
          repo: repo,
          locale: const Locale('ar'),
          brightness: Brightness.dark,
          child: const CustomersScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'CustomerDetailsScreen fetches GET /{id}, shows Sent status, and omits null paymentMethod',
        (tester) async {
      final repo = _FakeCustomersRepo();
      _setViewport(tester, const Size(390, 844));

      await tester.pumpWidget(
        _wrap(
          prefs: prefs,
          repo: repo,
          child: const CustomerDetailsScreen(customerId: 'cust-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(repo.getByIdCalls, 1);
      expect(find.text('Carthage Tech'), findsOneWidget);
      expect(find.text('Sent'), findsOneWidget);
      // Must NOT fake 'Bank Transfer' when paymentMethod is null.
      expect(find.textContaining('Bank Transfer'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AddEditCustomerSheet exposes companyName and submits payload',
        (tester) async {
      final repo = _FakeCustomersRepo();
      _setViewport(tester, const Size(390, 844));

      await tester.pumpWidget(
        _wrap(
          prefs: prefs,
          repo: repo,
          child: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showAddEditCustomerSheet(ctx),
                child: const Text('Open Customer Sheet'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Customer Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Company Name'), findsOneWidget);
      final inputs = find.byType(TextFormField);
      await tester.enterText(inputs.at(0), 'Leila Mansour');
      await tester.enterText(inputs.at(1), 'Tunis Digital');

      final saveBtn = find.text('Save');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(repo.lastCreated?.name, 'Leila Mansour');
      expect(repo.lastCreated?.companyName, 'Tunis Digital');
      expect(tester.takeException(), isNull);
    });
  });
}

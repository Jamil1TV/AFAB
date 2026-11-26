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
import 'package:afab_mobile/features/invoices/data/invoice_dtos.dart';
import 'package:afab_mobile/features/invoices/data/invoices_repository.dart';
import 'package:afab_mobile/features/invoices/domain/invoices_providers.dart';
import 'package:afab_mobile/features/invoices/presentation/create_edit_invoice_screen.dart';
import 'package:afab_mobile/features/invoices/presentation/invoice_details_screen.dart';
import 'package:afab_mobile/features/invoices/presentation/invoices_screen.dart';
import 'package:afab_mobile/features/invoices/presentation/widgets/record_payment_sheet.dart';
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

class _FakeInvoicesRepo extends InvoicesRepository {
  _FakeInvoicesRepo() : super(Dio());

  bool failNextPayment = false;
  final List<String> sentIdempotencyKeys = [];

  final draftInv = InvoiceDto.fromJson({
    'id': 'inv-draft-1',
    'businessId': 'biz-1',
    'invoiceNumber': 'INV-2026-0041',
    'customerId': 'cust-1',
    'customerName': 'Carthage Tech',
    'status': 'DRAFT',
    'storedStatus': 'DRAFT',
    'overdue': false,
    'issueDate': '2026-11-20',
    'dueDate': '2026-12-20',
    'currency': 'TND',
    'subtotal': '500.000',
    'discountAmount': '0.000',
    'taxAmount': '95.000',
    'totalAmount': '595.000',
    'paidAmount': '0.000',
    'outstandingBalance': '595.000',
    'items': [
      {
        'id': 'it-1',
        'description': 'Flutter Consulting',
        'quantity': '1',
        'unitPrice': '500.000',
        'taxRate': '19',
        'lineSubtotal': '500.000',
        'lineTax': '95.000',
        'lineTotal': '595.000',
      },
    ],
  });

  final crossCurrencyInv = InvoiceDto.fromJson({
    'id': 'inv-eur-1',
    'businessId': 'biz-1',
    'invoiceNumber': 'INV-2026-0042',
    'customerId': 'cust-1',
    'customerName': 'Paris Client',
    'status': 'SENT',
    'storedStatus': 'SENT',
    'overdue': false,
    'issueDate': '2026-11-15',
    'dueDate': '2026-12-15',
    'currency': 'EUR',
    'subtotal': '1000.00',
    'discountAmount': '0.00',
    'taxAmount': '0.00',
    'totalAmount': '1000.00',
    'paidAmount': '0.00',
    'outstandingBalance': '1000.00',
    'items': [
      {
        'id': 'it-2',
        'description': 'EU Advisory',
        'quantity': '1',
        'unitPrice': '1000.00',
        'taxRate': '0',
        'lineSubtotal': '1000.00',
        'lineTax': '0.00',
        'lineTotal': '1000.00',
      },
    ],
  });

  @override
  Future<InvoiceDto> getInvoiceById(String id) async =>
      id == crossCurrencyInv.id ? crossCurrencyInv : draftInv;

  @override
  Future<PaymentDto> recordPayment(
    String invoiceId,
    RecordPaymentRequestDto request,
  ) async {
    sentIdempotencyKeys.add(request.idempotencyKey);
    if (failNextPayment) {
      failNextPayment = false;
      throw const NetworkFailure(message: 'Simulated timeout');
    }
    return PaymentDto(
      id: 'pay-1',
      invoiceId: invoiceId,
      amount: request.amount,
      currency: request.currency,
      paymentDate: request.paymentDate,
      paymentMethod: request.paymentMethod,
      idempotencyKey: request.idempotencyKey,
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
  required _FakeInvoicesRepo repo,
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
      invoicesRepositoryProvider.overrideWithValue(repo),
      invoiceSummaryProvider.overrideWith(
        (ref) async => InvoiceSummaryDto(
          totalInvoices: 2,
          paidInvoices: 0,
          pendingInvoices: 2,
          overdueInvoices: 0,
          totalInvoiceAmount: Decimal.parse('1595.000'),
          paidAmount: Decimal.zero,
          pendingAmount: Decimal.parse('1595.000'),
          overdueAmount: Decimal.zero,
          currency: 'TND',
          statusBreakdown: [
            InvoiceStatusBreakdownItemDto(
              name: 'Sent',
              amount: Decimal.parse('1000.000'),
              percentage: 62.7,
              color: '#3B82F6',
            ),
          ],
          upcomingDueList: [
            UpcomingInvoiceItemDto(
              invoiceId: 'INV-2026-0042',
              customerName: 'Paris Client',
              dueDate: '2026-12-15',
              amount: Decimal.parse('1000.000'),
            ),
          ],
        ),
      ),
      invoicesListProvider.overrideWith(
        (ref) async => InvoicePageDto(
          content: [repo.draftInv, repo.crossCurrencyInv],
          pageNumber: 0,
          pageSize: 15,
          totalElements: 2,
          totalPages: 1,
          totalInvoiced: Decimal.parse('1595.000'),
          totalPaid: Decimal.zero,
          totalOutstanding: Decimal.parse('1595.000'),
          currency: 'TND',
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

  group('Invoices module widget tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets(
        'InvoicesScreen includes Sent filter chip & renders cleanly on phone + Dark AR tablet',
        (tester) async {
      final repo = _FakeInvoicesRepo();
      _setViewport(tester, const Size(390, 844));

      await tester.pumpWidget(
        _wrap(prefs: prefs, repo: repo, child: const InvoicesScreen()),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('INV-2026-0041'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Sent'), findsAtLeastNWidgets(1));
      expect(find.text('INV-2026-0041'), findsOneWidget);
      expect(tester.takeException(), isNull);

      _setViewport(tester, const Size(1024, 768));
      await tester.pumpWidget(
        _wrap(
          prefs: prefs,
          repo: repo,
          locale: const Locale('ar'),
          brightness: Brightness.dark,
          child: const InvoicesScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('InvoiceDetailsScreen exposes both Mark as Sent and Issue as Unpaid on DRAFT',
        (tester) async {
      final repo = _FakeInvoicesRepo();
      _setViewport(tester, const Size(390, 844));

      await tester.pumpWidget(
        _wrap(
          prefs: prefs,
          repo: repo,
          child: const InvoiceDetailsScreen(invoiceId: 'inv-draft-1'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mark as Sent'), findsOneWidget);
      expect(find.text('Issue as Unpaid'), findsOneWidget);
      expect(find.text('Export PDF'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'CreateEditInvoiceScreen calculates live Decimal totals and shows dirty discard dialog',
        (tester) async {
      final repo = _FakeInvoicesRepo();
      _setViewport(tester, const Size(390, 844));

      await tester.pumpWidget(
        _wrap(
          prefs: prefs,
          repo: repo,
          child: const CreateEditInvoiceScreen(mode: InvoiceFormMode.create),
        ),
      );
      await tester.pumpAndSettle();

      final priceField = find.widgetWithText(TextFormField, '0.00');
      await tester.enterText(priceField, '100.000');
      await tester.pumpAndSettle();

      expect(find.textContaining('100.000'), findsAtLeastNWidgets(1));

      await tester.tap(find.byIcon(LucideIcons.x).first);
      await tester.pumpAndSettle();
      expect(find.text('Discard unsaved changes?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'RecordPaymentSheet shows 1:1 notice, conditional FX rate, and reuses single Idempotency-Key across retry',
        (tester) async {
      final repo = _FakeInvoicesRepo()..failNextPayment = true;
      _setViewport(tester, const Size(390, 844));

      await tester.pumpWidget(
        _wrap(
          prefs: prefs,
          repo: repo,
          child: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () =>
                    showRecordPaymentSheet(ctx, invoice: repo.crossCurrencyInv),
                child: const Text('Pay Cross Currency'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pay Cross Currency'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('1:1 COMPLETED Income transaction'),
        findsOneWidget,
      );
      expect(find.textContaining('Exchange Rate (1 EUR = ? TND)'), findsOneWidget);

      await tester.tap(find.text('50%'));
      await tester.pumpAndSettle();

      final confirmBtn = find.text('Confirm Payment');
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // First attempt fails -> retry CTA appears and keeps the exact same UUID key!
      final retryBtn = find.text('Retry Same Payment');
      expect(retryBtn, findsOneWidget);
      await tester.ensureVisible(retryBtn);
      await tester.tap(retryBtn);
      await tester.pumpAndSettle();

      expect(repo.sentIdempotencyKeys.length, 2);
      expect(repo.sentIdempotencyKeys[0], repo.sentIdempotencyKeys[1]);
      expect(tester.takeException(), isNull);
    });
  });
}

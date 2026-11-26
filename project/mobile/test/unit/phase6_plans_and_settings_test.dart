import 'dart:typed_data';

import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:afab_mobile/features/customers/data/customer_dtos.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/features/invoices/data/invoice_dtos.dart';
import 'package:afab_mobile/features/plans/data/plans_dtos.dart';
import 'package:afab_mobile/features/settings/data/export_generators.dart';
import 'package:afab_mobile/features/settings/data/settings_dtos.dart';
import 'package:afab_mobile/features/settings/domain/signature_image_processor.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 6 Plans & Settings DTOs, Processor & Export Generators', () {
    test('SubscriptionSnapshotDto parses full Stripe + trial + pending fields', () {
      final dto = SubscriptionSnapshotDto.fromJson({
        'planId': 'plan-plus',
        'planSlug': 'plus',
        'planName': 'Plus',
        'priceMonthly': 9.99,
        'priceYearly': 7.99,
        'currency': 'EUR',
        'status': 'TRIALING',
        'trial': true,
        'trialDaysRemaining': 5,
        'billingInterval': 'yearly',
        'cancelAtPeriodEnd': false,
        'pendingPlanSlug': 'free',
        'pendingPlanName': 'Free',
        'pendingChangeEffectiveAt': '2026-12-03T00:00:00Z',
        'gracePeriodHoursRemaining': 48,
        'trialUsed': true,
        'trialEligible': false,
        'allocationAttentionRequired': true,
        'editableBusinessLimit': 3,
        'editableBusinessCount': 2,
        'totalBusinessCount': 4,
        'hasStripeCustomer': true,
        'hasActiveStripeSubscription': true,
        'stripeConfigured': true,
        'entitlements': {
          'ai.chat.tokens_per_month': 150000,
          'ai.chat.queries_per_month': 300,
          'reports.level': 'advanced',
          'export.per_month': 50,
        },
        'usage': {
          'ai.chat.tokens_per_month': 4200,
          'ai.chat.queries_per_month': 12,
          'export.per_month': 3,
        },
      });

      expect(dto.isPlus, isTrue);
      expect(dto.isTrialActive, isTrue);
      expect(dto.currency, 'EUR');
      expect(dto.billingInterval, 'yearly');
      expect(dto.hasPendingChange, isTrue);
      expect(dto.pendingPlanSlug, 'free');
      expect(dto.aiTokensLimit, 150000);
      expect(dto.aiTokensUsed, 4200);
      expect(dto.aiQueriesLimit, 300);
      expect(dto.aiQueriesUsed, 12);
      expect(dto.reportsLevel, 'advanced');
      expect(dto.hasStripeCustomer, isTrue);
      expect(dto.hasActiveStripeSubscription, isTrue);
      expect(dto.stripeConfigured, isTrue);
    });

    test('PaymentHistoryItemDto formats JPY 0-dec, USD 2-dec, and TND 3-dec', () {
      final jpy = PaymentHistoryItemDto.fromJson({
        'id': 'p1',
        'amountCents': 1500,
        'currency': 'JPY',
        'status': 'PAID',
      });
      final usd = PaymentHistoryItemDto.fromJson({
        'id': 'p2',
        'amountCents': 1999,
        'currency': 'USD',
        'status': 'PAID',
      });
      final tnd = PaymentHistoryItemDto.fromJson({
        'id': 'p3',
        'amountCents': 19990,
        'currency': 'TND',
        'status': 'FAILED',
      });

      expect(jpy.amountDecimal, Decimal.fromInt(1500));
      expect(
        MoneyFormatter.formatDecimal(jpy.amountDecimal, currency: jpy.currency),
        contains('1,500'),
      );
      expect(usd.amountDecimal, Decimal.parse('19.99'));
      expect(
        MoneyFormatter.formatDecimal(usd.amountDecimal, currency: usd.currency),
        '\$19.99',
      );
      expect(tnd.amountDecimal, Decimal.parse('19.990'));
      expect(
        MoneyFormatter.formatDecimal(tnd.amountDecimal, currency: tnd.currency),
        'DT 19.990',
      );
    });

    test('BusinessAllocationDto, AccountDeletionPreflightDto, SessionDto & TwoFactorSetupDto parse', () {
      final alloc = BusinessAllocationDto.fromJson({
        'currentPlanSlug': 'plus',
        'currentPlanName': 'Plus',
        'editableLimit': 3,
        'editableCount': 2,
        'readOnlyCount': 1,
        'totalOwnedCount': 3,
        'allocationAttentionRequired': false,
        'pendingBusinessIds': ['b1'],
        'businesses': [
          {
            'id': 'b1',
            'name': 'Alpha Co',
            'currency': 'TND',
            'editable': true,
            'primary': true,
            'active': true,
          },
        ],
      });
      expect(alloc.businesses.single.name, 'Alpha Co');
      expect(alloc.pendingBusinessIds, ['b1']);

      final preflight = AccountDeletionPreflightDto.fromJson({
        'canDelete': false,
        'guidance': 'Archive or transfer active owned businesses.',
        'blockingBusinesses': [
          {
            'businessId': 'b1',
            'businessName': 'Alpha Co',
            'activeMemberCount': 2,
            'hasOtherActiveMembers': true,
          },
        ],
      });
      expect(preflight.canDelete, isFalse);
      expect(preflight.blockingBusinesses.single.hasOtherActiveMembers, isTrue);

      final sess = SessionDto.fromJson({
        'id': 's1',
        'deviceInfo': 'Pixel 9 Android',
        'ipAddress': '196.179.10.5',
        'currentSession': false,
      });
      expect(sess.deviceInfo, 'Pixel 9 Android');

      final twoFa = TwoFactorSetupDto.fromJson({
        'secret': 'JBSWY3DPEHPK3PXP',
        'qrCodeUri': 'otpauth://totp/AFAB:user@tn?secret=JBSWY3DPEHPK3PXP',
        'backupCodes': ['AAAA1111', 'BBBB2222'],
      });
      expect(twoFa.backupCodes, hasLength(2));
    });

    test('processSignatureBytes removes white paper background and keeps dark ink', () {
      final canvas = img.Image(width: 4, height: 4, numChannels: 4);
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          if (x == 1 && y == 1) {
            canvas.setPixelRgba(x, y, 25, 25, 30, 255); // ink pixel
          } else {
            canvas.setPixelRgba(x, y, 250, 250, 250, 255); // paper pixel
          }
        }
      }
      final inputPng = Uint8List.fromList(img.encodePng(canvas));
      final outBytes = processSignatureBytes(
        (rawBytes: inputPng, makeTransparent: true),
      );
      expect(outBytes, isNotNull);

      final decoded = img.decodeImage(outBytes!)!;
      expect(decoded.getPixel(0, 0).a.toInt(), 0);
      expect(decoded.getPixel(1, 1).a.toInt(), 255);
    });

    test('ExportGenerators produces valid XLSX and PDF bytes with optional signature', () async {
      final dummySigCanvas = img.Image(width: 10, height: 10, numChannels: 4);
      dummySigCanvas.setPixelRgba(5, 5, 10, 10, 10, 255);
      final sigBytes = Uint8List.fromList(img.encodePng(dummySigCanvas));

      final txs = [
        TransactionDto(
          id: 'tx1',
          type: TransactionType.income,
          amount: Decimal.parse('1500.000'),
          currency: 'TND',
          convertedAmount: Decimal.parse('1500.000'),
          baseCurrency: 'TND',
          description: 'Consulting Retainer',
          transactionDate: '2026-11-20',
          paymentMethod: PaymentMethod.bankTransfer,
          status: TransactionStatus.completed,
        ),
      ];
      final custs = [
        CustomerDto(
          id: 'c1',
          customerCode: 'CUST-001',
          businessId: 'b1',
          name: 'Amira Ben Ali',
          group: 'STANDARD',
          status: 'ACTIVE',
          totalRevenue: Decimal.parse('1000.000'),
          invoicedAmount: Decimal.parse('1500.000'),
          outstandingBalance: Decimal.parse('500.000'),
          ordersCount: 2,
        ),
      ];
      final invs = [
        InvoiceDto(
          id: 'inv1',
          businessId: 'b1',
          invoiceNumber: 'INV-2026-01',
          issueDate: '2026-11-01',
          dueDate: '2026-12-01',
          status: InvoiceStatus.sent,
          storedStatus: InvoiceStatus.sent,
          overdue: false,
          currency: 'TND',
          subtotal: Decimal.parse('1500.000'),
          discountAmount: Decimal.zero,
          taxAmount: Decimal.zero,
          totalAmount: Decimal.parse('1500.000'),
          paidAmount: Decimal.parse('1000.000'),
          outstandingBalance: Decimal.parse('500.000'),
        ),
      ];

      final xlsx = ExportGenerators.buildExcelBytes(
        kind: ExportDatasetKind.master,
        businessName: 'Carthage Labs',
        displayCurrency: 'TND',
        branding: const ExportBrandingOverrides(
          fiscalMatricule: '1234567/A/M/000',
        ),
        transactions: txs,
        customers: custs,
        invoices: invs,
        periodNetFlow: Decimal.parse('1500.000'),
      );
      // XLSX zip archive starts with "PK"
      expect(xlsx.length, greaterThan(100));
      expect(xlsx[0], 0x50);
      expect(xlsx[1], 0x4B);

      final pdfBytes = await ExportGenerators.buildPdfBytes(
        kind: ExportDatasetKind.master,
        locale: 'en',
        businessName: 'Carthage Labs',
        periodLabel: 'this_month',
        displayCurrency: 'TND',
        branding: const ExportBrandingOverrides(
          fiscalMatricule: '1234567/A/M/000',
          includeSignature: true,
        ),
        transactions: txs,
        customers: custs,
        invoices: invs,
        periodNetFlow: Decimal.parse('1500.000'),
        signaturePngBytes: sigBytes,
        signatoryName: 'Youssef Trabelsi',
        signatoryTitle: 'Managing Director',
      );
      expect(String.fromCharCodes(pdfBytes.take(5)), '%PDF-');
    });
  });
}

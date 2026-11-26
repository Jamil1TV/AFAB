import 'dart:convert';

import 'package:afab_mobile/features/budgets/data/budget_dtos.dart';
import 'package:afab_mobile/features/customers/data/customer_dtos.dart';
import 'package:afab_mobile/features/invoices/data/invoice_dtos.dart';
import 'package:afab_mobile/features/invoices/data/invoice_pdf_generator.dart';
import 'package:afab_mobile/features/invoices/domain/invoice_calculator.dart';
import 'package:afab_mobile/features/recurring/data/recurring_dtos.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Business Operations DTOs, Decimal Calculator & PDF', () {
    test('CustomerDto & CustomerSummaryDto parse financial fields accurately', () {
      final dto = CustomerDto.fromJson({
        'id': 'cust-1',
        'customerCode': 'CUST-0042',
        'businessId': 'biz-1',
        'name': 'Amine Ben Salem',
        'companyName': 'Carthage Tech',
        'email': 'amine@carthage.tn',
        'phone': '+216 71 000 111',
        'group': 'VIP',
        'status': 'Active',
        'totalRevenue': '12450.500',
        'invoicedAmount': '15000.000',
        'outstandingBalance': '2549.500',
        'ordersCount': 4,
        'orders': [
          {
            'id': 'inv-1',
            'orderNumber': 'INV-2026-0009',
            'customerId': 'cust-1',
            'amount': '2549.500',
            'status': 'PARTIALLY_PAID',
            'orderDate': '2026-11-18',
            'description': 'Q4 Consulting',
            'paymentMethod': null,
            'invoiceNumber': 'INV-2026-0009',
          },
        ],
      });

      expect(dto.companyName, 'Carthage Tech');
      expect(dto.totalRevenue, Decimal.parse('12450.500'));
      expect(dto.invoicedAmount, Decimal.parse('15000.000'));
      expect(dto.outstandingBalance, Decimal.parse('2549.500'));
      expect(dto.orders.single.paymentMethod, isNull);
      expect(dto.orders.single.status, 'PARTIALLY_PAID');
    });

    test('InvoiceDto binds subtotal and discountAmount and all 7 statuses', () {
      for (final s in InvoiceStatus.values) {
        expect(InvoiceStatus.fromApi(s.apiValue), s);
      }

      final inv = InvoiceDto.fromJson({
        'id': 'inv-1',
        'businessId': 'biz-1',
        'invoiceNumber': 'INV-2026-0010',
        'customerId': 'cust-1',
        'customerName': 'Carthage Tech',
        'status': 'SENT',
        'storedStatus': 'SENT',
        'overdue': false,
        'issueDate': '2026-11-01',
        'dueDate': '2026-11-30',
        'currency': 'TND',
        'subtotal': '1000.000',
        'discountAmount': '50.000',
        'taxAmount': '190.000',
        'totalAmount': '1140.000',
        'paidAmount': '0.000',
        'outstandingBalance': '1140.000',
        'items': [
          {
            'id': 'item-1',
            'description': 'Audit Services',
            'quantity': '2',
            'unitPrice': '500.000',
            'taxRate': '19',
            'lineSubtotal': '1000.000',
            'lineTax': '190.000',
            'lineTotal': '1190.000',
          },
        ],
        'payments': const [],
      });

      expect(inv.subtotal, Decimal.parse('1000.000'));
      expect(inv.discountAmount, Decimal.parse('50.000'));
      expect(inv.totalAmount, Decimal.parse('1140.000'));
      expect(inv.status, InvoiceStatus.sent);
      expect(inv.status.isPayable, isTrue);
    });

    test('InvoiceCalculator matches HALF_UP scale 4 Decimal precision', () {
      final totals = InvoiceCalculator.computeTotals(
        items: const [
          InvoiceLineInput(
            description: 'TND Advisory',
            quantity: '1.5',
            unitPrice: '12.345',
            taxRate: '19',
          ),
          InvoiceLineInput(
            description: 'Setup Fee',
            quantity: '1',
            unitPrice: '100,000',
            taxRate: '7',
          ),
        ],
        discountRaw: '10.000',
      );

      // Line 1: 1.5 * 12.345 = 18.5175; tax 19% = 3.518325 -> 3.5183
      expect(totals.lines[0].lineSubtotal, Decimal.parse('18.5175'));
      expect(totals.lines[0].lineTax, Decimal.parse('3.5183'));
      // Line 2: 100.000; tax 7% = 7.0000
      expect(totals.subtotal, Decimal.parse('118.5175'));
      expect(totals.taxAmount, Decimal.parse('10.5183'));
      expect(totals.total, Decimal.parse('119.0358'));
      expect(totals.discountExceedsTotal, isFalse);

      final tooHighDiscount = InvoiceCalculator.computeTotals(
        items: const [
          InvoiceLineInput(
            description: 'Small Item',
            quantity: '1',
            unitPrice: '10',
            taxRate: '0',
          ),
        ],
        discountRaw: '20',
      );
      expect(tooHighDiscount.discountExceedsTotal, isTrue);
      expect(tooHighDiscount.total, Decimal.zero);
    });

    test('InvoicePdfGenerator emits valid %PDF- bytes without throwing', () async {
      final inv = InvoiceDto.fromJson({
        'id': 'inv-pdf-1',
        'businessId': 'biz-1',
        'invoiceNumber': 'INV-2026-0099',
        'customerName': 'Northwind Studio',
        'customerEmail': 'billing@northwind.io',
        'status': 'UNPAID',
        'storedStatus': 'UNPAID',
        'overdue': false,
        'issueDate': '2026-11-10',
        'dueDate': '2026-12-10',
        'currency': 'TND',
        'subtotal': '500.000',
        'discountAmount': '25.000',
        'taxAmount': '95.000',
        'totalAmount': '570.000',
        'paidAmount': '0.000',
        'outstandingBalance': '570.000',
        'notes': 'Pay within 30 days',
        'items': [
          {
            'id': 'it-1',
            'description': 'Monthly Retainer',
            'quantity': '1',
            'unitPrice': '500.000',
            'taxRate': '19',
            'lineSubtotal': '500.000',
            'lineTax': '95.000',
            'lineTotal': '595.000',
          },
        ],
      });

      final bytes = await InvoicePdfGenerator.buildPdfBytes(
        inv,
        businessName: 'Carthage Labs',
      );
      expect(bytes.length, greaterThan(500));
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    });

    test('BudgetDto and BudgetSummaryDto parse fields accurately', () {
      final summary = BudgetOverviewSummaryDto.fromJson({
        'currency': 'TND',
        'activeBudgetCount': 2,
        'approachingCount': 1,
        'overBudgetCount': 1,
        'totalBudgeted': '5000.000',
        'totalSpent': '4600.000',
        'totalRemaining': '400.000',
        'budgets': [
          {
            'id': 'b-1',
            'businessId': 'biz-1',
            'name': 'Cloud Budget',
            'budgetAmount': '1000.000',
            'currency': 'TND',
            'categoryId': 'cat-1',
            'categoryName': 'Cloud Hosting',
            'categoryColor': '#10B981',
            'periodType': 'MONTHLY',
            'startDate': '2026-11-01',
            'endDate': '2026-11-30',
            'alertThresholdPercent': 80,
            'status': 'ACTIVE',
            'actualSpending': '1150.000',
            'remainingAmount': '0.000',
            'overBudgetAmount': '150.000',
            'percentageConsumed': '115.0',
            'alertLevel': 'OVER_BUDGET',
          },
        ],
      });

      expect(summary.budgets.single.overBudgetAmount, Decimal.parse('150.000'));
      expect(summary.budgets.single.alertLevel, 'OVER_BUDGET');
    });

    test('RecurringTransactionDto & RunResult parse all fields', () {
      final run = RecurringRunResultDto.fromJson({
        'generatedCount': 2,
        'transactionIds': ['tx-a', 'tx-b'],
        'rule': {
          'id': 'rec-1',
          'businessId': 'biz-1',
          'type': 'EXPENSE',
          'description': 'Office Rent',
          'amount': '1800.000',
          'currency': 'TND',
          'paymentMethod': 'BANK_TRANSFER',
          'frequency': 'MONTHLY',
          'startDate': '2026-10-01',
          'nextExecutionDate': '2026-12-01',
          'active': true,
          'lastExecutedAt': '2026-11-01T08:00:00Z',
        },
      });

      expect(run.generatedCount, 2);
      expect(run.transactionIds, ['tx-a', 'tx-b']);
      expect(run.rule.amount, Decimal.parse('1800.000'));
      expect(run.rule.lastExecutedAt, isNotNull);
    });
  });
}

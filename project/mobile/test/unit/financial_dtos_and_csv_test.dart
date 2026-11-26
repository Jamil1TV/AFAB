import 'package:afab_mobile/core/utils/color_parser.dart';
import 'package:afab_mobile/core/utils/csv_exporter.dart';
import 'package:afab_mobile/features/categories/data/category_dto.dart';
import 'package:afab_mobile/features/expenses/data/expense_dtos.dart';
import 'package:afab_mobile/features/revenue/data/revenue_dtos.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Financial Core DTOs, ColorParser & CsvExporter', () {
    test('CategoryDto maps Jackson systemDefault and null businessId safely',
        () {
      final sysCat = CategoryDto.fromJson(const {
        'id': 'c1',
        'businessId': null,
        'name': 'Software',
        'type': 'EXPENSE',
        'icon': 'Laptop',
        'color': 'var(--primary)',
        'systemDefault': true,
      });

      expect(sysCat.systemDefault, isTrue);
      expect(sysCat.isExpense, isTrue);
      expect(
        ColorParser.parseHex(sysCat.color, const Color(0xFF8B5CF6)),
        const Color(0xFF8B5CF6),
      );

      final customCat = CategoryDto.fromJson(const {
        'id': 'c2',
        'businessId': 'biz-1',
        'name': 'Retainers',
        'type': 'INCOME',
        'icon': 'DollarSign',
        'color': '#10B981',
        'systemDefault': false,
      });
      expect(customCat.systemDefault, isFalse);
      expect(customCat.isIncome, isTrue);
      expect(
        ColorParser.parseHex(customCat.color, Colors.black),
        const Color(0xFF10B981),
      );
    });

    test('TransactionDto parses FX snapshot, anomalies, and split items', () {
      final tx = TransactionDto.fromJson(const {
        'id': 'tx-100',
        'type': 'EXPENSE',
        'amount': 3350.0,
        'currency': 'TND',
        'originalAmount': 1000.0,
        'originalCurrency': 'EUR',
        'baseCurrency': 'TND',
        'exchangeRate': 3.35,
        'convertedAmount': 3350.0,
        'fxRateSource': 'ECB',
        'legacyFx': false,
        'description': 'Figma & Cloud "Annual"',
        'transactionDate': '2026-11-25',
        'paymentMethod': 'CREDIT_CARD',
        'status': 'COMPLETED',
        'taxDeductible': true,
        'taxRate': 19,
        'isSplit': true,
        'potentialDuplicate': true,
        'priceHikePercentage': 12.5,
        'splitItems': [
          {
            'id': 's1',
            'categoryId': 'c1',
            'categoryName': 'Software',
            'categoryColor': '#8B5CF6',
            'amount': 2000.0,
          },
          {
            'id': 's2',
            'categoryId': 'c2',
            'categoryName': 'Hosting',
            'categoryColor': '#10B981',
            'amount': 1350.0,
          },
        ],
      });

      expect(tx.hasForeignFx, isTrue);
      expect(tx.paymentMethod, PaymentMethod.creditCard);
      expect(tx.isSplit, isTrue);
      expect(tx.splitItems.length, 2);
      expect(tx.potentialDuplicate, isTrue);
      expect(tx.priceHikePercentage, Decimal.parse('12.5'));

      final csv = CsvExporter.buildTransactionsCsv([tx], fallbackCurrency: 'TND');
      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv.contains('3350.000'), isTrue); // 3-decimal TND precision
      expect(csv.contains('"Figma & Cloud ""Annual"""'), isTrue); // escaped quotes
    });

    test('ExpenseSummaryDto & RevenueSummaryDto parse backend DTO fields', () {
      final exp = ExpenseSummaryDto.fromJson(const {
        'totalExpenses': 1250.5,
        'avgPerDay': 125.05,
        'highestExpenseTitle': 'AWS',
        'highestExpenseAmount': 600,
        'categoryCount': 3,
        'recurringTotal': 0,
        'recurringPercentage': 0.0,
        'currency': 'TND',
        'categoryBreakdown': [
          {'name': 'Cloud', 'amount': 600, 'percentage': 48.0, 'color': '#8B5CF6'},
        ],
        'recurringList': [],
        'dailyOverview': [
          {'date': '2026-11-20', 'amount': 600},
        ],
      });
      expect(exp.totalExpenses, Decimal.parse('1250.5'));
      expect(exp.dailyOverview.length, 1);

      final rev = RevenueSummaryDto.fromJson(const {
        'totalRevenue': 9400,
        'grossRevenue': 9400,
        'discounts': 0,
        'refunds': 0,
        'netRevenue': 9400,
        'avgPerDay': 940,
        'highestRevenueAmount': 5000,
        'highestRevenueDate': '2026-11-22',
        'totalInvoices': 7,
        'currency': 'USD',
        'revenueBySource': [],
        'topProducts': [],
        'dailyOverview': [],
      });
      expect(rev.totalInvoices, 7);
      expect(rev.netRevenue, Decimal.fromInt(9400));
    });
  });
}

import 'package:afab_mobile/features/categories/data/category_dto.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:afab_mobile/features/transactions/domain/nlp_transaction_parser.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NlpTransactionParser', () {
    const categories = [
      CategoryDto(
        id: 'cat-sw',
        name: 'Software',
        type: 'EXPENSE',
        systemDefault: true,
      ),
      CategoryDto(
        id: 'cat-sales',
        name: 'Client Consulting',
        type: 'INCOME',
        systemDefault: false,
      ),
    ];

    test('fixes Web thousands-comma bug on \$1,500 income entry', () {
      final parsed = NlpTransactionParser.parse(
        r'Received $1,500 from Acme Client Consulting yesterday via bank transfer',
        defaultCurrency: 'TND',
        categories: categories,
        nowOverride: DateTime(2026, 11, 25),
      );

      expect(parsed.isValid, isTrue);
      expect(parsed.type, TransactionType.income);
      expect(parsed.amount, Decimal.fromInt(1500));
      expect(parsed.currency, 'USD');
      expect(parsed.transactionDate, '2026-11-24');
      expect(parsed.paymentMethod, PaymentMethod.bankTransfer);
      expect(parsed.categoryId, 'cat-sales');
    });

    test('parses 3-decimal TND amounts with commas and matches category', () {
      final parsed = NlpTransactionParser.parse(
        'Paid 12,345.678 TND for Software license via credit card tax',
        defaultCurrency: 'USD',
        categories: categories,
        nowOverride: DateTime(2026, 11, 25),
      );

      expect(parsed.isValid, isTrue);
      expect(parsed.type, TransactionType.expense);
      expect(parsed.amount, Decimal.parse('12345.678'));
      expect(parsed.currency, 'TND');
      expect(parsed.paymentMethod, PaymentMethod.creditCard);
      expect(parsed.categoryId, 'cat-sw');
      expect(parsed.taxDeductible, isTrue);
    });

    test('supports EU comma-decimal and Arabic triggers', () {
      final eu = NlpTransactionParser.parse(
        'Coffee beans 45,50 EUR cash',
        defaultCurrency: 'USD',
        nowOverride: DateTime(2026, 11, 25),
      );
      expect(eu.amount, Decimal.parse('45.5'));
      expect(eu.currency, 'EUR');
      expect(eu.paymentMethod, PaymentMethod.cash);

      final ar = NlpTransactionParser.parse(
        'استلمت 850 د.ت أمس تحويل بنكي',
        defaultCurrency: 'USD',
        nowOverride: DateTime(2026, 11, 25),
      );
      expect(ar.type, TransactionType.income);
      expect(ar.amount, Decimal.fromInt(850));
      expect(ar.currency, 'TND');
      expect(ar.transactionDate, '2026-11-24');
      expect(ar.paymentMethod, PaymentMethod.bankTransfer);
    });

    test('marks input invalid when amount is missing', () {
      final invalid = NlpTransactionParser.parse(
        'Paid vendor for office supplies',
        defaultCurrency: 'USD',
      );
      expect(invalid.isValid, isFalse);
      expect(invalid.amount, isNull);
    });
  });
}

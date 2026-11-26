import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoneyFormatter ISO-4217 & number format tests', () {
    test('formats TND with 3 minor-unit decimals', () {
      final result = MoneyFormatter.formatDecimal(
        Decimal.parse('1234.567'),
        currency: 'TND',
      );
      expect(result, 'DT 1,234.567');
    });

    test('formats JPY with 0 minor-unit decimals and rounds half up', () {
      final result = MoneyFormatter.formatDecimal(
        Decimal.parse('1234.56'),
        currency: 'JPY',
      );
      expect(result, '¥1,235');
    });

    test('supports all 5 AFAB number format styles for USD', () {
      final amount = Decimal.parse('1234567.89');
      expect(
        MoneyFormatter.formatDecimal(amount, currency: 'USD', numberFormat: 'US'),
        r'$1,234,567.89',
      );
      expect(
        MoneyFormatter.formatDecimal(amount, currency: 'USD', numberFormat: 'EU'),
        r'$1.234.567,89',
      );
      expect(
        MoneyFormatter.formatDecimal(amount, currency: 'USD', numberFormat: 'SI'),
        r'$1 234 567,89',
      );
      expect(
        MoneyFormatter.formatDecimal(amount, currency: 'USD', numberFormat: 'DOT'),
        r'$1,234,567·89',
      );
      expect(
        MoneyFormatter.formatDecimal(amount, currency: 'USD', numberFormat: 'RAW'),
        r'$1234567.89',
      );
    });

    test('places negative and optional positive signs before currency prefix', () {
      expect(
        MoneyFormatter.formatDecimal(
          Decimal.parse('-42.5'),
          currency: 'USD',
        ),
        r'-$42.50',
      );
      expect(
        MoneyFormatter.formatDecimal(
          Decimal.parse('42.5'),
          currency: 'EUR',
          showSign: true,
        ),
        '+€42.50',
      );
    });

    test('avoids IEEE-754 float drift on decimal arithmetic', () {
      final sum = Decimal.parse('0.1') + Decimal.parse('0.2');
      expect(
        MoneyFormatter.formatDecimal(sum, currency: 'USD'),
        r'$0.30',
      );
    });

    test('formats compact amounts cleanly', () {
      expect(
        MoneyFormatter.formatCompact(Decimal.parse('1250000'), currency: 'USD'),
        r'$1.3M',
      );
      expect(
        MoneyFormatter.formatCompact(Decimal.parse('12500'), currency: 'USD'),
        r'$12.5K',
      );
      expect(
        MoneyFormatter.formatCompact(Decimal.parse('500'), currency: 'TND'),
        'DT 500.000',
      );
    });
  });
}

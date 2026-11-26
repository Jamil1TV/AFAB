import 'package:afab_mobile/core/money/currency_minor_units.dart';
import 'package:decimal/decimal.dart';

/// Exact decimal financial formatter supporting ISO-4217 minor units
/// (`3` for TND/KWD/BHD/OMR/JOD/LYD/IQD, `0` for JPY/KRW, `2` default),
/// all 5 AFAB number format styles (`US`, `EU`, `SI`, `DOT`, `RAW`),
/// and guaranteed Western Arabic digits (`0-9`).
abstract final class MoneyFormatter {
  static Decimal parseDecimal(dynamic value, {Decimal? fallback}) {
    if (value == null) return fallback ?? Decimal.zero;
    if (value is Decimal) return value;
    if (value is int) return Decimal.fromInt(value);
    if (value is num) {
      return Decimal.tryParse(value.toString()) ?? fallback ?? Decimal.zero;
    }
    if (value is String) {
      final direct = Decimal.tryParse(value.trim());
      if (direct != null) return direct;
      final cleaned = value.replaceAll(RegExp(r'[^0-9.-]'), '');
      return Decimal.tryParse(cleaned) ?? fallback ?? Decimal.zero;
    }
    return fallback ?? Decimal.zero;
  }

  static String formatDecimal(
    Decimal amount, {
    required String currency,
    String numberFormat = 'US',
    bool showSign = false,
  }) {
    final decimals = CurrencyMinorUnits.decimalsFor(currency);
    final isNegative = amount < Decimal.zero;
    final absVal = amount.abs();
    final rounded = absVal.round(scale: decimals);

    final rawStr = rounded.toStringAsFixed(decimals);
    final parts = rawStr.split('.');
    final intPart = parts[0];
    final fracPart = parts.length > 1 ? parts[1] : '';

    final formattedNumber = _applyNumberStyle(
      intPart: intPart,
      fracPart: fracPart,
      style: numberFormat,
    );

    final prefix = CurrencyMinorUnits.prefixFor(currency);
    final sign = isNegative
        ? '-'
        : (showSign && amount > Decimal.zero ? '+' : '');
    return '$sign$prefix$formattedNumber';
  }

  static String formatNum(
    num amount, {
    required String currency,
    String numberFormat = 'US',
    bool showSign = false,
  }) {
    return formatDecimal(
      parseDecimal(amount),
      currency: currency,
      numberFormat: numberFormat,
      showSign: showSign,
    );
  }

  static String formatCompact(
    Decimal amount, {
    required String currency,
    String numberFormat = 'US',
  }) {
    final abs = amount.abs();
    final million = Decimal.fromInt(1000000);
    final thousand = Decimal.fromInt(1000);
    final sign = amount < Decimal.zero ? '-' : '';
    final prefix = CurrencyMinorUnits.prefixFor(currency);

    if (abs >= million) {
      final val = (abs.toDouble() / 1000000.0).toStringAsFixed(1);
      return '$sign$prefix${val}M';
    }
    if (abs >= thousand) {
      final val = (abs.toDouble() / 1000.0).toStringAsFixed(1);
      return '$sign$prefix${val}K';
    }
    return formatDecimal(amount, currency: currency, numberFormat: numberFormat);
  }

  static String _applyNumberStyle({
    required String intPart,
    required String fracPart,
    required String style,
  }) {
    final upper = style.toUpperCase();
    final (groupSep, decSep) = switch (upper) {
      'EU' => ('.', ','),
      'SI' => (' ', ','),
      'DOT' => (',', '·'),
      'RAW' => ('', '.'),
      _ => (',', '.'),
    };

    final groupedInt = groupSep.isEmpty ? intPart : _groupThousands(intPart, groupSep);
    if (fracPart.isEmpty) {
      return groupedInt;
    }
    return '$groupedInt$decSep$fracPart';
  }

  static String _groupThousands(String digits, String sep) {
    final buffer = StringBuffer();
    var count = 0;
    for (var i = digits.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write(sep);
      }
      buffer.write(digits[i]);
      count++;
    }
    return buffer.toString().split('').reversed.join();
  }
}

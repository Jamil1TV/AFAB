import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:afab_mobile/features/categories/data/category_dto.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

class ParsedNlpTransaction {
  const ParsedNlpTransaction({
    required this.type,
    required this.amount,
    required this.currency,
    required this.description,
    required this.transactionDate,
    required this.paymentMethod,
    this.categoryId,
    this.categoryName,
    required this.taxDeductible,
  });

  final TransactionType type;
  final Decimal? amount;
  final String currency;
  final String description;
  final String transactionDate; // YYYY-MM-DD
  final PaymentMethod paymentMethod;
  final String? categoryId;
  final String? categoryName;
  final bool taxDeductible;

  bool get isValid =>
      amount != null &&
      amount! >= Decimal.parse('0.0001') &&
      description.trim().isNotEmpty;
}

/// Natural-language quick transaction parser fixing Web's `"$1,500"` comma bug
/// and adding English + Arabic triggers for type, currency, date, and method.
abstract final class NlpTransactionParser {
  static final List<String> _incomeKeywords = [
    'received',
    'earned',
    'income',
    'invoiced',
    'deposit',
    'sold',
    'revenue',
    'got paid',
    'salary',
    'refund from',
    'client paid',
    'payment from',
    'استلمت',
    'إيراد',
    'دخل',
    'دفعة عميل',
    'قبضت',
  ];

  static final RegExp _thousandsAmountRegex = RegExp(
    r'\b\d{1,3}(?:,\d{3})+(?:\.\d{1,4})?\b',
  );
  static final RegExp _commaDecimalRegex = RegExp(
    r'\b\d+,\d{1,3}(?!\d)',
  );
  static final RegExp _standardAmountRegex = RegExp(
    r'\b\d+(?:\.\d{1,4})?\b',
  );

  static ParsedNlpTransaction parse(
    String rawInput, {
    required String defaultCurrency,
    List<CategoryDto> categories = const [],
    DateTime? nowOverride,
  }) {
    final trimmed = rawInput.trim();
    final lower = trimmed.toLowerCase();
    final now = nowOverride ?? DateTime.now();

    // 1. Determine type
    final isIncome = _incomeKeywords.any((kw) => lower.contains(kw));
    final type = isIncome ? TransactionType.income : TransactionType.expense;

    // 2. Determine date
    var date = now;
    if (lower.contains('yesterday') || lower.contains('أمس')) {
      date = now.subtract(const Duration(days: 1));
    } else if (lower.contains('last week') || lower.contains('الأسبوع الماضي')) {
      date = now.subtract(const Duration(days: 7));
    }
    final formattedDate = DateFormat('yyyy-MM-dd', 'en_US').format(date);

    // 3. Extract currency hint
    final currency = _detectCurrency(trimmed, lower, defaultCurrency);

    // 4. Extract amount cleanly preserving comma thousands separators
    final (amount, matchedAmountToken) = _extractAmount(trimmed);

    // 5. Detect payment method
    final paymentMethod = _detectPaymentMethod(lower);

    // 6. Tax-deductible keyword
    final taxDeductible = lower.contains('tax') ||
        lower.contains('deductible') ||
        lower.contains('ضريبة') ||
        lower.contains('ضريبي');

    // 7. Match best category matching detected type
    String? categoryId;
    String? categoryName;
    for (final cat in categories) {
      if (cat.type.toUpperCase() != type.apiValue) continue;
      if (cat.name.trim().isNotEmpty &&
          lower.contains(cat.name.trim().toLowerCase())) {
        categoryId = cat.id;
        categoryName = cat.name;
        break;
      }
    }

    // 8. Build clean description
    var desc = trimmed;
    if (matchedAmountToken != null && matchedAmountToken.isNotEmpty) {
      desc = desc.replaceFirst(matchedAmountToken, '');
    }
    desc = desc
        .replaceAll(
          RegExp(
            r'(\$|€|£|¥|\b(?:USD|EUR|GBP|TND|AED|SAR|KWD|MAD|CAD|AUD|CHF|QAR|JPY|DT)\b|د\.ت)',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'\b(yesterday|today|last week|via bank transfer|via credit card|via card|via cash|by card|by cash)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (desc.isEmpty && trimmed.isNotEmpty) {
      desc = trimmed;
    }

    return ParsedNlpTransaction(
      type: type,
      amount: amount,
      currency: currency,
      description: desc,
      transactionDate: formattedDate,
      paymentMethod: paymentMethod,
      categoryId: categoryId,
      categoryName: categoryName,
      taxDeductible: taxDeductible,
    );
  }

  static (Decimal?, String?) _extractAmount(String input) {
    final thousandsMatch = _thousandsAmountRegex.firstMatch(input);
    if (thousandsMatch != null) {
      final token = thousandsMatch.group(0)!;
      final normalized = token.replaceAll(',', '');
      return (MoneyFormatter.parseDecimal(normalized), token);
    }

    final commaDecimalMatch = _commaDecimalRegex.firstMatch(input);
    if (commaDecimalMatch != null) {
      final token = commaDecimalMatch.group(0)!;
      final normalized = token.replaceAll(',', '.');
      return (MoneyFormatter.parseDecimal(normalized), token);
    }

    final stdMatch = _standardAmountRegex.firstMatch(input);
    if (stdMatch != null) {
      final token = stdMatch.group(0)!;
      return (MoneyFormatter.parseDecimal(token), token);
    }

    return (null, null);
  }

  static String _detectCurrency(
    String raw,
    String lower,
    String defaultCurrency,
  ) {
    const codeOrder = [
      'TND',
      'USD',
      'EUR',
      'GBP',
      'AED',
      'SAR',
      'KWD',
      'QAR',
      'MAD',
      'CAD',
      'AUD',
      'CHF',
      'JPY',
    ];
    for (final code in codeOrder) {
      if (RegExp('\\b$code\\b', caseSensitive: false).hasMatch(raw)) {
        return code;
      }
    }
    if (RegExp(r'\bdt\b', caseSensitive: false).hasMatch(raw) ||
        raw.contains('د.ت') ||
        lower.contains('dinar')) {
      return 'TND';
    }
    if (raw.contains('€')) return 'EUR';
    if (raw.contains('£')) return 'GBP';
    if (raw.contains('¥')) return 'JPY';
    if (raw.contains(r'$')) return 'USD';
    return defaultCurrency.toUpperCase();
  }

  static PaymentMethod _detectPaymentMethod(String lower) {
    if (lower.contains('credit card') || lower.contains('بطاقة ائتمان')) {
      return PaymentMethod.creditCard;
    }
    if (lower.contains('cash') ||
        lower.contains('bills') ||
        lower.contains('نقد')) {
      return PaymentMethod.cash;
    }
    if (lower.contains('card') ||
        lower.contains('debit') ||
        lower.contains('visa') ||
        lower.contains('mastercard') ||
        lower.contains('amex') ||
        lower.contains('بطاقة')) {
      return PaymentMethod.card;
    }
    if (lower.contains('bank') ||
        lower.contains('wire') ||
        lower.contains('transfer') ||
        lower.contains('ach') ||
        lower.contains('تحويل')) {
      return PaymentMethod.bankTransfer;
    }
    if (lower.contains('paypal') ||
        lower.contains('stripe') ||
        lower.contains('crypto')) {
      return PaymentMethod.other;
    }
    return PaymentMethod.bankTransfer;
  }
}

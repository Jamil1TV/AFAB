import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

enum TransactionType {
  income('INCOME'),
  expense('EXPENSE');

  const TransactionType(this.apiValue);
  final String apiValue;

  static TransactionType fromApi(String? value) {
    return value?.toUpperCase() == 'INCOME'
        ? TransactionType.income
        : TransactionType.expense;
  }
}

enum TransactionStatus {
  completed('COMPLETED'),
  pending('PENDING'),
  cancelled('CANCELLED');

  const TransactionStatus(this.apiValue);
  final String apiValue;

  static TransactionStatus fromApi(String? value) {
    return switch (value?.toUpperCase()) {
      'PENDING' => TransactionStatus.pending,
      'CANCELLED' => TransactionStatus.cancelled,
      _ => TransactionStatus.completed,
    };
  }
}

enum PaymentMethod {
  bankTransfer('BANK_TRANSFER'),
  card('CARD'),
  creditCard('CREDIT_CARD'),
  cash('CASH'),
  other('OTHER');

  const PaymentMethod(this.apiValue);
  final String apiValue;

  static PaymentMethod fromApi(String? value) {
    return switch (value?.toUpperCase()) {
      'CARD' => PaymentMethod.card,
      'CREDIT_CARD' => PaymentMethod.creditCard,
      'CASH' => PaymentMethod.cash,
      'OTHER' => PaymentMethod.other,
      _ => PaymentMethod.bankTransfer,
    };
  }
}

enum TransactionPeriod {
  weekly('weekly'),
  monthly('monthly'),
  yearly('yearly'),
  all('all'),
  custom('custom');

  const TransactionPeriod(this.apiValue);
  final String apiValue;
}

enum TransactionSortField { date, amount }

enum TransactionFormMode { create, duplicate, edit }

@immutable
class SplitItemDto {
  const SplitItemDto({
    required this.id,
    this.categoryId,
    required this.categoryName,
    this.categoryColor,
    this.categoryIcon,
    required this.amount,
    this.description,
  });

  final String id;
  final String? categoryId;
  final String categoryName;
  final String? categoryColor;
  final String? categoryIcon;
  final Decimal amount;
  final String? description;

  factory SplitItemDto.fromJson(Map<String, dynamic> json) {
    return SplitItemDto(
      id: (json['id'] ?? '').toString(),
      categoryId: json['categoryId']?.toString(),
      categoryName: (json['categoryName'] ?? 'Uncategorized').toString(),
      categoryColor: json['categoryColor']?.toString(),
      categoryIcon: json['categoryIcon']?.toString(),
      amount: MoneyFormatter.parseDecimal(json['amount']),
      description: json['description']?.toString(),
    );
  }
}

@immutable
class TransactionDto {
  const TransactionDto({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    this.originalAmount,
    this.originalCurrency,
    this.baseCurrency,
    this.exchangeRate,
    this.convertedAmount,
    this.fxRateSource,
    this.fxRateTimestamp,
    this.legacyFx = false,
    required this.description,
    required this.transactionDate,
    required this.paymentMethod,
    required this.status,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    this.categoryIcon,
    this.notes,
    this.taxDeductible = false,
    this.taxRate,
    this.isSplit = false,
    this.parentTransactionId,
    this.potentialDuplicate = false,
    this.priceHikePercentage,
    this.splitItems = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final TransactionType type;
  final Decimal amount;
  final String currency;
  final Decimal? originalAmount;
  final String? originalCurrency;
  final String? baseCurrency;
  final Decimal? exchangeRate;
  final Decimal? convertedAmount;
  final String? fxRateSource;
  final DateTime? fxRateTimestamp;
  final bool legacyFx;
  final String description;
  final String transactionDate;
  final PaymentMethod paymentMethod;
  final TransactionStatus status;
  final String? categoryId;
  final String? categoryName;
  final String? categoryColor;
  final String? categoryIcon;
  final String? notes;
  final bool taxDeductible;
  final Decimal? taxRate;
  final bool isSplit;
  final String? parentTransactionId;
  final bool potentialDuplicate;
  final Decimal? priceHikePercentage;
  final List<SplitItemDto> splitItems;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isIncome => type == TransactionType.income;
  String get resolvedBaseCurrency => baseCurrency ?? currency;

  bool get hasForeignFx =>
      originalCurrency != null &&
      originalCurrency!.isNotEmpty &&
      originalCurrency!.toUpperCase() != resolvedBaseCurrency.toUpperCase() &&
      exchangeRate != null;

  factory TransactionDto.fromJson(Map<String, dynamic> json) {
    final rawSplits = json['splitItems'] as List<dynamic>? ?? const [];
    return TransactionDto(
      id: (json['id'] ?? '').toString(),
      type: TransactionType.fromApi(json['type']?.toString()),
      amount: MoneyFormatter.parseDecimal(json['amount']),
      currency: (json['currency'] ?? json['baseCurrency'] ?? 'USD').toString(),
      originalAmount: json['originalAmount'] != null
          ? MoneyFormatter.parseDecimal(json['originalAmount'])
          : null,
      originalCurrency: json['originalCurrency']?.toString(),
      baseCurrency: json['baseCurrency']?.toString(),
      exchangeRate: json['exchangeRate'] != null
          ? MoneyFormatter.parseDecimal(json['exchangeRate'])
          : null,
      convertedAmount: json['convertedAmount'] != null
          ? MoneyFormatter.parseDecimal(json['convertedAmount'])
          : null,
      fxRateSource: json['fxRateSource']?.toString(),
      fxRateTimestamp: json['fxRateTimestamp'] is String
          ? DateTime.tryParse(json['fxRateTimestamp'] as String)
          : null,
      legacyFx: json['legacyFx'] as bool? ?? false,
      description: (json['description'] ?? '').toString(),
      transactionDate: (json['transactionDate'] ?? '').toString(),
      paymentMethod: PaymentMethod.fromApi(json['paymentMethod']?.toString()),
      status: TransactionStatus.fromApi(json['status']?.toString()),
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName']?.toString(),
      categoryColor: json['categoryColor']?.toString(),
      categoryIcon: json['categoryIcon']?.toString(),
      notes: json['notes']?.toString(),
      taxDeductible: json['taxDeductible'] as bool? ?? false,
      taxRate: json['taxRate'] != null
          ? MoneyFormatter.parseDecimal(json['taxRate'])
          : null,
      isSplit:
          (json['isSplit'] as bool?) ?? (json['split'] as bool?) ?? false,
      parentTransactionId: json['parentTransactionId']?.toString(),
      potentialDuplicate: json['potentialDuplicate'] as bool? ?? false,
      priceHikePercentage: json['priceHikePercentage'] != null
          ? MoneyFormatter.parseDecimal(json['priceHikePercentage'])
          : null,
      splitItems: rawSplits
          .whereType<Map<String, dynamic>>()
          .map(SplitItemDto.fromJson)
          .toList(),
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] is String
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}

@immutable
class TransactionPageDto {
  const TransactionPageDto({
    required this.content,
    required this.pageNumber,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.totalInflow,
    required this.totalOutflow,
    required this.netBalance,
    required this.currency,
  });

  final List<TransactionDto> content;
  final int pageNumber;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final Decimal totalInflow;
  final Decimal totalOutflow;
  final Decimal netBalance;
  final String currency;

  factory TransactionPageDto.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'] as List<dynamic>? ?? const [];
    return TransactionPageDto(
      content: rawContent
          .whereType<Map<String, dynamic>>()
          .map(TransactionDto.fromJson)
          .toList(),
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 0,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 15,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      totalInflow: MoneyFormatter.parseDecimal(json['totalInflow']),
      totalOutflow: MoneyFormatter.parseDecimal(json['totalOutflow']),
      netBalance: MoneyFormatter.parseDecimal(json['netBalance']),
      currency: (json['currency'] ?? 'USD').toString(),
    );
  }
}

@immutable
class FxConvertResultDto {
  const FxConvertResultDto({
    required this.from,
    required this.to,
    required this.amount,
    required this.exchangeRate,
    required this.convertedAmount,
  });

  final String from;
  final String to;
  final Decimal amount;
  final Decimal exchangeRate;
  final Decimal convertedAmount;

  factory FxConvertResultDto.fromJson(Map<String, dynamic> json) {
    return FxConvertResultDto(
      from: (json['from'] ?? 'USD').toString().toUpperCase(),
      to: (json['to'] ?? 'USD').toString().toUpperCase(),
      amount: MoneyFormatter.parseDecimal(json['amount']),
      exchangeRate: MoneyFormatter.parseDecimal(json['exchangeRate']),
      convertedAmount: MoneyFormatter.parseDecimal(json['convertedAmount']),
    );
  }
}

@immutable
class SplitLinePayload {
  const SplitLinePayload({
    required this.categoryId,
    required this.amount,
    this.description,
  });

  final String categoryId;
  final Decimal amount;
  final String? description;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'categoryId': categoryId,
        'amount': amount.toString(),
        if (description != null && description!.trim().isNotEmpty)
          'description': description!.trim(),
      };
}

@immutable
class CreateTransactionPayload {
  const CreateTransactionPayload({
    required this.type,
    required this.amount,
    this.originalCurrency,
    this.exchangeRate,
    required this.description,
    required this.transactionDate,
    this.categoryId,
    required this.paymentMethod,
    required this.status,
    this.notes,
    this.taxDeductible = false,
    this.taxRate,
    this.splitItems = const [],
  });

  final TransactionType type;
  final Decimal amount;
  final String? originalCurrency;
  final Decimal? exchangeRate;
  final String description;
  final String transactionDate; // YYYY-MM-DD
  final String? categoryId;
  final PaymentMethod paymentMethod;
  final TransactionStatus status;
  final String? notes;
  final bool taxDeductible;
  final Decimal? taxRate;
  final List<SplitLinePayload> splitItems;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.apiValue,
        'amount': amount.toString(),
        if (originalCurrency != null && originalCurrency!.isNotEmpty)
          'originalCurrency': originalCurrency!.toUpperCase(),
        if (exchangeRate != null) 'exchangeRate': exchangeRate.toString(),
        'description': description.trim(),
        'transactionDate': transactionDate,
        if (categoryId != null && categoryId!.isNotEmpty)
          'categoryId': categoryId,
        'paymentMethod': paymentMethod.apiValue,
        'status': status.apiValue,
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
        'taxDeductible': taxDeductible,
        if (taxDeductible && taxRate != null) 'taxRate': taxRate.toString(),
        if (splitItems.isNotEmpty)
          'splitItems': splitItems.map((e) => e.toJson()).toList(),
      };
}

@immutable
class UpdateTransactionPayload {
  const UpdateTransactionPayload({
    required this.type,
    required this.amount,
    required this.description,
    required this.transactionDate,
    this.categoryId,
    required this.paymentMethod,
    required this.status,
    this.notes,
    required this.taxDeductible,
    this.taxRate,
  });

  final TransactionType type;
  final Decimal amount;
  final String description;
  final String transactionDate;
  final String? categoryId;
  final PaymentMethod paymentMethod;
  final TransactionStatus status;
  final String? notes;
  final bool taxDeductible;
  final Decimal? taxRate;

  /// Intentionally omits `originalCurrency` & `exchangeRate` per backend
  /// historical FX immutability contract (`TransactionService.java:330-343`).
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.apiValue,
        'amount': amount.toString(),
        'description': description.trim(),
        'transactionDate': transactionDate,
        'categoryId':
            (categoryId != null && categoryId!.isNotEmpty) ? categoryId : null,
        'paymentMethod': paymentMethod.apiValue,
        'status': status.apiValue,
        'notes': (notes != null && notes!.trim().isNotEmpty)
            ? notes!.trim()
            : null,
        'taxDeductible': taxDeductible,
        'taxRate': (taxDeductible && taxRate != null)
            ? taxRate.toString()
            : null,
      };
}

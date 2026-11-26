import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

@immutable
class RecurringTransactionDto {
  const RecurringTransactionDto({
    required this.id,
    required this.businessId,
    required this.type,
    required this.description,
    required this.amount,
    required this.currency,
    this.categoryId,
    this.categoryName,
    required this.paymentMethod,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.nextExecutionDate,
    required this.active,
    this.notes,
    this.lastExecutedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String businessId;
  final String type; // INCOME | EXPENSE
  final String description;
  final Decimal amount;
  final String currency;
  final String? categoryId;
  final String? categoryName;
  final String paymentMethod;
  final String frequency; // WEEKLY | MONTHLY | QUARTERLY | YEARLY
  final String startDate;
  final String? endDate;
  final String nextExecutionDate;
  final bool active;
  final String? notes;
  final DateTime? lastExecutedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isIncome => type.toUpperCase() == 'INCOME';

  factory RecurringTransactionDto.fromJson(Map<String, dynamic> json) {
    return RecurringTransactionDto(
      id: (json['id'] ?? '').toString(),
      businessId: (json['businessId'] ?? '').toString(),
      type: (json['type'] ?? 'EXPENSE').toString().toUpperCase(),
      description: (json['description'] ?? '').toString(),
      amount: MoneyFormatter.parseDecimal(json['amount']),
      currency: (json['currency'] ?? 'USD').toString().toUpperCase(),
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName']?.toString(),
      paymentMethod: (json['paymentMethod'] ?? 'BANK_TRANSFER').toString(),
      frequency: (json['frequency'] ?? 'MONTHLY').toString().toUpperCase(),
      startDate: (json['startDate'] ?? '').toString(),
      endDate: json['endDate']?.toString(),
      nextExecutionDate: (json['nextExecutionDate'] ?? '').toString(),
      active: json['active'] as bool? ?? true,
      notes: json['notes']?.toString(),
      lastExecutedAt: json['lastExecutedAt'] is String
          ? DateTime.tryParse(json['lastExecutedAt'] as String)
          : null,
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
class RecurringRunResultDto {
  const RecurringRunResultDto({
    required this.rule,
    required this.generatedCount,
    this.transactionIds = const [],
  });

  final RecurringTransactionDto rule;
  final int generatedCount;
  final List<String> transactionIds;

  factory RecurringRunResultDto.fromJson(Map<String, dynamic> json) {
    final ids = json['transactionIds'] as List<dynamic>? ?? const [];
    return RecurringRunResultDto(
      rule: RecurringTransactionDto.fromJson(
        json['rule'] as Map<String, dynamic>? ?? const {},
      ),
      generatedCount: (json['generatedCount'] as num?)?.toInt() ?? 0,
      transactionIds: ids.map((e) => e.toString()).toList(),
    );
  }
}

@immutable
class RecurringTransactionRequestDto {
  const RecurringTransactionRequestDto({
    required this.type,
    required this.description,
    required this.amount,
    required this.currency,
    this.categoryId,
    this.paymentMethod = 'BANK_TRANSFER',
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.active = true,
    this.notes,
  });

  final String type;
  final String description;
  final Decimal amount;
  final String currency;
  final String? categoryId;
  final String paymentMethod;
  final String frequency;
  final String startDate;
  final String? endDate;
  final bool active;
  final String? notes;

  Map<String, dynamic> toJson() {
    final cleanNotes = notes?.trim();
    return {
      'type': type.toUpperCase(),
      'description': description.trim(),
      'amount': amount.toString(),
      'currency': currency.toUpperCase(),
      if (categoryId != null && categoryId!.isNotEmpty)
        'categoryId': categoryId,
      'paymentMethod': paymentMethod,
      'frequency': frequency.toUpperCase(),
      'startDate': startDate,
      if (endDate != null && endDate!.isNotEmpty) 'endDate': endDate,
      'active': active,
      if (cleanNotes != null && cleanNotes.isNotEmpty) 'notes': cleanNotes,
    };
  }
}

import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

@immutable
class BudgetDto {
  const BudgetDto({
    required this.id,
    required this.businessId,
    required this.name,
    required this.budgetAmount,
    required this.currency,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    required this.alertThresholdPercent,
    this.description,
    required this.status,
    required this.actualSpending,
    required this.remainingAmount,
    required this.overBudgetAmount,
    required this.percentageConsumed,
    required this.alertLevel,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String businessId;
  final String name;
  final Decimal budgetAmount;
  final String currency;
  final String? categoryId;
  final String? categoryName;
  final String? categoryColor;
  final String periodType; // MONTHLY | QUARTERLY | YEARLY | CUSTOM
  final String startDate;
  final String endDate;
  final int alertThresholdPercent;
  final String? description;
  final String status; // ACTIVE | ARCHIVED
  final Decimal actualSpending;
  final Decimal remainingAmount;
  final Decimal overBudgetAmount;
  final Decimal percentageConsumed;
  final String alertLevel; // OK | APPROACHING | OVER_BUDGET
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isArchived => status.toUpperCase() == 'ARCHIVED';

  factory BudgetDto.fromJson(Map<String, dynamic> json) {
    return BudgetDto(
      id: (json['id'] ?? '').toString(),
      businessId: (json['businessId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      budgetAmount: MoneyFormatter.parseDecimal(json['budgetAmount']),
      currency: (json['currency'] ?? 'USD').toString().toUpperCase(),
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName']?.toString(),
      categoryColor: json['categoryColor']?.toString(),
      periodType: (json['periodType'] ?? 'MONTHLY').toString().toUpperCase(),
      startDate: (json['startDate'] ?? '').toString(),
      endDate: (json['endDate'] ?? '').toString(),
      alertThresholdPercent:
          (json['alertThresholdPercent'] as num?)?.toInt() ?? 80,
      description: json['description']?.toString(),
      status: (json['status'] ?? 'ACTIVE').toString().toUpperCase(),
      actualSpending: MoneyFormatter.parseDecimal(json['actualSpending']),
      remainingAmount: MoneyFormatter.parseDecimal(json['remainingAmount']),
      overBudgetAmount: MoneyFormatter.parseDecimal(json['overBudgetAmount']),
      percentageConsumed: MoneyFormatter.parseDecimal(
        json['percentageConsumed'],
      ),
      alertLevel: (json['alertLevel'] ?? 'OK').toString().toUpperCase(),
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
class BudgetOverviewSummaryDto {
  const BudgetOverviewSummaryDto({
    required this.currency,
    required this.activeBudgetCount,
    required this.approachingCount,
    required this.overBudgetCount,
    required this.totalBudgeted,
    required this.totalSpent,
    required this.totalRemaining,
    this.budgets = const [],
  });

  final String currency;
  final int activeBudgetCount;
  final int approachingCount;
  final int overBudgetCount;
  final Decimal totalBudgeted;
  final Decimal totalSpent;
  final Decimal totalRemaining;
  final List<BudgetDto> budgets;

  factory BudgetOverviewSummaryDto.fromJson(Map<String, dynamic> json) {
    final raw = json['budgets'] as List<dynamic>? ?? const [];
    return BudgetOverviewSummaryDto(
      currency: (json['currency'] ?? 'USD').toString().toUpperCase(),
      activeBudgetCount: (json['activeBudgetCount'] as num?)?.toInt() ?? 0,
      approachingCount: (json['approachingCount'] as num?)?.toInt() ?? 0,
      overBudgetCount: (json['overBudgetCount'] as num?)?.toInt() ?? 0,
      totalBudgeted: MoneyFormatter.parseDecimal(json['totalBudgeted']),
      totalSpent: MoneyFormatter.parseDecimal(json['totalSpent']),
      totalRemaining: MoneyFormatter.parseDecimal(json['totalRemaining']),
      budgets: raw
          .whereType<Map<String, dynamic>>()
          .map(BudgetDto.fromJson)
          .toList(),
    );
  }
}

@immutable
class BudgetRequestDto {
  const BudgetRequestDto({
    required this.name,
    required this.amount,
    this.currency,
    this.categoryId,
    required this.periodType,
    this.startDate,
    this.endDate,
    this.alertThresholdPercent = 80,
    this.description,
  });

  final String name;
  final Decimal amount;
  final String? currency;
  final String? categoryId;
  final String periodType;
  final String? startDate;
  final String? endDate;
  final int alertThresholdPercent;
  final String? description;

  Map<String, dynamic> toJson() {
    final cleanDesc = description?.trim();
    return {
      'name': name.trim(),
      'amount': amount.toString(),
      if (currency != null && currency!.isNotEmpty)
        'currency': currency!.toUpperCase(),
      if (categoryId != null && categoryId!.isNotEmpty)
        'categoryId': categoryId,
      'periodType': periodType.toUpperCase(),
      if (startDate != null && startDate!.isNotEmpty) 'startDate': startDate,
      if (endDate != null && endDate!.isNotEmpty) 'endDate': endDate,
      'alertThresholdPercent': alertThresholdPercent,
      if (cleanDesc != null && cleanDesc.isNotEmpty) 'description': cleanDesc,
    };
  }
}

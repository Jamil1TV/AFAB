import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

@immutable
class CategoryBreakdownItemDto {
  const CategoryBreakdownItemDto({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  final String name;
  final Decimal amount;
  final double percentage;
  final String color;

  factory CategoryBreakdownItemDto.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdownItemDto(
      name: (json['name'] ?? 'Uncategorized').toString(),
      amount: MoneyFormatter.parseDecimal(json['amount']),
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      color: (json['color'] ?? '#8b5cf6').toString(),
    );
  }
}

@immutable
class ExpenseRecurringItemDto {
  const ExpenseRecurringItemDto({
    required this.name,
    required this.amount,
    required this.billingCycle,
    required this.dueDate,
    this.icon,
  });

  final String name;
  final Decimal amount;
  final String billingCycle;
  final String dueDate;
  final String? icon;

  factory ExpenseRecurringItemDto.fromJson(Map<String, dynamic> json) {
    return ExpenseRecurringItemDto(
      name: (json['name'] ?? '').toString(),
      amount: MoneyFormatter.parseDecimal(json['amount']),
      billingCycle: (json['billingCycle'] ?? '').toString(),
      dueDate: (json['dueDate'] ?? '').toString(),
      icon: json['icon']?.toString(),
    );
  }
}

@immutable
class DailyOverviewPointDto {
  const DailyOverviewPointDto({
    required this.date,
    required this.amount,
  });

  final String date;
  final double amount;

  factory DailyOverviewPointDto.fromJson(Map<String, dynamic> json) {
    return DailyOverviewPointDto(
      date: (json['date'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

@immutable
class ExpenseSummaryDto {
  const ExpenseSummaryDto({
    required this.totalExpenses,
    required this.avgPerDay,
    required this.highestExpenseTitle,
    required this.highestExpenseAmount,
    required this.categoryCount,
    required this.recurringTotal,
    required this.recurringPercentage,
    required this.currency,
    required this.categoryBreakdown,
    required this.recurringList,
    required this.dailyOverview,
  });

  final Decimal totalExpenses;
  final Decimal avgPerDay;
  final String highestExpenseTitle;
  final Decimal highestExpenseAmount;
  final int categoryCount;
  final Decimal recurringTotal;
  final double recurringPercentage;
  final String currency;
  final List<CategoryBreakdownItemDto> categoryBreakdown;
  final List<ExpenseRecurringItemDto> recurringList;
  final List<DailyOverviewPointDto> dailyOverview;

  factory ExpenseSummaryDto.fromJson(Map<String, dynamic> json) {
    final cats = json['categoryBreakdown'] as List<dynamic>? ?? const [];
    final recs = json['recurringList'] as List<dynamic>? ?? const [];
    final daily = json['dailyOverview'] as List<dynamic>? ?? const [];
    return ExpenseSummaryDto(
      totalExpenses: MoneyFormatter.parseDecimal(json['totalExpenses']),
      avgPerDay: MoneyFormatter.parseDecimal(json['avgPerDay']),
      highestExpenseTitle: (json['highestExpenseTitle'] ?? '-').toString(),
      highestExpenseAmount:
          MoneyFormatter.parseDecimal(json['highestExpenseAmount']),
      categoryCount: (json['categoryCount'] as num?)?.toInt() ?? 0,
      recurringTotal: MoneyFormatter.parseDecimal(json['recurringTotal']),
      recurringPercentage:
          (json['recurringPercentage'] as num?)?.toDouble() ?? 0.0,
      currency: (json['currency'] ?? 'USD').toString(),
      categoryBreakdown: cats
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) =>
                CategoryBreakdownItemDto.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      recurringList: recs
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) =>
                ExpenseRecurringItemDto.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      dailyOverview: daily
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) => DailyOverviewPointDto.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }
}

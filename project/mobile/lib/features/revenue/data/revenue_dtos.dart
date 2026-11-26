import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:afab_mobile/features/expenses/data/expense_dtos.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

@immutable
class RevenueSummaryDto {
  const RevenueSummaryDto({
    required this.totalRevenue,
    required this.grossRevenue,
    required this.discounts,
    required this.refunds,
    required this.netRevenue,
    required this.avgPerDay,
    required this.highestRevenueAmount,
    required this.highestRevenueDate,
    required this.totalInvoices,
    required this.currency,
    required this.revenueBySource,
    required this.topProducts,
    required this.dailyOverview,
  });

  final Decimal totalRevenue;
  final Decimal grossRevenue;
  final Decimal discounts;
  final Decimal refunds;
  final Decimal netRevenue;
  final Decimal avgPerDay;
  final Decimal highestRevenueAmount;
  final String highestRevenueDate;
  final int totalInvoices;
  final String currency;
  final List<CategoryBreakdownItemDto> revenueBySource;
  final List<CategoryBreakdownItemDto> topProducts;
  final List<DailyOverviewPointDto> dailyOverview;

  factory RevenueSummaryDto.fromJson(Map<String, dynamic> json) {
    final sources = json['revenueBySource'] as List<dynamic>? ?? const [];
    final products = json['topProducts'] as List<dynamic>? ?? const [];
    final daily = json['dailyOverview'] as List<dynamic>? ?? const [];
    return RevenueSummaryDto(
      totalRevenue: MoneyFormatter.parseDecimal(json['totalRevenue']),
      grossRevenue: MoneyFormatter.parseDecimal(json['grossRevenue']),
      discounts: MoneyFormatter.parseDecimal(json['discounts']),
      refunds: MoneyFormatter.parseDecimal(json['refunds']),
      netRevenue: MoneyFormatter.parseDecimal(json['netRevenue']),
      avgPerDay: MoneyFormatter.parseDecimal(json['avgPerDay']),
      highestRevenueAmount:
          MoneyFormatter.parseDecimal(json['highestRevenueAmount']),
      highestRevenueDate: (json['highestRevenueDate'] ?? '-').toString(),
      totalInvoices: (json['totalInvoices'] as num?)?.toInt() ?? 0,
      currency: (json['currency'] ?? 'USD').toString(),
      revenueBySource: sources
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) =>
                CategoryBreakdownItemDto.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      topProducts: products
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) =>
                CategoryBreakdownItemDto.fromJson(Map<String, dynamic>.from(e)),
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

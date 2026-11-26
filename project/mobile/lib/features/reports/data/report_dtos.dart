import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

@immutable
class CategoryShareDto {
  const CategoryShareDto({
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
  });

  final String categoryName;
  final Decimal amount;
  final double percentage;
  final int transactionCount;

  factory CategoryShareDto.fromJson(Map<String, dynamic> json) {
    return CategoryShareDto(
      categoryName: (json['categoryName'] ?? 'Uncategorized').toString(),
      amount: MoneyFormatter.parseDecimal(json['amount']),
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class ProfitAndLossReportDto {
  const ProfitAndLossReportDto({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.currency,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.grossProfit,
    required this.netOperatingIncome,
    required this.profitMarginPct,
    this.revenueBreakdown = const [],
    this.expenseBreakdown = const [],
  });

  final String period;
  final String startDate;
  final String endDate;
  final String currency;
  final Decimal totalRevenue;
  final Decimal totalExpenses;
  final Decimal grossProfit;
  final Decimal netOperatingIncome;
  final double profitMarginPct;
  final List<CategoryShareDto> revenueBreakdown;
  final List<CategoryShareDto> expenseBreakdown;

  factory ProfitAndLossReportDto.fromJson(Map<String, dynamic> json) {
    final revRaw = json['revenueBreakdown'] as List<dynamic>? ?? const [];
    final expRaw = json['expenseBreakdown'] as List<dynamic>? ?? const [];
    return ProfitAndLossReportDto(
      period: (json['period'] ?? '').toString(),
      startDate: (json['startDate'] ?? '').toString(),
      endDate: (json['endDate'] ?? '').toString(),
      currency: (json['currency'] ?? 'USD').toString().toUpperCase(),
      totalRevenue: MoneyFormatter.parseDecimal(json['totalRevenue']),
      totalExpenses: MoneyFormatter.parseDecimal(json['totalExpenses']),
      grossProfit: MoneyFormatter.parseDecimal(json['grossProfit']),
      netOperatingIncome: MoneyFormatter.parseDecimal(
        json['netOperatingIncome'],
      ),
      profitMarginPct: (json['profitMarginPct'] as num?)?.toDouble() ?? 0.0,
      revenueBreakdown: revRaw
          .whereType<Map<String, dynamic>>()
          .map(CategoryShareDto.fromJson)
          .toList(),
      expenseBreakdown: expRaw
          .whereType<Map<String, dynamic>>()
          .map(CategoryShareDto.fromJson)
          .toList(),
    );
  }
}

@immutable
class MonthlyCashFlowDto {
  const MonthlyCashFlowDto({
    required this.month,
    required this.inflow,
    required this.outflow,
    required this.net,
  });

  final String month; // YYYY-MM
  final Decimal inflow;
  final Decimal outflow;
  final Decimal net;

  factory MonthlyCashFlowDto.fromJson(Map<String, dynamic> json) {
    return MonthlyCashFlowDto(
      month: (json['month'] ?? '').toString(),
      inflow: MoneyFormatter.parseDecimal(json['inflow']),
      outflow: MoneyFormatter.parseDecimal(json['outflow']),
      net: MoneyFormatter.parseDecimal(json['net']),
    );
  }
}

@immutable
class CashFlowReportDto {
  const CashFlowReportDto({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.currency,
    required this.cashInflow,
    required this.cashOutflow,
    required this.netCashChange,
    this.monthlyTrend = const [],
  });

  final String period;
  final String startDate;
  final String endDate;
  final String currency;
  final Decimal cashInflow;
  final Decimal cashOutflow;
  final Decimal netCashChange;
  final List<MonthlyCashFlowDto> monthlyTrend;

  factory CashFlowReportDto.fromJson(Map<String, dynamic> json) {
    final raw = json['monthlyTrend'] as List<dynamic>? ?? const [];
    return CashFlowReportDto(
      period: (json['period'] ?? '').toString(),
      startDate: (json['startDate'] ?? '').toString(),
      endDate: (json['endDate'] ?? '').toString(),
      currency: (json['currency'] ?? 'USD').toString().toUpperCase(),
      cashInflow: MoneyFormatter.parseDecimal(json['cashInflow']),
      cashOutflow: MoneyFormatter.parseDecimal(json['cashOutflow']),
      netCashChange: MoneyFormatter.parseDecimal(json['netCashChange']),
      monthlyTrend: raw
          .whereType<Map<String, dynamic>>()
          .map(MonthlyCashFlowDto.fromJson)
          .toList(),
    );
  }
}

@immutable
class ComparisonReportDto {
  const ComparisonReportDto({
    required this.currency,
    required this.primaryPeriodLabel,
    required this.primaryRevenue,
    required this.primaryExpenses,
    required this.primaryNetIncome,
    required this.comparisonPeriodLabel,
    required this.comparisonRevenue,
    required this.comparisonExpenses,
    required this.comparisonNetIncome,
    required this.revenueDifference,
    required this.revenueDifferencePct,
    required this.expensesDifference,
    required this.expensesDifferencePct,
    required this.netIncomeDifference,
    required this.netIncomeDifferencePct,
  });

  final String currency;
  final String primaryPeriodLabel;
  final Decimal primaryRevenue;
  final Decimal primaryExpenses;
  final Decimal primaryNetIncome;
  final String comparisonPeriodLabel;
  final Decimal comparisonRevenue;
  final Decimal comparisonExpenses;
  final Decimal comparisonNetIncome;
  final Decimal revenueDifference;
  final double revenueDifferencePct;
  final Decimal expensesDifference;
  final double expensesDifferencePct;
  final Decimal netIncomeDifference;
  final double netIncomeDifferencePct;

  factory ComparisonReportDto.fromJson(Map<String, dynamic> json) {
    return ComparisonReportDto(
      currency: (json['currency'] ?? 'USD').toString().toUpperCase(),
      primaryPeriodLabel: (json['primaryPeriodLabel'] ?? '').toString(),
      primaryRevenue: MoneyFormatter.parseDecimal(json['primaryRevenue']),
      primaryExpenses: MoneyFormatter.parseDecimal(json['primaryExpenses']),
      primaryNetIncome: MoneyFormatter.parseDecimal(json['primaryNetIncome']),
      comparisonPeriodLabel: (json['comparisonPeriodLabel'] ?? '').toString(),
      comparisonRevenue: MoneyFormatter.parseDecimal(json['comparisonRevenue']),
      comparisonExpenses: MoneyFormatter.parseDecimal(
        json['comparisonExpenses'],
      ),
      comparisonNetIncome: MoneyFormatter.parseDecimal(
        json['comparisonNetIncome'],
      ),
      revenueDifference: MoneyFormatter.parseDecimal(json['revenueDifference']),
      revenueDifferencePct:
          (json['revenueDifferencePct'] as num?)?.toDouble() ?? 0.0,
      expensesDifference: MoneyFormatter.parseDecimal(
        json['expensesDifference'],
      ),
      expensesDifferencePct:
          (json['expensesDifferencePct'] as num?)?.toDouble() ?? 0.0,
      netIncomeDifference: MoneyFormatter.parseDecimal(
        json['netIncomeDifference'],
      ),
      netIncomeDifferencePct:
          (json['netIncomeDifferencePct'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

@immutable
class ExportedReportFile {
  const ExportedReportFile({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String filename;
  final String mimeType;
}

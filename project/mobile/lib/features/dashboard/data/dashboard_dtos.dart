import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

enum DashboardPeriod {
  weekly('weekly'),
  month('month'),
  year('year');

  const DashboardPeriod(this.apiValue);
  final String apiValue;
}

@immutable
class KpiMetricDto {
  const KpiMetricDto({
    required this.formattedValue,
    required this.change,
    required this.isPositive,
    required this.rawValue,
    required this.rawChange,
  });

  final String formattedValue;
  final String change;
  final bool isPositive;
  final Decimal rawValue;
  final Decimal rawChange;

  factory KpiMetricDto.fromJson(Map<String, dynamic> json) {
    final rawVal = json['rawValue'] != null
        ? MoneyFormatter.parseDecimal(json['rawValue'])
        : MoneyFormatter.parseDecimal(json['value']);
    return KpiMetricDto(
      formattedValue: (json['value'] ?? '0').toString(),
      change: (json['change'] ?? '0.0%').toString(),
      isPositive:
          (json['isPositive'] as bool?) ?? (json['positive'] as bool?) ?? true,
      rawValue: rawVal,
      rawChange: MoneyFormatter.parseDecimal(json['rawChange']),
    );
  }
}

@immutable
class RevenueDataPointDto {
  const RevenueDataPointDto({
    required this.month,
    required this.name,
    required this.revenue,
    required this.expenses,
  });

  final String month;
  final String name;
  final double revenue;
  final double expenses;

  factory RevenueDataPointDto.fromJson(Map<String, dynamic> json) {
    return RevenueDataPointDto(
      month: (json['month'] ?? '').toString(),
      name: (json['name'] ?? json['month'] ?? '').toString(),
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      expenses: (json['expenses'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

@immutable
class RecentTransactionItemDto {
  const RecentTransactionItemDto({
    required this.id,
    required this.name,
    required this.description,
    required this.rawAmount,
    required this.date,
    required this.type,
    required this.status,
    required this.initials,
    required this.isCredit,
  });

  final String id;
  final String name;
  final String description;
  final Decimal rawAmount;
  final String date;
  final String type;
  final String status;
  final String initials;
  final bool isCredit;

  factory RecentTransactionItemDto.fromJson(Map<String, dynamic> json) {
    final rawAmt = json['rawAmount'] != null
        ? MoneyFormatter.parseDecimal(json['rawAmount'])
        : MoneyFormatter.parseDecimal(json['amount']);
    return RecentTransactionItemDto(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['description'] ?? '').toString(),
      description: (json['description'] ?? json['name'] ?? '').toString(),
      rawAmount: rawAmt,
      date: (json['date'] ?? '').toString(),
      type: (json['type'] ?? 'EXPENSE').toString(),
      status: (json['status'] ?? 'COMPLETED').toString(),
      initials: (json['initials'] ?? 'TX').toString(),
      isCredit: (json['isCredit'] as bool?) ??
          (json['credit'] as bool?) ??
          ((json['type'] ?? '').toString().toUpperCase() == 'INCOME'),
    );
  }
}

/// Parses numeric `value` directly (fixing Web's `ExpenseCategories.tsx` `$0.00`
/// bug caused by `parseFloat("USD 500.00")`).
@immutable
class ExpenseCategorySliceDto {
  const ExpenseCategorySliceDto({
    required this.name,
    required this.numericValue,
    required this.percentage,
    required this.colorHex,
  });

  final String name;
  final Decimal numericValue;
  final double percentage;
  final String colorHex;

  factory ExpenseCategorySliceDto.fromJson(Map<String, dynamic> json) {
    final numeric = json['value'] != null
        ? MoneyFormatter.parseDecimal(json['value'])
        : MoneyFormatter.parseDecimal(json['amount']);
    return ExpenseCategorySliceDto(
      name: (json['name'] ?? 'Uncategorized').toString(),
      numericValue: numeric,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      colorHex: (json['color'] ?? '#8b5cf6').toString(),
    );
  }
}

@immutable
class ReminderItemDto {
  const ReminderItemDto({
    required this.id,
    required this.title,
    required this.date,
    required this.priority,
    required this.type,
  });

  final String id;
  final String title;
  final String date;
  final String priority;
  final String type;

  factory ReminderItemDto.fromJson(Map<String, dynamic> json) {
    return ReminderItemDto(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      priority: (json['priority'] ?? 'medium').toString(),
      type: (json['type'] ?? 'budget').toString(),
    );
  }
}

@immutable
class TopCustomerItemDto {
  const TopCustomerItemDto({
    required this.id,
    required this.name,
    required this.revenue,
    required this.avatar,
  });

  final String id;
  final String name;
  final Decimal revenue;
  final String avatar;

  factory TopCustomerItemDto.fromJson(Map<String, dynamic> json) {
    return TopCustomerItemDto(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      revenue: MoneyFormatter.parseDecimal(json['revenue']),
      avatar: (json['avatar'] ?? 'C').toString(),
    );
  }
}

@immutable
class BudgetProgressDto {
  const BudgetProgressDto({
    required this.id,
    required this.name,
    required this.budgetAmount,
    required this.currency,
    required this.categoryName,
    required this.categoryColor,
    required this.actualSpending,
    required this.remainingAmount,
    required this.overBudgetAmount,
    required this.percentageConsumed,
    required this.alertLevel,
  });

  final String id;
  final String name;
  final Decimal budgetAmount;
  final String currency;
  final String categoryName;
  final String categoryColor;
  final Decimal actualSpending;
  final Decimal remainingAmount;
  final Decimal overBudgetAmount;
  final double percentageConsumed;
  final String alertLevel;

  factory BudgetProgressDto.fromJson(Map<String, dynamic> json) {
    return BudgetProgressDto(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      budgetAmount: MoneyFormatter.parseDecimal(json['budgetAmount']),
      currency: (json['currency'] ?? 'USD').toString(),
      categoryName: (json['categoryName'] ?? 'All Expenses').toString(),
      categoryColor: (json['categoryColor'] ?? '#8b5cf6').toString(),
      actualSpending: MoneyFormatter.parseDecimal(json['actualSpending']),
      remainingAmount: MoneyFormatter.parseDecimal(json['remainingAmount']),
      overBudgetAmount: MoneyFormatter.parseDecimal(json['overBudgetAmount']),
      percentageConsumed:
          (json['percentageConsumed'] as num?)?.toDouble() ?? 0.0,
      alertLevel: (json['alertLevel'] ?? 'OK').toString(),
    );
  }
}

@immutable
class BudgetSummaryDto {
  const BudgetSummaryDto({
    required this.currency,
    required this.activeBudgetCount,
    required this.approachingCount,
    required this.overBudgetCount,
    required this.budgets,
  });

  final String currency;
  final int activeBudgetCount;
  final int approachingCount;
  final int overBudgetCount;
  final List<BudgetProgressDto> budgets;

  factory BudgetSummaryDto.fromJson(Map<String, dynamic> json) {
    final list = json['budgets'] as List<dynamic>? ?? const [];
    return BudgetSummaryDto(
      currency: (json['currency'] ?? 'USD').toString(),
      activeBudgetCount: (json['activeBudgetCount'] as num?)?.toInt() ?? 0,
      approachingCount: (json['approachingCount'] as num?)?.toInt() ?? 0,
      overBudgetCount: (json['overBudgetCount'] as num?)?.toInt() ?? 0,
      budgets: list
          .whereType<Map<String, dynamic>>()
          .map(BudgetProgressDto.fromJson)
          .toList(),
    );
  }
}

@immutable
class DashboardSummaryDto {
  const DashboardSummaryDto({
    required this.revenue,
    required this.expenses,
    required this.profit,
    required this.cashFlow,
    required this.revenueData,
    required this.transactions,
    required this.expenseCategories,
    required this.reminders,
    required this.customers,
    required this.currency,
    required this.businessName,
    this.budgets,
  });

  final KpiMetricDto revenue;
  final KpiMetricDto expenses;
  final KpiMetricDto profit;
  final KpiMetricDto cashFlow;
  final List<RevenueDataPointDto> revenueData;
  final List<RecentTransactionItemDto> transactions;
  final List<ExpenseCategorySliceDto> expenseCategories;
  final List<ReminderItemDto> reminders;
  final List<TopCustomerItemDto> customers;
  final String currency;
  final String businessName;
  final BudgetSummaryDto? budgets;

  factory DashboardSummaryDto.fromJson(Map<String, dynamic> json) {
    final kpi = (json['kpiData'] as Map?)?.cast<String, dynamic>() ?? const {};
    KpiMetricDto parseKpi(String key) {
      final raw = kpi[key];
      if (raw is Map<String, dynamic>) return KpiMetricDto.fromJson(raw);
      if (raw is Map) {
        return KpiMetricDto.fromJson(Map<String, dynamic>.from(raw));
      }
      return KpiMetricDto(
        formattedValue: '0',
        change: '0.0%',
        isPositive: true,
        rawValue: Decimal.zero,
        rawChange: Decimal.zero,
      );
    }

    List<T> parseList<T>(
      dynamic raw,
      T Function(Map<String, dynamic>) mapper,
    ) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => mapper(Map<String, dynamic>.from(e)))
          .toList();
    }

    final rawBudgets = json['budgets'];
    return DashboardSummaryDto(
      revenue: parseKpi('revenue'),
      expenses: parseKpi('expenses'),
      profit: parseKpi('profit'),
      cashFlow: parseKpi('cashFlow'),
      revenueData: parseList(json['revenueData'], RevenueDataPointDto.fromJson),
      transactions:
          parseList(json['transactions'], RecentTransactionItemDto.fromJson),
      expenseCategories: parseList(
        json['expenseCategories'],
        ExpenseCategorySliceDto.fromJson,
      ),
      reminders: parseList(json['reminders'], ReminderItemDto.fromJson),
      customers: parseList(json['customers'], TopCustomerItemDto.fromJson),
      currency: (json['currency'] as String?)?.isNotEmpty == true
          ? json['currency'].toString()
          : 'USD',
      businessName: (json['businessName'] ?? '').toString(),
      budgets: rawBudgets is Map
          ? BudgetSummaryDto.fromJson(Map<String, dynamic>.from(rawBudgets))
          : null,
    );
  }
}

@immutable
class PulseAlertDto {
  const PulseAlertDto({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.copilotPrompt,
    this.metricValue,
    this.currency,
    this.actionLabel = '',
    this.href = '/dashboard',
  });

  final String id;
  final String type;
  final String severity;
  final String title;
  final String description;
  final String copilotPrompt;
  final Decimal? metricValue;
  final String? currency;
  final String actionLabel;
  final String href;

  factory PulseAlertDto.fromJson(Map<String, dynamic> json) {
    return PulseAlertDto(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      severity: (json['severity'] ?? 'INFO').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      copilotPrompt: (json['copilotPrompt'] ?? '').toString(),
      metricValue: json['metricValue'] != null
          ? MoneyFormatter.parseDecimal(json['metricValue'])
          : null,
      currency: json['currency']?.toString(),
      actionLabel: (json['actionLabel'] ?? '').toString(),
      href: (json['href'] ?? '/dashboard').toString(),
    );
  }
}

@immutable
class AiPulseDto {
  const AiPulseDto({
    required this.currency,
    required this.alerts,
    this.generatedAt,
    this.highCount = 0,
    this.mediumCount = 0,
    this.infoCount = 0,
    this.monthRevenue,
    this.monthExpenses,
    this.monthNetProfit,
    this.overdueTotal,
    this.overdueCount = 0,
    this.missingReceiptCount = 0,
  });

  final String currency;
  final List<PulseAlertDto> alerts;
  final DateTime? generatedAt;
  final int highCount;
  final int mediumCount;
  final int infoCount;
  final Decimal? monthRevenue;
  final Decimal? monthExpenses;
  final Decimal? monthNetProfit;
  final Decimal? overdueTotal;
  final int overdueCount;
  final int missingReceiptCount;

  Decimal get safeMonthRevenue => monthRevenue ?? Decimal.zero;
  Decimal get safeMonthExpenses => monthExpenses ?? Decimal.zero;
  Decimal get safeMonthNetProfit => monthNetProfit ?? Decimal.zero;
  Decimal get safeOverdueTotal => overdueTotal ?? Decimal.zero;

  factory AiPulseDto.fromJson(Map<String, dynamic> json) {
    final rawAlerts = json['alerts'] as List<dynamic>? ?? const [];
    return AiPulseDto(
      currency: (json['currency'] ?? 'USD').toString(),
      generatedAt: DateTime.tryParse((json['generatedAt'] ?? '').toString()),
      highCount: (json['highCount'] as num?)?.toInt() ?? 0,
      mediumCount: (json['mediumCount'] as num?)?.toInt() ?? 0,
      infoCount: (json['infoCount'] as num?)?.toInt() ?? 0,
      monthRevenue: json['monthRevenue'] != null
          ? MoneyFormatter.parseDecimal(json['monthRevenue'])
          : null,
      monthExpenses: json['monthExpenses'] != null
          ? MoneyFormatter.parseDecimal(json['monthExpenses'])
          : null,
      monthNetProfit: json['monthNetProfit'] != null
          ? MoneyFormatter.parseDecimal(json['monthNetProfit'])
          : null,
      overdueTotal: json['overdueTotal'] != null
          ? MoneyFormatter.parseDecimal(json['overdueTotal'])
          : null,
      overdueCount: (json['overdueCount'] as num?)?.toInt() ?? 0,
      missingReceiptCount: (json['missingReceiptCount'] as num?)?.toInt() ?? 0,
      alerts: rawAlerts
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => PulseAlertDto.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

@immutable
class SubscriptionSnapshotDto {
  const SubscriptionSnapshotDto({
    this.planId,
    required this.planSlug,
    required this.planName,
    this.priceMonthly,
    this.priceYearly,
    this.currency = 'USD',
    required this.status,
    required this.isTrial,
    this.trialDaysRemaining,
    this.periodStart,
    this.periodEnd,
    this.trialStart,
    this.trialEnd,
    this.billingInterval = 'monthly',
    this.cancelAtPeriodEnd = false,
    this.canceledAt,
    this.effectiveCancelAt,
    this.pendingPlanSlug,
    this.pendingPlanName,
    this.pendingBillingInterval,
    this.pendingChangeEffectiveAt,
    this.firstPaymentFailureAt,
    this.gracePeriodEndsAt,
    this.gracePeriodHoursRemaining,
    this.lastPaymentFailureReason,
    this.trialUsed = false,
    this.trialEligible = false,
    required this.allocationAttentionRequired,
    required this.editableBusinessLimit,
    required this.editableBusinessCount,
    required this.totalBusinessCount,
    this.hasStripeCustomer = false,
    this.hasActiveStripeSubscription = false,
    this.stripeConfigured = false,
    this.entitlements = const {},
    this.usage = const {},
  });

  final String? planId;
  final String planSlug;
  final String planName;
  final Decimal? priceMonthly;
  final Decimal? priceYearly;
  final String currency;
  final String status;
  final bool isTrial;
  final int? trialDaysRemaining;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final DateTime? trialStart;
  final DateTime? trialEnd;
  final String billingInterval;
  final bool cancelAtPeriodEnd;
  final DateTime? canceledAt;
  final DateTime? effectiveCancelAt;
  final String? pendingPlanSlug;
  final String? pendingPlanName;
  final String? pendingBillingInterval;
  final DateTime? pendingChangeEffectiveAt;
  final DateTime? firstPaymentFailureAt;
  final DateTime? gracePeriodEndsAt;
  final int? gracePeriodHoursRemaining;
  final String? lastPaymentFailureReason;
  final bool trialUsed;
  final bool trialEligible;
  final bool allocationAttentionRequired;
  final int editableBusinessLimit;
  final int editableBusinessCount;
  final int totalBusinessCount;
  final bool hasStripeCustomer;
  final bool hasActiveStripeSubscription;
  final bool stripeConfigured;
  final Map<String, dynamic> entitlements;
  final Map<String, int> usage;

  bool get isPastDue => status.toUpperCase() == 'PAST_DUE';
  bool get isPro => planSlug.toLowerCase() == 'pro';
  bool get isPlus => planSlug.toLowerCase() == 'plus';
  bool get isFree => planSlug.toLowerCase() == 'free';

  bool get isTrialActive =>
      isTrial || status.toUpperCase() == 'TRIALING';

  bool get isPlusTrialEligible =>
      trialEligible || (!trialUsed && !hasActiveStripeSubscription);

  bool get hasActivePaidSubscription {
    final s = status.toUpperCase();
    return (isPlus || isPro) &&
        (s == 'ACTIVE' || s == 'TRIALING' || s == 'PAST_DUE');
  }

  bool get hasPendingChange =>
      cancelAtPeriodEnd ||
      (pendingPlanSlug != null && pendingPlanSlug!.isNotEmpty);

  DateTime? get effectiveEndDate =>
      effectiveCancelAt ?? pendingChangeEffectiveAt ?? periodEnd ?? trialEnd;

  String get reportsLevel =>
      (entitlements['reports.level'] ?? 'basic').toString().toLowerCase();

  int get monthlyExportLimit =>
      (entitlements['export.per_month'] as num?)?.toInt() ?? 5;

  int get monthlyExportUsed => usage['export.per_month'] ?? 0;

  int get aiTokensLimit =>
      (entitlements['ai.chat.tokens_per_month'] as num?)?.toInt() ?? 10000;

  int get aiTokensUsed => usage['ai.chat.tokens_per_month'] ?? 0;

  int get aiQueriesLimit =>
      (entitlements['ai.chat.queries_per_month'] as num?)?.toInt() ?? 20;

  int get aiQueriesUsed => usage['ai.chat.queries_per_month'] ?? 0;

  factory SubscriptionSnapshotDto.fromJson(Map<String, dynamic> json) {
    final rawEnt = json['entitlements'];
    final rawUsage = json['usage'];
    final parsedUsage = <String, int>{};
    if (rawUsage is Map) {
      for (final entry in rawUsage.entries) {
        final v = entry.value;
        if (v is num) parsedUsage[entry.key.toString()] = v.toInt();
      }
    }
    DateTime? parseDt(dynamic v) =>
        v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;

    return SubscriptionSnapshotDto(
      planId: json['planId']?.toString(),
      planSlug: (json['planSlug'] ?? 'free').toString().toLowerCase(),
      planName: (json['planName'] ?? 'Free').toString(),
      priceMonthly: json['priceMonthly'] != null
          ? MoneyFormatter.parseDecimal(json['priceMonthly'])
          : null,
      priceYearly: json['priceYearly'] != null
          ? MoneyFormatter.parseDecimal(json['priceYearly'])
          : null,
      currency: (json['currency'] as String?)?.isNotEmpty == true
          ? json['currency'].toString().toUpperCase()
          : 'USD',
      status: (json['status'] ?? 'ACTIVE').toString(),
      isTrial: (json['trial'] as bool?) ?? (json['isTrial'] as bool?) ?? false,
      trialDaysRemaining: (json['trialDaysRemaining'] as num?)?.toInt(),
      periodStart: parseDt(json['periodStart']),
      periodEnd: parseDt(json['periodEnd']),
      trialStart: parseDt(json['trialStart']),
      trialEnd: parseDt(json['trialEnd']),
      billingInterval:
          (json['billingInterval'] as String?)?.toLowerCase() == 'yearly'
              ? 'yearly'
              : 'monthly',
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] as bool? ?? false,
      canceledAt: parseDt(json['canceledAt']),
      effectiveCancelAt: parseDt(json['effectiveCancelAt']),
      pendingPlanSlug: json['pendingPlanSlug']?.toString().toLowerCase(),
      pendingPlanName: json['pendingPlanName']?.toString(),
      pendingBillingInterval: json['pendingBillingInterval']?.toString(),
      pendingChangeEffectiveAt: parseDt(json['pendingChangeEffectiveAt']),
      firstPaymentFailureAt: parseDt(json['firstPaymentFailureAt']),
      gracePeriodEndsAt: parseDt(json['gracePeriodEndsAt']),
      gracePeriodHoursRemaining:
          (json['gracePeriodHoursRemaining'] as num?)?.toInt(),
      lastPaymentFailureReason: json['lastPaymentFailureReason']?.toString(),
      trialUsed: json['trialUsed'] as bool? ?? false,
      trialEligible: json['trialEligible'] as bool? ?? false,
      allocationAttentionRequired:
          json['allocationAttentionRequired'] as bool? ?? false,
      editableBusinessLimit:
          (json['editableBusinessLimit'] as num?)?.toInt() ?? 1,
      editableBusinessCount:
          (json['editableBusinessCount'] as num?)?.toInt() ?? 1,
      totalBusinessCount: (json['totalBusinessCount'] as num?)?.toInt() ?? 1,
      hasStripeCustomer: json['hasStripeCustomer'] as bool? ?? false,
      hasActiveStripeSubscription:
          json['hasActiveStripeSubscription'] as bool? ?? false,
      stripeConfigured: json['stripeConfigured'] as bool? ?? false,
      entitlements: rawEnt is Map
          ? Map<String, dynamic>.from(rawEnt)
          : const {},
      usage: parsedUsage,
    );
  }
}

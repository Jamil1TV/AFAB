import 'dart:math' as math;

import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/navigation/copilot_prompt_request.dart';
import 'package:afab_mobile/core/network/global_events.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/app_states/plan_limit_sheet.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:afab_mobile/features/reports/data/report_dtos.dart';
import 'package:afab_mobile/features/reports/data/reports_repository.dart';
import 'package:afab_mobile/features/reports/domain/reports_providers.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/afab_kpi_card.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:afab_mobile/shared/widgets/afab_segmented_bar.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:afab_mobile/shared/widgets/analytics_charts.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `INT-03`: Financial Reports (P&L, Cash Flow, Period Comparison),
/// Pro custom date range, export quota pill, Explain Report Copilot action,
/// and native RFC 4180 CSV / OpenPDF sharing.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _exportingCsv = false;
  bool _exportingPdf = false;

  Future<void> _pickCustomDateRange() async {
    final filter = ref.read(reportsFilterProvider);
    final initialStart = (filter.customStart != null
            ? DateTime.tryParse(filter.customStart!)
            : null) ??
        DateTime.now().subtract(const Duration(days: 30));
    final initialEnd = (filter.customEnd != null
            ? DateTime.tryParse(filter.customEnd!)
            : null) ??
        DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );
    if (picked != null && mounted) {
      final fmt = DateFormat('yyyy-MM-dd', 'en_US');
      ref.read(reportsFilterProvider.notifier).setCustomRange(
            fmt.format(picked.start),
            fmt.format(picked.end),
          );
    }
  }

  Future<void> _runExport({required bool isPdf}) async {
    final filter = ref.read(reportsFilterProvider);
    final snap = ref.read(subscriptionSnapshotProvider).value;
    if (snap != null &&
        snap.monthlyExportLimit != -1 &&
        snap.monthlyExportUsed >= snap.monthlyExportLimit) {
      await showPlanLimitSheet(
        context,
        PlanLimitReachedEvent(
          feature: 'export.per_month',
          limit: snap.monthlyExportLimit,
          used: snap.monthlyExportUsed,
          upgradeTo: snap.isFree ? 'plus' : 'pro',
          message: 'Monthly export limit reached.',
        ),
      );
      return;
    }

    setState(() {
      if (isPdf) {
        _exportingPdf = true;
      } else {
        _exportingCsv = true;
      }
    });

    try {
      final repo = ref.read(reportsRepositoryProvider);
      final file = isPdf
          ? await repo.exportPdf(
              period: filter.period,
              startDate: filter.customStart,
              endDate: filter.customEnd,
            )
          : await repo.exportCsv(
              period: filter.period,
              startDate: filter.customStart,
              endDate: filter.customEnd,
            );
      await repo.saveAndShareExport(file);
      ref.invalidate(subscriptionSnapshotProvider);
    } on PlanLimitReachedFailure catch (e) {
      if (!mounted) return;
      await showPlanLimitSheet(
        context,
        PlanLimitReachedEvent(
          feature: e.feature,
          limit: e.limit,
          used: e.used,
          upgradeTo: e.upgradeTo,
          message: e.message,
        ),
      );
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    } catch (e) {
      if (mounted) {
        AfabToast.showError(
          context,
          '${context.l10n.errorGenericTitle}: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _exportingCsv = false;
          _exportingPdf = false;
        });
      }
    }
  }

  void _explainReport(ReportsFilterState filter) {
    context.go(
      '/copilot',
      extra: CopilotPromptRequest(
        prompt:
            'Analyze my ${filter.tab.name} financial report for period "${filter.period}"'
            '${filter.tab == ReportsTab.comparison ? ' compared against "${filter.comparisonPeriod}"' : ''}'
            ' and explain key drivers, margins, and recommendations.',
        autoSend: true,
        screenContext: {
          'page': 'reports',
          'tab': filter.tab.name,
          'period': filter.period,
          if (filter.tab == ReportsTab.comparison)
            'comparisonPeriod': filter.comparisonPeriod,
          'startDate': ?filter.customStart,
          'endDate': ?filter.customEnd,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final locale = Localizations.localeOf(context).languageCode;
    final biz = ref.watch(activeBusinessProvider);
    final fallbackCurr = biz?.currency ?? 'USD';

    final filter = ref.watch(reportsFilterProvider);
    final snapAsync = ref.watch(subscriptionSnapshotProvider);
    final snap = snapAsync.value;
    final reportsLevel = snap?.reportsLevel ?? 'basic';
    final exportLimit = snap?.monthlyExportLimit ?? 5;
    final exportUsed = snap?.monthlyExportUsed ?? 0;

    final pnlAsync = filter.tab == ReportsTab.pnl
        ? ref.watch(pnlReportProvider)
        : null;
    final cfAsync = filter.tab == ReportsTab.cashflow
        ? ref.watch(cashFlowReportProvider)
        : null;
    final compAsync = filter.tab == ReportsTab.comparison
        ? ref.watch(comparisonReportProvider)
        : null;

    final isPlanGated = (pnlAsync?.value is ReportPlanGated) ||
        (cfAsync?.value is ReportPlanGated) ||
        (compAsync?.value is ReportPlanGated);

    final periodOptions = <(String value, String label)>[
      ('this_month', l10n.reportsPeriodThisMonth),
      ('last_month', l10n.reportsPeriodLastMonth),
      ('this_quarter', l10n.reportsPeriodThisQuarter),
      ('this_year', l10n.reportsPeriodThisYear),
      ('last_year', l10n.reportsPeriodLastYear),
      if (filter.tab != ReportsTab.comparison)
        ('custom', l10n.reportsPeriodCustom),
    ];

    final effectivePeriod = filter.tab == ReportsTab.comparison &&
            filter.period == 'custom'
        ? 'this_month'
        : filter.period;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isExpanded = AfabBreakpoints.isExpandedTablet(width);
          final pnlKpiCols = width >= 1024
              ? 4
              : AfabBreakpoints.kpiColumnsForWidth(width);
          final cfKpiCols = width >= 900 ? 3 : AfabBreakpoints.kpiColumnsForWidth(width);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(pnlReportProvider);
              ref.invalidate(cashFlowReportProvider);
              ref.invalidate(comparisonReportProvider);
              ref.invalidate(subscriptionSnapshotProvider);
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                isExpanded ? 24 : 16,
                16,
                isExpanded ? 24 : 16,
                40,
              ),
              children: [
                // Header & Quota Pill + Action Row
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.reportsTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.reportsSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceInset,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.sparkles,
                            size: 15,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            exportLimit == -1
                                ? l10n.reportsMonthlyUnlimited
                                : l10n.reportsMonthlyQuota(
                                    exportUsed,
                                    exportLimit,
                                  ),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AfabButton(
                      label: l10n.reportsExplainBtn,
                      icon: LucideIcons.sparkles,
                      variant: AfabButtonVariant.secondary,
                      compact: true,
                      onPressed: () => _explainReport(filter),
                    ),
                    AfabButton(
                      label: l10n.reportsExportCsvBtn,
                      icon: LucideIcons.download,
                      variant: AfabButtonVariant.secondary,
                      compact: true,
                      isLoading: _exportingCsv,
                      onPressed: (isPlanGated || _exportingCsv)
                          ? null
                          : () => _runExport(isPdf: false),
                    ),
                    AfabButton(
                      label: l10n.reportsExportPdfBtn,
                      icon: LucideIcons.fileDown,
                      compact: true,
                      isLoading: _exportingPdf,
                      onPressed: (isPlanGated || _exportingPdf)
                          ? null
                          : () => _runExport(isPdf: true),
                    ),
                  ],
                ),

                if (locale == 'ar') ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.infoBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colors.info.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.info, size: 16, color: colors.info),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.reportsArabicPdfWarning,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // 3 Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: AfabSegmentedBar<ReportsTab>(
                    items: [
                      AfabSegmentItem(
                        value: ReportsTab.pnl,
                        label: l10n.reportsTabPnl,
                      ),
                      AfabSegmentItem(
                        value: ReportsTab.cashflow,
                        label: l10n.reportsTabCashFlow,
                      ),
                      AfabSegmentItem(
                        value: ReportsTab.comparison,
                        label: l10n.reportsTabComparison,
                      ),
                    ],
                    selectedValue: filter.tab,
                    onSelected: (t) =>
                        ref.read(reportsFilterProvider.notifier).setTab(t),
                  ),
                ),
                const SizedBox(height: 12),

                // Period Selectors
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: filter.tab == ReportsTab.comparison && width >= 520
                          ? 220
                          : double.infinity,
                      child: DropdownButtonFormField<String>(
                        initialValue: effectivePeriod,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: filter.tab == ReportsTab.comparison
                              ? l10n.reportsPrimaryPeriod
                              : null,
                          isDense: true,
                        ),
                        items: [
                          for (final opt in periodOptions)
                            DropdownMenuItem(
                              value: opt.$1,
                              child: Text(opt.$2),
                            ),
                        ],
                        onChanged: (v) async {
                          if (v == null) return;
                          if (v == 'custom' &&
                              snap != null &&
                              reportsLevel != 'custom') {
                            await showPlanLimitSheet(
                              context,
                              const PlanLimitReachedEvent(
                                feature: 'reports.level',
                                limit: 0,
                                used: 0,
                                upgradeTo: 'pro',
                                message: 'Pro plan required for custom date ranges.',
                              ),
                            );
                            return;
                          }
                          ref.read(reportsFilterProvider.notifier).setPeriod(v);
                          if (v == 'custom') {
                            await _pickCustomDateRange();
                          }
                        },
                      ),
                    ),
                    if (filter.tab == ReportsTab.comparison)
                      SizedBox(
                        width: width >= 520 ? 220 : double.infinity,
                        child: DropdownButtonFormField<String>(
                          initialValue: filter.comparisonPeriod,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: l10n.reportsCompareAgainst,
                            isDense: true,
                          ),
                          items: [
                            for (final opt in periodOptions)
                              if (opt.$1 != 'custom')
                                DropdownMenuItem(
                                  value: opt.$1,
                                  child: Text(opt.$2),
                                ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              ref
                                  .read(reportsFilterProvider.notifier)
                                  .setComparisonPeriod(v);
                            }
                          },
                        ),
                      ),
                    if (filter.period == 'custom' &&
                        filter.tab != ReportsTab.comparison)
                      ActionChip(
                        avatar: const Icon(LucideIcons.calendarRange, size: 15),
                        label: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            (filter.customStart != null &&
                                    filter.customEnd != null)
                                ? '${filter.customStart} → ${filter.customEnd}'
                                : l10n.reportsSelectDateRange,
                          ),
                        ),
                        onPressed: _pickCustomDateRange,
                      ),
                  ],
                ),
                if (filter.tab == ReportsTab.comparison &&
                    effectivePeriod == filter.comparisonPeriod) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n.reportsIdenticalPeriodsHint,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colors.warning),
                  ),
                ],
                const SizedBox(height: 16),

                // Tab Content
                if (filter.tab == ReportsTab.pnl)
                  pnlAsync!.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: AfabLoader(size: 52),
                      ),
                    ),
                    error: (err, _) => AfabErrorState(
                      title: l10n.errorGenericTitle,
                      message: err.toString(),
                      retryLabel: l10n.commonRetry,
                      onRetry: () => ref.invalidate(pnlReportProvider),
                    ),
                    data: (res) => switch (res) {
                      ReportPlanGated<ProfitAndLossReportDto>(:final failure) =>
                        _PlanGatedCard(message: failure.message),
                      ReportLoaded<ProfitAndLossReportDto>(:final data) =>
                        _buildPnlBody(
                          context,
                          report: data,
                          fallbackCurrency: fallbackCurr,
                          kpiCols: pnlKpiCols,
                          isExpanded: isExpanded,
                        ),
                    },
                  )
                else if (filter.tab == ReportsTab.cashflow)
                  cfAsync!.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: AfabLoader(size: 52),
                      ),
                    ),
                    error: (err, _) => AfabErrorState(
                      title: l10n.errorGenericTitle,
                      message: err.toString(),
                      retryLabel: l10n.commonRetry,
                      onRetry: () => ref.invalidate(cashFlowReportProvider),
                    ),
                    data: (res) => switch (res) {
                      ReportPlanGated<CashFlowReportDto>(:final failure) =>
                        _PlanGatedCard(message: failure.message),
                      ReportLoaded<CashFlowReportDto>(:final data) =>
                        _buildCashFlowBody(
                          context,
                          report: data,
                          fallbackCurrency: fallbackCurr,
                          kpiCols: cfKpiCols,
                        ),
                    },
                  )
                else
                  compAsync!.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: AfabLoader(size: 52),
                      ),
                    ),
                    error: (err, _) => AfabErrorState(
                      title: l10n.errorGenericTitle,
                      message: err.toString(),
                      retryLabel: l10n.commonRetry,
                      onRetry: () => ref.invalidate(comparisonReportProvider),
                    ),
                    data: (res) => switch (res) {
                      ReportPlanGated<ComparisonReportDto>(:final failure) =>
                        _PlanGatedCard(message: failure.message),
                      ReportLoaded<ComparisonReportDto>(:final data) =>
                        _buildComparisonBody(
                          context,
                          report: data,
                          fallbackCurrency: fallbackCurr,
                          kpiCols: cfKpiCols,
                        ),
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPnlBody(
    BuildContext context, {
    required ProfitAndLossReportDto report,
    required String fallbackCurrency,
    required int kpiCols,
    required bool isExpanded,
  }) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final curr = report.currency.isNotEmpty ? report.currency : fallbackCurrency;
    final marginPositive = report.profitMarginPct >= 0;

    final revCard = _CategoryShareListCard(
      title: l10n.reportsPnlRevByCategory,
      total: report.totalRevenue,
      currency: curr,
      items: report.revenueBreakdown,
      emptyText: l10n.reportsPnlNoIncome,
      barColor: colors.success,
    );
    final expCard = _CategoryShareListCard(
      title: l10n.reportsPnlExpByCategory,
      total: report.totalExpenses,
      currency: curr,
      items: report.expenseBreakdown,
      emptyText: l10n.reportsPnlNoExpenses,
      barColor: colors.primary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AfabKpiWrapGrid(
          columns: kpiCols,
          children: [
            AfabKpiCard(
              title: l10n.reportsPnlRevenue,
              amount: report.totalRevenue,
              currency: curr,
              changeText: report.period,
              isPositive: true,
              periodComparisonLabel: l10n.reportsPnlCashReceived,
              icon: LucideIcons.trendingUp,
              topAccentColor: colors.success,
            ),
            AfabKpiCard(
              title: l10n.reportsPnlExpenses,
              amount: report.totalExpenses,
              currency: curr,
              changeText: report.period,
              isPositive: false,
              periodComparisonLabel: l10n.reportsPnlCashSpent,
              icon: LucideIcons.trendingDown,
              topAccentColor: colors.danger,
            ),
            AfabKpiCard(
              title: l10n.reportsPnlNetIncome,
              amount: report.netOperatingIncome,
              currency: curr,
              changeText: '${report.profitMarginPct.toStringAsFixed(1)}%',
              isPositive: report.netOperatingIncome >= Decimal.zero,
              periodComparisonLabel: report.period,
              icon: LucideIcons.wallet,
              topAccentColor: colors.primary,
            ),
            _MarginKpiCard(
              title: l10n.reportsPnlMargin,
              marginPct: report.profitMarginPct,
              subtitle: marginPositive
                  ? l10n.reportsPnlPositiveMargin
                  : l10n.reportsPnlDeficit,
              positive: marginPositive,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isExpanded)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: revCard),
              const SizedBox(width: 14),
              Expanded(child: expCard),
            ],
          )
        else ...[
          revCard,
          const SizedBox(height: 14),
          expCard,
        ],
      ],
    );
  }

  Widget _buildCashFlowBody(
    BuildContext context, {
    required CashFlowReportDto report,
    required String fallbackCurrency,
    required int kpiCols,
  }) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final curr = report.currency.isNotEmpty ? report.currency : fallbackCurrency;
    final trend = report.monthlyTrend;
    final hasAnyFlow = trend.any(
      (m) => m.inflow > Decimal.zero || m.outflow > Decimal.zero,
    );

    var maxY = 100.0;
    for (final m in trend) {
      maxY = math.max(maxY, math.max(m.inflow.toDouble(), m.outflow.toDouble()));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AfabKpiWrapGrid(
          columns: kpiCols,
          children: [
            AfabKpiCard(
              title: l10n.reportsCfInflow,
              amount: report.cashInflow,
              currency: curr,
              changeText: report.period,
              isPositive: true,
              periodComparisonLabel: l10n.reportsPnlCashReceived,
              icon: LucideIcons.arrowUpRight,
              topAccentColor: colors.success,
            ),
            AfabKpiCard(
              title: l10n.reportsCfOutflow,
              amount: report.cashOutflow,
              currency: curr,
              changeText: report.period,
              isPositive: false,
              periodComparisonLabel: l10n.reportsPnlCashSpent,
              icon: LucideIcons.arrowDownLeft,
              topAccentColor: colors.danger,
            ),
            AfabKpiCard(
              title: l10n.reportsCfNetChange,
              amount: report.netCashChange,
              currency: curr,
              changeText: report.period,
              isPositive: report.netCashChange >= Decimal.zero,
              periodComparisonLabel: l10n.dashboardCashFlow,
              icon: LucideIcons.activity,
              topAccentColor: colors.primary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        AfabCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(
                    l10n.reportsCfTrendTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Wrap(
                    spacing: 12,
                    children: [
                      _LegendDotLabel(
                        color: colors.success,
                        label: l10n.dashboardRevenueLabel,
                      ),
                      _LegendDotLabel(
                        color: colors.danger,
                        label: l10n.dashboardExpensesLabel,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (!hasAnyFlow)
                AfabEmptyState(
                  icon: LucideIcons.chartBar,
                  title: l10n.commonNoData,
                  description: l10n.reportsCfTrendEmpty,
                )
              else
                SizedBox(
                  height: 240,
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: BarChart(
                      BarChartData(
                        maxY: maxY * 1.18,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: colors.border,
                            strokeWidth: 1,
                            dashArray: const [4, 4],
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, _) {
                                final idx = val.toInt();
                                if (idx < 0 || idx >= trend.length) {
                                  return const SizedBox.shrink();
                                }
                                final raw = trend[idx].month;
                                final short = raw.length >= 7
                                    ? raw.substring(2, 7)
                                    : raw;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    short,
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < trend.length; i++)
                            BarChartGroupData(
                              x: i,
                              barsSpace: 4,
                              barRods: [
                                BarChartRodData(
                                  toY: trend[i].inflow.toDouble(),
                                  color: colors.success,
                                  width: 12,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(5),
                                  ),
                                ),
                                BarChartRodData(
                                  toY: trend[i].outflow.toDouble(),
                                  color: colors.danger,
                                  width: 12,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(5),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonBody(
    BuildContext context, {
    required ComparisonReportDto report,
    required String fallbackCurrency,
    required int kpiCols,
  }) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final curr = report.currency.isNotEmpty ? report.currency : fallbackCurrency;

    return AfabCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              '${report.primaryPeriodLabel} vs ${report.comparisonPeriodLabel}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 14),
          AfabKpiWrapGrid(
            columns: kpiCols,
            children: [
              _ComparisonVarianceTile(
                title: l10n.reportsCompRevGrowth,
                primaryAmount: report.primaryRevenue,
                comparisonLabel: report.comparisonPeriodLabel,
                comparisonAmount: report.comparisonRevenue,
                diffAmount: report.revenueDifference,
                diffPct: report.revenueDifferencePct,
                currency: curr,
                favorable: report.revenueDifferencePct >= 0,
                colors: colors,
              ),
              _ComparisonVarianceTile(
                title: l10n.reportsCompExpChange,
                primaryAmount: report.primaryExpenses,
                comparisonLabel: report.comparisonPeriodLabel,
                comparisonAmount: report.comparisonExpenses,
                diffAmount: report.expensesDifference,
                diffPct: report.expensesDifferencePct,
                currency: curr,
                // Lower expenses compared to prior period is favorable.
                favorable: report.expensesDifferencePct <= 0,
                colors: colors,
              ),
              _ComparisonVarianceTile(
                title: l10n.reportsCompNetChange,
                primaryAmount: report.primaryNetIncome,
                comparisonLabel: report.comparisonPeriodLabel,
                comparisonAmount: report.comparisonNetIncome,
                diffAmount: report.netIncomeDifference,
                diffPct: report.netIncomeDifferencePct,
                currency: curr,
                favorable: report.netIncomeDifferencePct >= 0,
                colors: colors,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanGatedCard extends StatelessWidget {
  const _PlanGatedCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    return AfabCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.warningBg,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.lock, color: colors.warning, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.reportsGatedTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          AfabButton(
            label: l10n.reportsGatedBtn,
            icon: LucideIcons.sparkles,
            variant: AfabButtonVariant.premium,
            onPressed: () => context.go('/plans'),
          ),
        ],
      ),
    );
  }
}

class _MarginKpiCard extends StatelessWidget {
  const _MarginKpiCard({
    required this.title,
    required this.marginPct,
    required this.subtitle,
    required this.positive,
  });

  final String title;
  final double marginPct;
  final String subtitle;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    final tint = positive ? colors.success : colors.danger;
    return AfabCard(
      topAccentColor: tint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.surfaceInset,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            child: Icon(LucideIcons.percent, size: 17, color: tint),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              '${marginPct.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tint,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CategoryShareListCard extends StatelessWidget {
  const _CategoryShareListCard({
    required this.title,
    required this.total,
    required this.currency,
    required this.items,
    required this.emptyText,
    required this.barColor,
  });

  final String title;
  final Decimal total;
  final String currency;
  final List<CategoryShareDto> items;
  final String emptyText;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    return AfabCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 8),
              MoneyText(
                amount: total,
                currency: currency,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            AfabEmptyState(
              icon: LucideIcons.layers,
              title: context.l10n.commonNoData,
              description: emptyText,
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      items[i].categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  MoneyText(
                    amount: items[i].amount,
                    currency: currency,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(width: 6),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '(${items[i].percentage.toStringAsFixed(1)}%)',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (items[i].percentage / 100.0).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: colors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
              if (i < items.length - 1) const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _ComparisonVarianceTile extends StatelessWidget {
  const _ComparisonVarianceTile({
    required this.title,
    required this.primaryAmount,
    required this.comparisonLabel,
    required this.comparisonAmount,
    required this.diffAmount,
    required this.diffPct,
    required this.currency,
    required this.favorable,
    required this.colors,
  });

  final String title;
  final Decimal primaryAmount;
  final String comparisonLabel;
  final Decimal comparisonAmount;
  final Decimal diffAmount;
  final double diffPct;
  final String currency;
  final bool favorable;
  final AfabColors colors;

  @override
  Widget build(BuildContext context) {
    return AfabInsetPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: MoneyText(
              amount: primaryAmount,
              currency: currency,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: AfabStatusBadge(
                  label:
                      '${diffPct >= 0 ? '+' : ''}${diffPct.toStringAsFixed(1)}%',
                  variant: favorable
                      ? AfabBadgeVariant.success
                      : AfabBadgeVariant.danger,
                ),
              ),
              MoneyText(
                amount: diffAmount,
                currency: currency,
                showSign: true,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '$comparisonLabel:',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              MoneyText(
                amount: comparisonAmount,
                currency: currency,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDotLabel extends StatelessWidget {
  const _LegendDotLabel({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/ai/domain/ai_providers.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:afab_mobile/features/dashboard/presentation/widgets/ai_insights_card.dart';
import 'package:afab_mobile/features/dashboard/presentation/widgets/expense_categories_card.dart';
import 'package:afab_mobile/features/dashboard/presentation/widgets/recent_transactions_card.dart';
import 'package:afab_mobile/features/dashboard/presentation/widgets/reminder_card.dart';
import 'package:afab_mobile/features/dashboard/presentation/widgets/revenue_area_chart.dart';
import 'package:afab_mobile/features/dashboard/presentation/widgets/top_customers_card.dart';
import 'package:afab_mobile/features/dashboard/presentation/widgets/upgrade_banner.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/afab_kpi_card.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:afab_mobile/shared/widgets/afab_segmented_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `DASH-01`: Financial Dashboard Home.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _greeting(BuildContext context, String name) {
    final l10n = context.l10n;
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.dashboardGoodMorning(name);
    if (hour < 18) return l10n.dashboardGoodAfternoon(name);
    return l10n.dashboardGoodEvening(name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final session = ref.watch(authNotifierProvider);
    final period = ref.watch(dashboardPeriodProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final pulseAsync = ref.watch(aiPulseProvider);
    final subAsync = ref.watch(subscriptionSnapshotProvider);

    final firstName = session.user?.firstName.trim().isNotEmpty == true
        ? session.user!.firstName.trim()
        : 'Owner';

    final periodLabel = switch (period) {
      DashboardPeriod.weekly => l10n.periodVsLastWeek,
      DashboardPeriod.month => l10n.periodVsLastMonth,
      DashboardPeriod.year => l10n.periodVsLastYear,
    };

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardSummaryProvider);
        ref.invalidate(aiPulseProvider);
        ref.invalidate(subscriptionSnapshotProvider);
        await ref.read(dashboardSummaryProvider.future);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isTabletSplit = AfabBreakpoints.isExpandedTablet(width);
          final kpiCols = AfabBreakpoints.kpiColumnsForWidth(width);

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isTabletSplit ? 24 : 16,
              vertical: 20,
            ),
            children: [
              // Welcome + Period selector
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(context, firstName),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.dashboardSubtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  AfabSegmentedBar<DashboardPeriod>(
                    items: [
                      AfabSegmentItem(
                        value: DashboardPeriod.weekly,
                        label: l10n.periodWeekly,
                      ),
                      AfabSegmentItem(
                        value: DashboardPeriod.month,
                        label: l10n.periodMonthly,
                      ),
                      AfabSegmentItem(
                        value: DashboardPeriod.year,
                        label: l10n.periodYearly,
                      ),
                    ],
                    selectedValue: period,
                    onSelected: (p) =>
                        ref.read(dashboardPeriodProvider.notifier).select(p),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              summaryAsync.when(
                loading: () => _DashboardSkeleton(kpiCols: kpiCols),
                error: (err, _) => AfabErrorState(
                  title: l10n.dashboardLoadError,
                  message: err.toString(),
                  retryLabel: l10n.commonRetry,
                  onRetry: () => ref.invalidate(dashboardSummaryProvider),
                ),
                data: (data) {
                  final revSeries =
                      data.revenueData.map((p) => p.revenue).toList();
                  final expSeries =
                      data.revenueData.map((p) => p.expenses).toList();
                  final netSeries = data.revenueData
                      .map((p) => p.revenue - p.expenses)
                      .toList();

                  final kpiCards = [
                    AfabKpiCard(
                      title: l10n.dashboardTotalRevenue,
                      amount: data.revenue.rawValue,
                      currency: data.currency,
                      changeText: data.revenue.change,
                      isPositive: data.revenue.isPositive,
                      periodComparisonLabel: periodLabel,
                      icon: LucideIcons.trendingUp,
                      sparklineData: revSeries,
                      topAccentColor: colors.primary,
                      onAskAi: () => ref
                          .read(copilotLauncherProvider.notifier)
                          .openCopilot(
                            prompt:
                                'Analyze Total Revenue (${data.revenue.formattedValue}, ${data.revenue.change}) for period "${period.apiValue}".',
                            autoSend: true,
                            screenContext: {
                              'page': 'dashboard',
                              'metric': 'revenue',
                              'period': period.apiValue,
                            },
                          ),
                      askAiTooltip: l10n.moreHubAskCopilotTooltip,
                    ),
                    AfabKpiCard(
                      title: l10n.dashboardTotalExpenses,
                      amount: data.expenses.rawValue,
                      currency: data.currency,
                      changeText: data.expenses.change,
                      isPositive: data.expenses.isPositive,
                      periodComparisonLabel: periodLabel,
                      icon: LucideIcons.trendingDown,
                      sparklineData: expSeries,
                      topAccentColor: colors.info,
                      onAskAi: () => ref
                          .read(copilotLauncherProvider.notifier)
                          .openCopilot(
                            prompt:
                                'Analyze Total Expenses (${data.expenses.formattedValue}, ${data.expenses.change}) for period "${period.apiValue}".',
                            autoSend: true,
                            screenContext: {
                              'page': 'dashboard',
                              'metric': 'expenses',
                              'period': period.apiValue,
                            },
                          ),
                      askAiTooltip: l10n.moreHubAskCopilotTooltip,
                    ),
                    AfabKpiCard(
                      title: l10n.dashboardNetProfit,
                      amount: data.profit.rawValue,
                      currency: data.currency,
                      changeText: data.profit.change,
                      isPositive: data.profit.isPositive,
                      periodComparisonLabel: periodLabel,
                      icon: LucideIcons.wallet,
                      sparklineData: netSeries,
                      topAccentColor: colors.success,
                      onAskAi: () => ref
                          .read(copilotLauncherProvider.notifier)
                          .openCopilot(
                            prompt:
                                'Analyze Net Profit (${data.profit.formattedValue}, ${data.profit.change}) for period "${period.apiValue}".',
                            autoSend: true,
                            screenContext: {
                              'page': 'dashboard',
                              'metric': 'profit',
                              'period': period.apiValue,
                            },
                          ),
                      askAiTooltip: l10n.moreHubAskCopilotTooltip,
                    ),
                    AfabKpiCard(
                      title: l10n.dashboardCashFlow,
                      amount: data.cashFlow.rawValue,
                      currency: data.currency,
                      changeText: data.cashFlow.change,
                      isPositive: data.cashFlow.isPositive,
                      periodComparisonLabel: periodLabel,
                      icon: LucideIcons.activity,
                      sparklineData: netSeries,
                      topAccentColor: colors.warning,
                      onAskAi: () => ref
                          .read(copilotLauncherProvider.notifier)
                          .openCopilot(
                            prompt:
                                'Analyze Cash Flow (${data.cashFlow.formattedValue}, ${data.cashFlow.change}) for period "${period.apiValue}".',
                            autoSend: true,
                            screenContext: {
                              'page': 'dashboard',
                              'metric': 'cashflow',
                              'period': period.apiValue,
                            },
                          ),
                      askAiTooltip: l10n.moreHubAskCopilotTooltip,
                    ),
                  ];

                  final kpiSection = _ResponsiveGrid(
                    columns: kpiCols,
                    spacing: 14,
                    children: kpiCards,
                  );

                  final revenueChart = RevenueAreaChart(
                    points: data.revenueData,
                    currency: data.currency,
                  );
                  final aiInsights = AiInsightsCard(pulse: pulseAsync.value);
                  final recentTx = RecentTransactionsCard(
                    transactions: data.transactions,
                    currency: data.currency,
                  );
                  final expenseCategories = ExpenseCategoriesCard(
                    categories: data.expenseCategories,
                    currency: data.currency,
                  );
                  final reminders = ReminderCard(reminders: data.reminders);
                  final topCustomers = TopCustomersCard(
                    customers: data.customers,
                    currency: data.currency,
                  );
                  final upgradeBanner =
                      UpgradeBanner(subscription: subAsync.value);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      kpiSection,
                      const SizedBox(height: 16),
                      if (isTabletSplit) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: revenueChart),
                            const SizedBox(width: 16),
                            Expanded(flex: 1, child: aiInsights),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: recentTx),
                            const SizedBox(width: 16),
                            Expanded(flex: 1, child: expenseCategories),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: reminders),
                            const SizedBox(width: 16),
                            Expanded(child: topCustomers),
                          ],
                        ),
                      ] else ...[
                        revenueChart,
                        const SizedBox(height: 16),
                        aiInsights,
                        const SizedBox(height: 16),
                        expenseCategories,
                        const SizedBox(height: 16),
                        recentTx,
                        const SizedBox(height: 16),
                        reminders,
                        const SizedBox(height: 16),
                        topCustomers,
                      ],
                      const SizedBox(height: 16),
                      upgradeBanner,
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({
    required this.columns,
    required this.spacing,
    required this.children,
  });

  final int columns;
  final double spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final slice = children.skip(i).take(columns).toList();
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var j = 0; j < columns; j++) ...[
              Expanded(
                child: j < slice.length ? slice[j] : const SizedBox.shrink(),
              ),
              if (j < columns - 1) SizedBox(width: spacing),
            ],
          ],
        ),
      );
      if (i + columns < children.length) {
        rows.add(SizedBox(height: spacing));
      }
    }
    return Column(children: rows);
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton({required this.kpiCols});

  final int kpiCols;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ResponsiveGrid(
          columns: kpiCols,
          spacing: 14,
          children: const [
            AfabShimmerBox(height: 130),
            AfabShimmerBox(height: 130),
            AfabShimmerBox(height: 130),
            AfabShimmerBox(height: 130),
          ],
        ),
        const SizedBox(height: 16),
        const AfabShimmerBox(height: 260),
        const SizedBox(height: 16),
        const AfabShimmerBox(height: 190),
      ],
    );
  }
}

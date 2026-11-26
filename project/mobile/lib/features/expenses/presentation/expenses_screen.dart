import 'dart:async';

import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/color_parser.dart';
import 'package:afab_mobile/core/utils/csv_exporter.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/categories/domain/category_providers.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/features/expenses/domain/expense_providers.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:afab_mobile/features/transactions/data/transaction_repository.dart';
import 'package:afab_mobile/features/transactions/domain/transaction_providers.dart';
import 'package:afab_mobile/features/transactions/presentation/widgets/delete_transaction_dialog.dart';
import 'package:afab_mobile/features/transactions/presentation/widgets/transaction_list_card.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/afab_kpi_card.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:afab_mobile/shared/widgets/afab_segmented_bar.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:afab_mobile/shared/widgets/analytics_charts.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `FIN-06`: Expenses Analytics & Ledger.
/// Fixes Web bugs: filters strictly `EXPENSE` categories, renders semantic
/// status badges, replaces stale "Phase 13" text with `/recurring` cross-link,
/// and opens unified `TransactionDetailsScreen` (`FIN-02`).
class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _exporting = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(expenseFilterProvider.notifier).setSearch(val);
    });
  }

  Future<void> _exportCsv(TransactionPageDto page, String fallbackCurr) async {
    setState(() => _exporting = true);
    try {
      final csv = CsvExporter.buildTransactionsCsv(
        page.content,
        fallbackCurrency: fallbackCurr,
      );
      await CsvExporter.shareCsv(
        csvContent: csv,
        filename: 'afab_expenses_${DateTime.now().millisecondsSinceEpoch}.csv',
        subject: context.l10n.expensesTitle,
      );
    } catch (e) {
      if (mounted) {
        AfabToast.showError(
          context,
          '${context.l10n.errorGenericTitle}: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _deleteTx(TransactionDto tx, String fallbackCurr) async {
    final l10n = context.l10n;
    final ok = await showDeleteTransactionDialog(
      context,
      transaction: tx,
      fallbackCurrency: fallbackCurr,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(transactionRepositoryProvider).deleteTransaction(tx.id);
      if (!mounted) return;
      invalidateFinanceLedgers(ref);
      AfabToast.showSuccess(context, l10n.txDeletedToast);
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final biz = ref.watch(activeBusinessProvider);
    final isEditable = !(biz?.isReadOnly ?? false);
    final fallbackCurr = biz?.currency ?? 'USD';
    final dateFmt = biz?.dateFormat ?? 'YYYY-MM-DD';

    final period = ref.watch(expensePeriodProvider);
    final filter = ref.watch(expenseFilterProvider);
    final summaryAsync = ref.watch(expenseSummaryProvider);
    final listAsync = ref.watch(expenseListProvider);
    final expenseCategories = ref.watch(expenseCategoriesProvider);

    final periodLabel = switch (period) {
      DashboardPeriod.weekly => l10n.periodWeekly,
      DashboardPeriod.month => l10n.periodMonthly,
      DashboardPeriod.year => l10n.periodYearly,
    };

    const donutPalette = [
      Color(0xFF8B5CF6),
      Color(0xFFF59E0B),
      Color(0xFF10B981),
      Color(0xFFF43F5E),
      Color(0xFF0EA5E9),
    ];

    return Scaffold(
      floatingActionButton: isEditable
          ? FloatingActionButton.extended(
              heroTag: 'expenses_new_fab',
              onPressed: () => context.push('/transactions/new?type=EXPENSE'),
              icon: const Icon(LucideIcons.plus),
              label: Text(l10n.expensesCreateBtn),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isExpanded = AfabBreakpoints.isExpandedTablet(width);
          final kpiCols = width >= 1024
              ? 3
              : AfabBreakpoints.kpiColumnsForWidth(width);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(expenseSummaryProvider);
              ref.invalidate(expenseListProvider);
              await Future.wait([
                ref.read(expenseSummaryProvider.future),
                ref.read(expenseListProvider.future),
              ]);
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                isExpanded ? 24 : 16,
                16,
                isExpanded ? 24 : 16,
                96,
              ),
              children: [
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
                          l10n.expensesTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.expensesSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
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
                              ref.read(expensePeriodProvider.notifier).select(p),
                        ),
                        if (listAsync.hasValue &&
                            listAsync.value!.content.isNotEmpty)
                          AfabButton(
                            label: l10n.commonExportCsv,
                            icon: LucideIcons.download,
                            variant: AfabButtonVariant.secondary,
                            compact: true,
                            isLoading: _exporting,
                            onPressed: () =>
                                _exportCsv(listAsync.value!, fallbackCurr),
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                summaryAsync.when(
                  loading: () => const AfabListSkeleton(count: 4),
                  error: (err, _) => AfabErrorState(
                    title: l10n.errorGenericTitle,
                    message: err.toString(),
                    retryLabel: l10n.commonRetry,
                    onRetry: () => ref.invalidate(expenseSummaryProvider),
                  ),
                  data: (summary) {
                    final curr = summary.currency.isNotEmpty
                        ? summary.currency
                        : fallbackCurr;

                    final areaChart = DailyTrendAreaChart(
                      title: l10n.expensesOverviewTitle,
                      totalAmount: summary.totalExpenses,
                      currency: curr,
                      points: summary.dailyOverview,
                      emptyText: l10n.expensesNoChartData,
                      accentColor: colors.primary,
                      badgeDotColor: colors.danger,
                    );

                    final donutChart = CategoryBreakdownDonutCard(
                      title: l10n.expensesDonutTitle,
                      centerSubtitle: l10n.expensesTotalSpend,
                      totalAmount: summary.totalExpenses,
                      currency: curr,
                      items: summary.categoryBreakdown,
                      emptyText: l10n.expensesNoChartData,
                      fallbackPalette: donutPalette,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AfabKpiWrapGrid(
                          columns: kpiCols,
                          children: [
                            AfabKpiCard(
                              title: l10n.expensesKpiTotal,
                              amount: summary.totalExpenses,
                              currency: curr,
                              changeText: periodLabel,
                              isPositive: false,
                              periodComparisonLabel:
                                  '${listAsync.value?.totalElements ?? 0}',
                              icon: LucideIcons.wallet,
                              topAccentColor: colors.danger,
                            ),
                            AfabKpiCard(
                              title: l10n.expensesKpiAvgDay,
                              amount: summary.avgPerDay,
                              currency: curr,
                              changeText: periodLabel,
                              isPositive: true,
                              periodComparisonLabel: l10n.expensesSubtitle,
                              icon: LucideIcons.calendarDays,
                              topAccentColor: colors.primary,
                            ),
                            AfabKpiCard(
                              title: l10n.expensesKpiHighest,
                              amount: summary.highestExpenseAmount,
                              currency: curr,
                              changeText: periodLabel,
                              isPositive: false,
                              periodComparisonLabel:
                                  summary.highestExpenseTitle,
                              icon: LucideIcons.trendingUp,
                              topAccentColor: colors.warning,
                            ),
                            AfabKpiCard(
                              title: l10n.expensesKpiCategories,
                              amount: Decimal.fromInt(summary.categoryCount),
                              currency: curr,
                              changeText: '${summary.categoryCount}',
                              isPositive: true,
                              periodComparisonLabel: periodLabel,
                              icon: LucideIcons.layers,
                              topAccentColor: colors.info,
                            ),
                            AfabKpiCard(
                              title: l10n.expensesKpiRecurring,
                              amount: summary.recurringTotal,
                              currency: curr,
                              changeText:
                                  '${summary.recurringPercentage.toStringAsFixed(0)}%',
                              isPositive: true,
                              periodComparisonLabel: l10n.navRecurring,
                              icon: LucideIcons.repeat,
                              topAccentColor: colors.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (isExpanded)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 8, child: areaChart),
                              const SizedBox(width: 16),
                              Expanded(flex: 4, child: donutChart),
                            ],
                          )
                        else ...[
                          areaChart,
                          const SizedBox(height: 16),
                          donutChart,
                        ],
                        const SizedBox(height: 16),
                        // Top Categories Progress + Honest Recurring CTA
                        if (summary.categoryBreakdown.isNotEmpty) ...[
                          AfabCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.expensesTopCategories,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                for (var i = 0;
                                    i < summary.categoryBreakdown.length &&
                                        i < 4;
                                    i++) ...[
                                  _CategoryProgressRow(
                                    item: summary.categoryBreakdown[i],
                                    currency: curr,
                                    fallbackColor:
                                        donutPalette[i % donutPalette.length],
                                  ),
                                  if (i < summary.categoryBreakdown.length - 1 &&
                                      i < 3)
                                    const SizedBox(height: 12),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        AfabCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: colors.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      LucideIcons.repeat,
                                      size: 20,
                                      color: colors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.expensesRecurringCardTitle,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          l10n.expensesRecurringEmpty,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: AfabButton(
                                  label: l10n.expensesManageRecurring,
                                  variant: AfabButtonVariant.soft,
                                  compact: true,
                                  onPressed: () => context.go('/recurring'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),
                Text(
                  l10n.expensesListHeader,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: isExpanded ? 300 : width - 32,
                      child: TextFormField(
                        controller: _searchCtrl,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: l10n.txSearchHint,
                          isDense: true,
                          prefixIcon: const Icon(Icons.search, size: 18),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: isExpanded ? 240 : width - 32,
                      child: DropdownButtonFormField<String?>(
                        initialValue: expenseCategories
                                .any((c) => c.id == filter.categoryId)
                            ? filter.categoryId
                            : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: l10n.txFilterCategory,
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(l10n.commonAll),
                          ),
                          for (final c in expenseCategories)
                            DropdownMenuItem<String?>(
                              value: c.id,
                              child: Text(
                                c.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (val) => ref
                            .read(expenseFilterProvider.notifier)
                            .setCategory(val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                listAsync.when(
                  loading: () => const AfabListSkeleton(count: 4),
                  error: (err, _) => AfabErrorState(
                    title: l10n.errorGenericTitle,
                    message: err.toString(),
                    retryLabel: l10n.commonRetry,
                    onRetry: () => ref.invalidate(expenseListProvider),
                  ),
                  data: (page) {
                    if (page.content.isEmpty) {
                      return AfabEmptyState(
                        icon: LucideIcons.trendingDown,
                        title: l10n.commonNoData,
                        description: l10n.txEmptyDesc,
                      );
                    }
                    final curr =
                        page.currency.isNotEmpty ? page.currency : fallbackCurr;
                    return Column(
                      children: [
                        for (final tx in page.content) ...[
                          TransactionListCard(
                            transaction: tx,
                            fallbackCurrency: curr,
                            dateFormat: dateFmt,
                            isReadOnly: !isEditable,
                            onTap: () =>
                                context.push('/transactions/${tx.id}', extra: tx),
                            onDuplicate: isEditable
                                ? () => context.push(
                                      '/transactions/${tx.id}/duplicate',
                                      extra: tx,
                                    )
                                : null,
                            onEdit: isEditable
                                ? () => context.push(
                                      '/transactions/${tx.id}/edit',
                                      extra: tx,
                                    )
                                : null,
                            onDelete:
                                isEditable ? () => _deleteTx(tx, curr) : null,
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (page.totalPages > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: page.pageNumber > 0
                                    ? () => ref
                                        .read(expenseFilterProvider.notifier)
                                        .setPage(page.pageNumber - 1)
                                    : null,
                                icon: const Icon(Icons.chevron_left),
                              ),
                              Text(
                                l10n.txPageSummary(
                                  page.pageNumber + 1,
                                  page.totalPages,
                                ),
                              ),
                              IconButton(
                                onPressed: page.pageNumber + 1 < page.totalPages
                                    ? () => ref
                                        .read(expenseFilterProvider.notifier)
                                        .setPage(page.pageNumber + 1)
                                    : null,
                                icon: const Icon(Icons.chevron_right),
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryProgressRow extends StatelessWidget {
  const _CategoryProgressRow({
    required this.item,
    required this.currency,
    required this.fallbackColor,
  });

  final dynamic item;
  final String currency;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    final barColor = ColorParser.parseHex(item.color as String?, fallbackColor);
    final pct = ((item.percentage as double) / 100.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.name as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(width: 8),
            MoneyText(
              amount: item.amount as Decimal,
              currency: currency,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: colors.border,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

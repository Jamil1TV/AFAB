import 'dart:async';

import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/csv_exporter.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/categories/domain/category_providers.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/features/revenue/domain/revenue_providers.dart';
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

/// Screen `FIN-07`: Revenue Analytics & Ledger.
/// Fixes Web bugs: `+ Create` defaults to `INCOME`, filters strictly `INCOME`
/// categories, clarifies `totalInvoices` semantic meaning, uses semantic status
/// badges, and opens unified `TransactionDetailsScreen` (`FIN-02`).
class RevenueScreen extends ConsumerStatefulWidget {
  const RevenueScreen({super.key});

  @override
  ConsumerState<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends ConsumerState<RevenueScreen> {
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
      ref.read(revenueFilterProvider.notifier).setSearch(val);
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
        filename: 'afab_revenue_${DateTime.now().millisecondsSinceEpoch}.csv',
        subject: context.l10n.revenueTitle,
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
    final locale = Localizations.localeOf(context).languageCode;
    final biz = ref.watch(activeBusinessProvider);
    final isEditable = !(biz?.isReadOnly ?? false);
    final fallbackCurr = biz?.currency ?? 'USD';
    final dateFmt = biz?.dateFormat ?? 'YYYY-MM-DD';

    final period = ref.watch(revenuePeriodProvider);
    final filter = ref.watch(revenueFilterProvider);
    final summaryAsync = ref.watch(revenueSummaryProvider);
    final listAsync = ref.watch(revenueListProvider);
    final incomeCategories = ref.watch(incomeCategoriesProvider);

    final periodLabel = switch (period) {
      DashboardPeriod.weekly => l10n.periodWeekly,
      DashboardPeriod.month => l10n.periodMonthly,
      DashboardPeriod.year => l10n.periodYearly,
    };

    const sourcePalette = [
      Color(0xFF10B981),
      Color(0xFF8B5CF6),
      Color(0xFF059669),
      Color(0xFF64748B),
      Color(0xFFF59E0B),
    ];

    return Scaffold(
      floatingActionButton: isEditable
          ? FloatingActionButton.extended(
              heroTag: 'revenue_new_fab',
              onPressed: () => context.push('/transactions/new?type=INCOME'),
              icon: const Icon(LucideIcons.plus),
              label: Text(l10n.revenueCreateBtn),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isExpanded = AfabBreakpoints.isExpandedTablet(width);
          final kpiCols = AfabBreakpoints.kpiColumnsForWidth(width);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(revenueSummaryProvider);
              ref.invalidate(revenueListProvider);
              await Future.wait([
                ref.read(revenueSummaryProvider.future),
                ref.read(revenueListProvider.future),
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
                          l10n.revenueTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.revenueSubtitle,
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
                              ref.read(revenuePeriodProvider.notifier).select(p),
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
                    onRetry: () => ref.invalidate(revenueSummaryProvider),
                  ),
                  data: (summary) {
                    final curr = summary.currency.isNotEmpty
                        ? summary.currency
                        : fallbackCurr;

                    final areaChart = DailyTrendAreaChart(
                      title: l10n.revenueOverviewTitle,
                      totalAmount: summary.totalRevenue,
                      currency: curr,
                      points: summary.dailyOverview,
                      emptyText: l10n.revenueNoChartData,
                      accentColor: colors.success,
                      badgeDotColor: colors.success,
                    );

                    final donutChart = CategoryBreakdownDonutCard(
                      title: l10n.revenueBySourceTitle,
                      centerSubtitle: l10n.dashboardRevenueLabel.toUpperCase(),
                      totalAmount: summary.totalRevenue,
                      currency: curr,
                      items: summary.revenueBySource,
                      emptyText: l10n.revenueNoChartData,
                      fallbackPalette: sourcePalette,
                    );

                    final grossNetCard = AfabCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.revenueGrossNetTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          _GrossNetRow(
                            label: l10n.revenueGrossLabel,
                            amount: summary.grossRevenue,
                            currency: curr,
                          ),
                          const SizedBox(height: 8),
                          _GrossNetRow(
                            label: l10n.revenueDiscountsLabel,
                            amount: -summary.discounts,
                            currency: curr,
                            color: colors.danger,
                          ),
                          const SizedBox(height: 8),
                          _GrossNetRow(
                            label: l10n.revenueRefundsLabel,
                            amount: -summary.refunds,
                            currency: curr,
                            color: colors.danger,
                          ),
                          Divider(height: 20, color: colors.border),
                          _GrossNetRow(
                            label: l10n.revenueNetLabel,
                            amount: summary.netRevenue,
                            currency: curr,
                            color: colors.success,
                            bold: true,
                          ),
                          if (summary.discounts == Decimal.zero &&
                              summary.refunds == Decimal.zero) ...[
                            const SizedBox(height: 10),
                            Text(
                              l10n.revenueCashBasisNote,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    );

                    final topProductsCard = AfabCard(
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
                                  color: colors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  LucideIcons.package,
                                  size: 20,
                                  color: colors.success,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.revenueTopProductsTitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.revenueTopProductsEmpty,
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
                              label: l10n.revenueViewInvoices,
                              variant: AfabButtonVariant.soft,
                              compact: true,
                              onPressed: () => context.go('/invoices'),
                            ),
                          ),
                        ],
                      ),
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AfabKpiWrapGrid(
                          columns: kpiCols,
                          children: [
                            AfabKpiCard(
                              title: l10n.revenueKpiTotal,
                              amount: summary.totalRevenue,
                              currency: curr,
                              changeText: periodLabel,
                              isPositive: true,
                              periodComparisonLabel:
                                  '${summary.totalInvoices} ${l10n.revenueKpiCompletedSub}',
                              icon: LucideIcons.dollarSign,
                              topAccentColor: colors.success,
                            ),
                            AfabKpiCard(
                              title: l10n.revenueKpiAvgDay,
                              amount: summary.avgPerDay,
                              currency: curr,
                              changeText: periodLabel,
                              isPositive: true,
                              periodComparisonLabel: l10n.revenueSubtitle,
                              icon: LucideIcons.trendingUp,
                              topAccentColor: colors.primary,
                            ),
                            AfabKpiCard(
                              title: l10n.revenueKpiHighestDay,
                              amount: summary.highestRevenueAmount,
                              currency: curr,
                              changeText: periodLabel,
                              isPositive: true,
                              periodComparisonLabel:
                                  AfabDateFormatter.formatIsoDate(
                                summary.highestRevenueDate,
                                dateFormat: dateFmt,
                                locale: locale,
                              ),
                              icon: LucideIcons.calendarDays,
                              topAccentColor: colors.warning,
                            ),
                            AfabKpiCard(
                              title: l10n.revenueKpiCompletedCount,
                              amount: Decimal.fromInt(summary.totalInvoices),
                              currency: curr,
                              changeText: '${summary.totalInvoices}',
                              isPositive: true,
                              periodComparisonLabel: l10n.revenueKpiCompletedSub,
                              icon: LucideIcons.fileText,
                              topAccentColor: colors.info,
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
                        if (isExpanded)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: grossNetCard),
                              const SizedBox(width: 16),
                              Expanded(child: topProductsCard),
                            ],
                          )
                        else ...[
                          grossNetCard,
                          const SizedBox(height: 16),
                          topProductsCard,
                        ],
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),
                Text(
                  l10n.revenueListHeader,
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
                        initialValue: incomeCategories
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
                          for (final c in incomeCategories)
                            DropdownMenuItem<String?>(
                              value: c.id,
                              child: Text(
                                c.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (val) => ref
                            .read(revenueFilterProvider.notifier)
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
                    onRetry: () => ref.invalidate(revenueListProvider),
                  ),
                  data: (page) {
                    if (page.content.isEmpty) {
                      return AfabEmptyState(
                        icon: LucideIcons.trendingUp,
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
                                        .read(revenueFilterProvider.notifier)
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
                                        .read(revenueFilterProvider.notifier)
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

class _GrossNetRow extends StatelessWidget {
  const _GrossNetRow({
    required this.label,
    required this.amount,
    required this.currency,
    this.color,
    this.bold = false,
  });

  final String label;
  final Decimal amount;
  final String currency;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleSmall
        : Theme.of(context).textTheme.bodyMedium;
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        MoneyText(
          amount: amount,
          currency: currency,
          style: style?.copyWith(
            color: color,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

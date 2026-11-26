import 'dart:async';

import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/csv_exporter.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/categories/domain/category_providers.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:afab_mobile/features/transactions/data/transaction_repository.dart';
import 'package:afab_mobile/features/transactions/domain/transaction_providers.dart';
import 'package:afab_mobile/features/transactions/presentation/transaction_details_screen.dart';
import 'package:afab_mobile/features/transactions/presentation/widgets/delete_transaction_dialog.dart';
import 'package:afab_mobile/features/transactions/presentation/widgets/quick_add_bar.dart';
import 'package:afab_mobile/features/transactions/presentation/widgets/transaction_filter_sheet.dart';
import 'package:afab_mobile/features/transactions/presentation/widgets/transaction_list_card.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/afab_kpi_card.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:afab_mobile/shared/widgets/afab_segmented_bar.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `FIN-01`: Financial Cash Ledger with Master-Detail support on
/// expanded tablets (`>= 840dp`), 7 server filters, Quick-Add NLP, pagination,
/// and ISO-precision CSV export.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;
  bool _exporting = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(transactionFilterProvider.notifier).setSearch(val);
    });
  }

  Future<void> _exportCsv(TransactionPageDto page) async {
    final l10n = context.l10n;
    final filter = ref.read(transactionFilterProvider);
    final bizCurr = ref.read(activeBusinessProvider)?.currency ?? page.currency;

    bool exportAll100 = false;
    if (page.totalElements > page.content.length) {
      final choice = await showDialog<bool>(
        context: context,
        builder: (dlgCtx) => AlertDialog(
          title: Text(l10n.txCsvExportChoiceTitle),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dlgCtx).pop(false),
              child: Text(l10n.txCsvExportCurrentPage(page.content.length)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dlgCtx).pop(true),
              child: Text(l10n.txCsvExportUpTo100),
            ),
          ],
        ),
      );
      if (choice == null || !mounted) return;
      exportAll100 = choice;
    }

    setState(() => _exporting = true);
    try {
      List<TransactionDto> rows = page.content;
      if (exportAll100) {
        final fullPage = await ref.read(transactionRepositoryProvider).getTransactions(
              type: filter.type,
              categoryId: filter.categoryId,
              status: filter.status,
              paymentMethod: filter.paymentMethod,
              taxDeductible: filter.taxDeductible,
              startDate: filter.startDate,
              endDate: filter.endDate,
              search: filter.search,
              page: 0,
              size: 100,
            );
        rows = fullPage.content;
      }
      final csv = CsvExporter.buildTransactionsCsv(
        rows,
        fallbackCurrency: bizCurr,
      );
      await CsvExporter.shareCsv(
        csvContent: csv,
        filename: 'afab_transactions_${DateTime.now().millisecondsSinceEpoch}.csv',
        subject: l10n.txTitle,
      );
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    } catch (e) {
      if (mounted) AfabToast.showError(context, '${l10n.errorGenericTitle}: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _deleteTx(TransactionDto tx, String fallbackCurrency) async {
    final l10n = context.l10n;
    final confirmed = await showDeleteTransactionDialog(
      context,
      transaction: tx,
      fallbackCurrency: fallbackCurrency,
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(transactionRepositoryProvider).deleteTransaction(tx.id);
      if (!mounted) return;
      if (ref.read(selectedTransactionIdProvider) == tx.id) {
        ref.read(selectedTransactionIdProvider.notifier).select(null);
      }
      invalidateFinanceLedgers(ref);
      AfabToast.showSuccess(context, l10n.txDeletedToast);
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    }
  }

  List<TransactionDto> _sortedRows(
    List<TransactionDto> items,
    TransactionFilterState filter,
  ) {
    final list = List<TransactionDto>.from(items);
    list.sort((a, b) {
      final cmp = switch (filter.sortField) {
        TransactionSortField.date => a.transactionDate.compareTo(b.transactionDate),
        TransactionSortField.amount => a.amount.compareTo(b.amount),
      };
      return filter.sortAscending ? cmp : -cmp;
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final biz = ref.watch(activeBusinessProvider);
    final isEditable = !(biz?.isReadOnly ?? false);
    final fallbackCurr = biz?.currency ?? 'USD';
    final dateFmt = biz?.dateFormat ?? 'YYYY-MM-DD';

    final filter = ref.watch(transactionFilterProvider);
    final pageAsync = ref.watch(transactionListProvider);
    final categories = ref.watch(categoryListProvider).value ?? const [];
    final selectedId = ref.watch(selectedTransactionIdProvider);

    return Scaffold(
      floatingActionButton: isEditable
          ? FloatingActionButton.extended(
              heroTag: 'transactions_new_fab',
              onPressed: () => context.push('/transactions/new'),
              icon: const Icon(LucideIcons.plus),
              label: Text(l10n.txAddButton),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMasterDetail = AfabBreakpoints.isExpandedTablet(width);
          final kpiCols = AfabBreakpoints.kpiColumnsForWidth(
            isMasterDetail ? width * 0.58 : width,
          );

          final masterPane = RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(transactionListProvider);
              ref.invalidate(categoryListProvider);
              await ref.read(transactionListProvider.future);
            },
            child: ListView(
              controller: _scrollCtrl,
              padding: EdgeInsets.fromLTRB(
                isMasterDetail ? 20 : 16,
                16,
                isMasterDetail ? 20 : 16,
                96,
              ),
              children: [
                // Title & Action Bar
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
                          l10n.txTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.txSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AfabButton(
                          label: l10n.txManageCategoriesButton,
                          icon: LucideIcons.tag,
                          variant: AfabButtonVariant.secondary,
                          compact: true,
                          onPressed: () => context.push('/categories'),
                        ),
                        if (isEditable)
                          AfabButton(
                            label: l10n.txSplitButton,
                            icon: LucideIcons.layers,
                            variant: AfabButtonVariant.soft,
                            compact: true,
                            onPressed: () => context.push('/transactions/split'),
                          ),
                        if (pageAsync.hasValue &&
                            pageAsync.value!.content.isNotEmpty)
                          AfabButton(
                            label: l10n.commonExportCsv,
                            icon: LucideIcons.download,
                            variant: AfabButtonVariant.secondary,
                            compact: true,
                            isLoading: _exporting,
                            onPressed: () => _exportCsv(pageAsync.value!),
                          ),
                      ],
                    ),
                  ],
                ),

                if (!isEditable) ...[
                  const SizedBox(height: 12),
                  AfabInsetPanel(
                    borderColor: colors.warning.withValues(alpha: 0.45),
                    child: Text(
                      l10n.commonReadOnlyNotice,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],

                if (isEditable) ...[
                  const SizedBox(height: 14),
                  const QuickAddBar(),
                ],

                const SizedBox(height: 14),
                // Period selector bar
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AfabSegmentedBar<TransactionPeriod>(
                      items: [
                        AfabSegmentItem(
                          value: TransactionPeriod.weekly,
                          label: l10n.periodWeekly,
                        ),
                        AfabSegmentItem(
                          value: TransactionPeriod.monthly,
                          label: l10n.periodMonthly,
                        ),
                        AfabSegmentItem(
                          value: TransactionPeriod.yearly,
                          label: l10n.periodYearly,
                        ),
                        AfabSegmentItem(
                          value: TransactionPeriod.all,
                          label: l10n.periodAllTime,
                        ),
                      ],
                      selectedValue: filter.period == TransactionPeriod.custom
                          ? TransactionPeriod.all
                          : filter.period,
                      onSelected: (p) => ref
                          .read(transactionFilterProvider.notifier)
                          .setPeriod(p),
                    ),
                    if (pageAsync.hasValue)
                      Text(
                        l10n.txFilteredResultsCount(pageAsync.value!.totalElements),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: colors.textMuted,
                            ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),
                pageAsync.when(
                  loading: () => const AfabListSkeleton(count: 6),
                  error: (err, _) => AfabErrorState(
                    title: l10n.errorGenericTitle,
                    message: err.toString(),
                    retryLabel: l10n.commonRetry,
                    onRetry: () => ref.invalidate(transactionListProvider),
                  ),
                  data: (page) {
                    final curr =
                        page.currency.isNotEmpty ? page.currency : fallbackCurr;
                    final rows = _sortedRows(page.content, filter);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 4 KPIs (All-time ledger totals per backend spec)
                        _KpiWrapGrid(
                          columns: kpiCols,
                          children: [
                            AfabKpiCard(
                              title: l10n.txKpiInflow,
                              amount: page.totalInflow,
                              currency: curr,
                              changeText: '+',
                              isPositive: true,
                              periodComparisonLabel: l10n.txAllTimeLedgerCaption,
                              icon: LucideIcons.trendingUp,
                              topAccentColor: colors.success,
                            ),
                            AfabKpiCard(
                              title: l10n.txKpiOutflow,
                              amount: page.totalOutflow,
                              currency: curr,
                              changeText: '-',
                              isPositive: false,
                              periodComparisonLabel: l10n.txAllTimeLedgerCaption,
                              icon: LucideIcons.arrowRightLeft,
                              topAccentColor: colors.primary,
                            ),
                            AfabKpiCard(
                              title: l10n.txKpiNetBalance,
                              amount: page.netBalance,
                              currency: curr,
                              changeText:
                                  page.netBalance >= Decimal.zero ? '+' : '-',
                              isPositive: page.netBalance >= Decimal.zero,
                              periodComparisonLabel: l10n.txAllTimeLedgerCaption,
                              icon: LucideIcons.dollarSign,
                              topAccentColor: page.netBalance >= Decimal.zero
                                  ? colors.success
                                  : colors.danger,
                            ),
                            AfabKpiCard(
                              title: l10n.txKpiCount,
                              amount: Decimal.fromInt(page.totalElements),
                              currency: curr,
                              changeText: '${page.totalElements}',
                              isPositive: true,
                              periodComparisonLabel: l10n.txFilteredResultsCount(
                                page.totalElements,
                              ),
                              icon: LucideIcons.layers,
                              topAccentColor: colors.info,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        // Search + Filters + Sort Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _searchCtrl,
                                onChanged: _onSearchChanged,
                                decoration: InputDecoration(
                                  hintText: l10n.txSearchHint,
                                  isDense: true,
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    size: 18,
                                  ),
                                  suffixIcon: _searchCtrl.text.isNotEmpty
                                      ? IconButton(
                                          onPressed: () {
                                            _searchCtrl.clear();
                                            ref
                                                .read(
                                                  transactionFilterProvider
                                                      .notifier,
                                                )
                                                .setSearch('');
                                          },
                                          icon: const Icon(
                                            LucideIcons.x,
                                            size: 16,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Badge(
                              isLabelVisible: filter.activeFilterCount > 0,
                              label: Text('${filter.activeFilterCount}'),
                              child: Builder(
                                builder: (context) {
                                  Future<void> openFilters() async {
                                    final next =
                                        await showTransactionFilterSheet(
                                      context,
                                      current: filter,
                                      categories: categories,
                                    );
                                    if (next != null) {
                                      ref
                                          .read(
                                            transactionFilterProvider.notifier,
                                          )
                                          .applyFilters(
                                            type: next.type,
                                            categoryId: next.categoryId,
                                            status: next.status,
                                            paymentMethod: next.paymentMethod,
                                            taxDeductible: next.taxDeductible,
                                            startDate: next.startDate,
                                            endDate: next.endDate,
                                            period: next.period,
                                          );
                                    }
                                  }

                                  if (MediaQuery.sizeOf(context).width < 380) {
                                    return IconButton.outlined(
                                      tooltip: l10n.txFiltersTitle,
                                      onPressed: openFilters,
                                      icon: const Icon(
                                        LucideIcons.slidersHorizontal,
                                        size: 18,
                                      ),
                                    );
                                  }
                                  return OutlinedButton.icon(
                                    onPressed: openFilters,
                                    icon: const Icon(
                                      LucideIcons.slidersHorizontal,
                                      size: 16,
                                    ),
                                    label: Text(l10n.txFiltersTitle),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        // Quick Filter & Sort strip
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              FilterChip(
                                label: Text(l10n.txTypeIncome),
                                selected: filter.type == TransactionType.income,
                                onSelected: (sel) => ref
                                    .read(transactionFilterProvider.notifier)
                                    .setType(
                                      sel ? TransactionType.income : null,
                                    ),
                              ),
                              const SizedBox(width: 6),
                              FilterChip(
                                label: Text(l10n.txTypeExpense),
                                selected:
                                    filter.type == TransactionType.expense,
                                onSelected: (sel) => ref
                                    .read(transactionFilterProvider.notifier)
                                    .setType(
                                      sel ? TransactionType.expense : null,
                                    ),
                              ),
                              const SizedBox(width: 6),
                              FilterChip(
                                label: Text(l10n.txBadgeTax),
                                selected: filter.taxDeductible == true,
                                onSelected: (sel) => ref
                                    .read(transactionFilterProvider.notifier)
                                    .setTaxDeductible(sel),
                              ),
                              const SizedBox(width: 6),
                              ActionChip(
                                label: Text(
                                  '${l10n.txSortDate} ${filter.sortField == TransactionSortField.date ? (filter.sortAscending ? '↑' : '↓') : ''}',
                                ),
                                onPressed: () => ref
                                    .read(transactionFilterProvider.notifier)
                                    .toggleSort(TransactionSortField.date),
                              ),
                              const SizedBox(width: 6),
                              ActionChip(
                                label: Text(
                                  '${l10n.txSortAmount} ${filter.sortField == TransactionSortField.amount ? (filter.sortAscending ? '↑' : '↓') : ''}',
                                ),
                                onPressed: () => ref
                                    .read(transactionFilterProvider.notifier)
                                    .toggleSort(TransactionSortField.amount),
                              ),
                              if (filter.activeFilterCount > 0) ...[
                                const SizedBox(width: 6),
                                TextButton(
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    ref
                                        .read(
                                          transactionFilterProvider.notifier,
                                        )
                                        .resetFilters();
                                  },
                                  child: Text(l10n.txFilterReset),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                        if (rows.isEmpty)
                          AfabEmptyState(
                            icon: LucideIcons.arrowRightLeft,
                            title: l10n.txEmptyTitle,
                            description: l10n.txEmptyDesc,
                            actionLabel:
                                isEditable ? l10n.txAddButton : null,
                            onAction: isEditable
                                ? () => context.push('/transactions/new')
                                : null,
                          )
                        else ...[
                          if (page.totalPages > 1)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                l10n.txPageOnlySortHint,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          for (final tx in rows) ...[
                            TransactionListCard(
                              transaction: tx,
                              fallbackCurrency: curr,
                              dateFormat: dateFmt,
                              selected: isMasterDetail && selectedId == tx.id,
                              isReadOnly: !isEditable,
                              onTap: () {
                                if (isMasterDetail) {
                                  ref
                                      .read(
                                        selectedTransactionIdProvider.notifier,
                                      )
                                      .select(tx.id);
                                } else {
                                  context.push(
                                    '/transactions/${tx.id}',
                                    extra: tx,
                                  );
                                }
                              },
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
                          if (page.totalPages > 1) ...[
                            const SizedBox(height: 8),
                            _PaginationBar(
                              pageNumber: page.pageNumber,
                              totalPages: page.totalPages,
                              pageSize: page.pageSize,
                              totalElements: page.totalElements,
                              onPageChanged: (nextPage) {
                                ref
                                    .read(transactionFilterProvider.notifier)
                                    .setPage(nextPage);
                                _scrollCtrl.animateTo(
                                  0,
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                );
                              },
                            ),
                          ],
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          );

          if (!isMasterDetail) {
            return masterPane;
          }

          return Row(
            children: [
              Expanded(flex: 58, child: masterPane),
              VerticalDivider(width: 1, color: colors.border),
              Expanded(
                flex: 42,
                child: selectedId == null
                    ? Center(
                        child: AfabEmptyState(
                          icon: LucideIcons.receipt,
                          title: l10n.txDetailsTitle,
                          description: l10n.txEmptyDetailPrompt,
                        ),
                      )
                    : TransactionDetailsPane(
                        key: ValueKey(selectedId),
                        transactionId: selectedId,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _KpiWrapGrid extends StatelessWidget {
  const _KpiWrapGrid({
    required this.columns,
    required this.children,
  });

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final slice = children.sublist(
        i,
        (i + columns) > children.length ? children.length : (i + columns),
      );
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < slice.length; j++) ...[
                Expanded(child: slice[j]),
                if (j < columns - 1) const SizedBox(width: 12),
              ],
              if (slice.length < columns)
                for (var k = 0; k < columns - slice.length; k++) ...[
                  const Expanded(child: SizedBox.shrink()),
                  if (slice.length + k < columns - 1) const SizedBox(width: 12),
                ],
            ],
          ),
        ),
      );
      if (i + columns < children.length) {
        rows.add(const SizedBox(height: 12));
      }
    }
    return Column(children: rows);
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.pageNumber,
    required this.totalPages,
    required this.pageSize,
    required this.totalElements,
    required this.onPageChanged,
  });

  final int pageNumber;
  final int totalPages;
  final int pageSize;
  final int totalElements;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final start = pageNumber * pageSize + 1;
    final end = ((pageNumber + 1) * pageSize).clamp(0, totalElements);

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Text(
          l10n.txShowingRange(start, end, totalElements),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: pageNumber > 0 ? () => onPageChanged(pageNumber - 1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              l10n.txPageSummary(pageNumber + 1, totalPages),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            IconButton(
              onPressed: pageNumber + 1 < totalPages
                  ? () => onPageChanged(pageNumber + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}

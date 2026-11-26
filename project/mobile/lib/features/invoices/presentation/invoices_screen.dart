import 'dart:async';

import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:afab_mobile/core/navigation/copilot_prompt_request.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/color_parser.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/invoices/data/invoice_dtos.dart';
import 'package:afab_mobile/features/invoices/domain/invoices_providers.dart';
import 'package:afab_mobile/features/invoices/presentation/invoice_details_screen.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/afab_kpi_card.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:afab_mobile/shared/widgets/analytics_charts.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `BIZ-03`: Invoices List, Summary Analytics, Upcoming Due & Master-Detail.
class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(invoicesFilterProvider.notifier).setSearch(val);
    });
  }

  void _openInvoice(String id, bool isExpanded) {
    if (isExpanded) {
      ref.read(selectedInvoiceIdProvider.notifier).select(id);
    } else {
      context.push('/invoices/$id');
    }
  }

  Future<void> _openUpcoming(
    UpcomingInvoiceItemDto upcoming,
    bool isExpanded,
  ) async {
    try {
      final uuid = await resolveInvoiceUuidByNumber(ref, upcoming.invoiceId);
      if (!mounted) return;
      if (uuid == null || uuid.isEmpty) {
        AfabToast.showInfo(context, upcoming.invoiceId);
        return;
      }
      _openInvoice(uuid, isExpanded);
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    }
  }

  void _openAiReminder(InvoiceDto inv) {
    final customerLabel = (inv.customerName?.isNotEmpty == true)
        ? inv.customerName!
        : 'customer';
    final balanceStr = MoneyFormatter.formatDecimal(
      inv.outstandingBalance,
      currency: inv.currency,
    );
    context.go(
      '/copilot',
      extra: CopilotPromptRequest(
        prompt:
            'Draft a polite, professional payment reminder for invoice ${inv.invoiceNumber} ($balanceStr outstanding, due ${inv.dueDate}) addressed to $customerLabel.',
        autoSend: true,
        screenContext: {
          'page': 'invoices',
          'invoiceId': inv.id,
          'invoiceNumber': inv.invoiceNumber,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final biz = ref.watch(activeBusinessProvider);
    final isEditable = !(biz?.isReadOnly ?? false);
    final fallbackCurr = biz?.currency ?? 'USD';
    final dateFmt = biz?.dateFormat ?? 'YYYY-MM-DD';
    final locale = Localizations.localeOf(context).languageCode;

    final filter = ref.watch(invoicesFilterProvider);
    final summaryAsync = ref.watch(invoiceSummaryProvider);
    final listAsync = ref.watch(invoicesListProvider);
    final selectedId = ref.watch(selectedInvoiceIdProvider);

    return Scaffold(
      floatingActionButton: isEditable
          ? FloatingActionButton.extended(
              heroTag: 'invoices_new_fab',
              onPressed: () => context.push('/invoices/new'),
              icon: const Icon(LucideIcons.filePlus),
              label: Text(l10n.invoicesCreateBtn),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isExpanded = AfabBreakpoints.isExpandedTablet(width);
          final kpiCols = AfabBreakpoints.kpiColumnsForWidth(width);

          final listColumn = RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(invoiceSummaryProvider);
              ref.invalidate(invoicesListProvider);
              await Future.wait([
                ref.read(invoiceSummaryProvider.future),
                ref.read(invoicesListProvider.future),
              ]);
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                isExpanded ? 24 : 16,
                16,
                16,
                96,
              ),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.invoicesTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.invoicesSubtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                summaryAsync.when(
                  loading: () => const AfabListSkeleton(count: 2),
                  error: (err, _) => AfabErrorState(
                    title: l10n.errorGenericTitle,
                    message: err.toString(),
                    retryLabel: l10n.commonRetry,
                    onRetry: () => ref.invalidate(invoiceSummaryProvider),
                  ),
                  data: (summary) {
                    final curr = summary.currency.isNotEmpty
                        ? summary.currency
                        : fallbackCurr;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AfabKpiWrapGrid(
                          columns: kpiCols,
                          children: [
                            AfabKpiCard(
                              title: l10n.invoicesKpiTotalInvoiced,
                              amount: summary.totalInvoiceAmount,
                              currency: curr,
                              changeText: '${summary.totalInvoices}',
                              isPositive: true,
                              periodComparisonLabel: l10n.invoicesTitle,
                              icon: LucideIcons.fileText,
                              topAccentColor: colors.primary,
                            ),
                            AfabKpiCard(
                              title: l10n.invoicesKpiPaid,
                              amount: summary.paidAmount,
                              currency: curr,
                              changeText: '${summary.paidInvoices}',
                              isPositive: true,
                              periodComparisonLabel: l10n.invoicesStatusPaid,
                              icon: LucideIcons.circleCheck,
                              topAccentColor: colors.success,
                            ),
                            AfabKpiCard(
                              title: l10n.invoicesKpiPending,
                              amount: summary.pendingAmount,
                              currency: curr,
                              changeText: '${summary.pendingInvoices}',
                              isPositive: true,
                              periodComparisonLabel: l10n.invoicesStatusUnpaid,
                              icon: LucideIcons.clock,
                              topAccentColor: colors.warning,
                            ),
                            AfabKpiCard(
                              title: l10n.invoicesKpiOverdue,
                              amount: summary.overdueAmount,
                              currency: curr,
                              changeText: '${summary.overdueInvoices}',
                              isPositive: summary.overdueInvoices == 0,
                              periodComparisonLabel: l10n.invoicesStatusOverdue,
                              icon: LucideIcons.triangleAlert,
                              topAccentColor: colors.danger,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _StatusBreakdownCard(
                          items: summary.statusBreakdown,
                          currency: curr,
                        ),
                        const SizedBox(height: 14),
                        AfabCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.invoicesUpcomingDue,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 10),
                              if (summary.upcomingDueList.isEmpty)
                                AfabEmptyState(
                                  icon: LucideIcons.calendarCheck,
                                  title: l10n.commonNoData,
                                  description: l10n.invoicesUpcomingEmpty,
                                )
                              else
                                for (var i = 0;
                                    i < summary.upcomingDueList.length;
                                    i++) ...[
                                  _UpcomingDueTile(
                                    item: summary.upcomingDueList[i],
                                    currency: curr,
                                    dateFormat: dateFmt,
                                    locale: locale,
                                    onTap: () => _openUpcoming(
                                      summary.upcomingDueList[i],
                                      isExpanded,
                                    ),
                                  ),
                                  if (i < summary.upcomingDueList.length - 1)
                                    Divider(height: 12, color: colors.border),
                                ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 18),
                TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: l10n.invoicesSearchHint,
                    isDense: true,
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                  ),
                ),
                const SizedBox(height: 10),

                // Status Filter Chips (ALL + all 7 statuses including SENT)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: FilterChip(
                          label: Text(l10n.commonAll),
                          selected: filter.status == null,
                          onSelected: (_) => ref
                              .read(invoicesFilterProvider.notifier)
                              .setStatus(null),
                        ),
                      ),
                      for (final st in InvoiceStatus.values)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: FilterChip(
                            label: Text(st.localizedLabel(context)),
                            selected: filter.status == st,
                            onSelected: (_) => ref
                                .read(invoicesFilterProvider.notifier)
                                .setStatus(st),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                listAsync.when(
                  loading: () => const AfabListSkeleton(count: 4),
                  error: (err, _) => AfabErrorState(
                    title: l10n.errorGenericTitle,
                    message: err.toString(),
                    retryLabel: l10n.commonRetry,
                    onRetry: () => ref.invalidate(invoicesListProvider),
                  ),
                  data: (page) {
                    if (page.content.isEmpty) {
                      return AfabEmptyState(
                        icon: LucideIcons.fileText,
                        title: l10n.invoicesEmptyTitle,
                        description: l10n.invoicesEmptyDesc,
                        actionLabel:
                            isEditable ? l10n.invoicesCreateBtn : null,
                        onAction: isEditable
                            ? () => context.push('/invoices/new')
                            : null,
                      );
                    }
                    return Column(
                      children: [
                        for (final inv in page.content) ...[
                          _InvoiceListCard(
                            invoice: inv,
                            selected: isExpanded && selectedId == inv.id,
                            dateFormat: dateFmt,
                            locale: locale,
                            onTap: () => _openInvoice(inv.id, isExpanded),
                            onAiReminder: inv.status.isPayable
                                ? () => _openAiReminder(inv)
                                : null,
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
                                        .read(invoicesFilterProvider.notifier)
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
                                        .read(invoicesFilterProvider.notifier)
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

          if (!isExpanded) return listColumn;

          return Row(
            children: [
              Expanded(flex: 42, child: listColumn),
              VerticalDivider(width: 1, color: colors.border),
              Expanded(
                flex: 58,
                child: selectedId == null
                    ? Center(
                        child: AfabEmptyState(
                          icon: LucideIcons.fileText,
                          title: l10n.invoicesDetailTitle,
                          description: l10n.invoicesDetailPrompt,
                        ),
                      )
                    : InvoiceDetailsPane(invoiceId: selectedId),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusBreakdownCard extends StatelessWidget {
  const _StatusBreakdownCard({
    required this.items,
    required this.currency,
  });

  final List<InvoiceStatusBreakdownItemDto> items;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasPositive = items.any((i) => i.amount > Decimal.zero);
    const palette = [
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFF3B82F6),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
    ];

    return AfabCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.invoicesStatusBreakdown,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (items.isEmpty || !hasPositive)
            AfabEmptyState(
              icon: LucideIcons.pieChart,
              title: l10n.commonNoData,
              description: l10n.invoicesEmptyDesc,
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 112,
                  height: 112,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 28,
                      sectionsSpace: 2,
                      sections: [
                        for (var i = 0; i < items.length; i++)
                          if (items[i].amount > Decimal.zero)
                            PieChartSectionData(
                              value: items[i].amount.toDouble(),
                              color: ColorParser.parseHex(
                                items[i].color,
                                palette[i % palette.length],
                              ),
                              radius: 20,
                              showTitle: false,
                            ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: ColorParser.parseHex(
                                  items[i].color,
                                  palette[i % palette.length],
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                items[i].name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            MoneyText(
                              amount: items[i].amount,
                              currency: currency,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        if (i < items.length - 1) const SizedBox(height: 6),
                      ],
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _UpcomingDueTile extends StatelessWidget {
  const _UpcomingDueTile({
    required this.item,
    required this.currency,
    required this.dateFormat,
    required this.locale,
    required this.onTap,
  });

  final UpcomingInvoiceItemDto item;
  final String currency;
  final String dateFormat;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateStr = AfabDateFormatter.formatIsoDate(
      item.dueDate,
      dateFormat: dateFormat,
      locale: locale,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      item.invoiceId,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${item.customerName} · ${l10n.invoicesDueDateLabel(dateStr)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            MoneyText(
              amount: item.amount,
              currency: currency,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceListCard extends StatelessWidget {
  const _InvoiceListCard({
    required this.invoice,
    required this.selected,
    required this.dateFormat,
    required this.locale,
    required this.onTap,
    this.onAiReminder,
  });

  final InvoiceDto invoice;
  final bool selected;
  final String dateFormat;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback? onAiReminder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final dueStr = AfabDateFormatter.formatIsoDate(
      invoice.dueDate,
      dateFormat: dateFormat,
      locale: locale,
    );

    return AfabCard(
      onTap: onTap,
      topAccentColor: selected ? colors.primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    invoice.invoiceNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AfabStatusBadge(
                label: invoice.status.localizedLabel(context),
                variant: invoice.status.badgeVariant,
              ),
              if (onAiReminder != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: l10n.invoicesAiReminderBtn,
                  icon: Icon(
                    LucideIcons.sparkles,
                    size: 18,
                    color: colors.primary,
                  ),
                  onPressed: onAiReminder,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            (invoice.customerName?.isNotEmpty == true)
                ? invoice.customerName!
                : l10n.invoicesWalkInCustomer,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                l10n.invoicesDueDateLabel(dueStr),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              MoneyText(
                amount: invoice.totalAmount,
                currency: invoice.currency,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

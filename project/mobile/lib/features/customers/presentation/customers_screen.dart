import 'dart:async';

import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/customers/data/customer_dtos.dart';
import 'package:afab_mobile/features/customers/domain/customers_providers.dart';
import 'package:afab_mobile/features/customers/presentation/customer_details_screen.dart';
import 'package:afab_mobile/features/customers/presentation/widgets/add_edit_customer_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/afab_kpi_card.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:afab_mobile/shared/widgets/afab_segmented_bar.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/analytics_charts.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `BIZ-01`: Customers Directory, Analytics, and Master-Detail CRM Hub.
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
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
      ref.read(customersFilterProvider.notifier).setSearch(val);
    });
  }

  void _openCustomer(CustomerDto customer, bool isExpanded) {
    if (isExpanded) {
      ref.read(selectedCustomerIdProvider.notifier).select(customer.id);
    } else {
      context.push('/customers/${customer.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final biz = ref.watch(activeBusinessProvider);
    final isEditable = !(biz?.isReadOnly ?? false);
    final fallbackCurr = biz?.currency ?? 'USD';

    final filter = ref.watch(customersFilterProvider);
    final summaryAsync = ref.watch(customerSummaryProvider);
    final listAsync = ref.watch(customersListProvider);
    final selectedId = ref.watch(selectedCustomerIdProvider);

    return Scaffold(
      floatingActionButton: isEditable
          ? FloatingActionButton.extended(
              heroTag: 'customers_new_fab',
              onPressed: () => showAddEditCustomerSheet(context),
              icon: const Icon(LucideIcons.userPlus),
              label: Text(l10n.customersAddBtn),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isExpanded = AfabBreakpoints.isExpandedTablet(width);
          final kpiCols = AfabBreakpoints.kpiColumnsForWidth(width);

          final listColumn = RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(customerSummaryProvider);
              ref.invalidate(customersListProvider);
              await Future.wait([
                ref.read(customerSummaryProvider.future),
                ref.read(customersListProvider.future),
              ]);
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                isExpanded ? 24 : 16,
                16,
                isExpanded ? 16 : 16,
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
                          l10n.customersTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.customersSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    AfabSegmentedBar<String>(
                      items: [
                        AfabSegmentItem(
                          value: 'today',
                          label: l10n.customersPeriodToday,
                        ),
                        AfabSegmentItem(
                          value: 'week',
                          label: l10n.customersPeriodWeek,
                        ),
                        AfabSegmentItem(
                          value: 'month',
                          label: l10n.customersPeriodMonth,
                        ),
                        AfabSegmentItem(
                          value: 'year',
                          label: l10n.customersPeriodYear,
                        ),
                      ],
                      selectedValue: filter.period,
                      onSelected: (p) =>
                          ref.read(customersFilterProvider.notifier).setPeriod(p),
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
                    onRetry: () => ref.invalidate(customerSummaryProvider),
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
                            _CustomerCountKpiCard(
                              title: l10n.customersKpiTotal,
                              value: '${summary.totalCustomers}',
                              changeText:
                                  '${summary.totalCustomersChangePct >= 0 ? '+' : ''}${summary.totalCustomersChangePct.toStringAsFixed(1)}%',
                              isPositive: summary.totalCustomersChangePct >= 0,
                              subLabel: l10n.customersNewPeriod(
                                summary.newCustomers,
                              ),
                              icon: LucideIcons.users,
                              accentColor: colors.primary,
                            ),
                            AfabKpiCard(
                              title: l10n.customersKpiTotalRevenue,
                              amount: summary.totalRevenue,
                              currency: curr,
                              changeText:
                                  '${summary.totalRevenueChangePct >= 0 ? '+' : ''}${summary.totalRevenueChangePct.toStringAsFixed(1)}%',
                              isPositive: summary.totalRevenueChangePct >= 0,
                              periodComparisonLabel:
                                  l10n.dashboardCustomersInRevenue,
                              icon: LucideIcons.dollarSign,
                              topAccentColor: colors.success,
                            ),
                            AfabKpiCard(
                              title: l10n.customersKpiAvgRevenue,
                              amount: summary.avgRevenuePerCustomer,
                              currency: curr,
                              changeText:
                                  '${summary.avgRevenueChangePct >= 0 ? '+' : ''}${summary.avgRevenueChangePct.toStringAsFixed(1)}%',
                              isPositive: summary.avgRevenueChangePct >= 0,
                              periodComparisonLabel: l10n.customersTitle,
                              icon: LucideIcons.trendingUp,
                              topAccentColor: colors.info,
                            ),
                            _CustomerCountKpiCard(
                              title: l10n.customersKpiRepeatRate,
                              value:
                                  '${summary.repeatCustomersPct.toStringAsFixed(1)}%',
                              changeText:
                                  '${summary.repeatCustomersChangePct >= 0 ? '+' : ''}${summary.repeatCustomersChangePct.toStringAsFixed(1)}%',
                              isPositive: summary.repeatCustomersChangePct >= 0,
                              subLabel: l10n.customersTitle,
                              icon: LucideIcons.repeat,
                              accentColor: colors.warning,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _CustomerSegmentsDonutCard(donut: summary.overviewDonut),
                        if (summary.topCustomers.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          AfabCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.customersTopTitle,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 10),
                                for (var i = 0;
                                    i < summary.topCustomers.length && i < 5;
                                    i++) ...[
                                  InkWell(
                                    onTap: () {
                                      final id = summary.topCustomers[i].id;
                                      if (isExpanded) {
                                        ref
                                            .read(selectedCustomerIdProvider
                                                .notifier)
                                            .select(id);
                                      } else {
                                        context.push('/customers/$id');
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  summary.topCustomers[i].name,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall,
                                                ),
                                                Text(
                                                  l10n.customersOrdersCount(
                                                    summary.topCustomers[i]
                                                        .ordersCount,
                                                  ),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                          MoneyText(
                                            amount:
                                                summary.topCustomers[i].revenue,
                                            currency: curr,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  color: colors.success,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (i < summary.topCustomers.length - 1 &&
                                      i < 4)
                                    Divider(height: 12, color: colors.border),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),

                const SizedBox(height: 18),

                // Search & Filters
                TextField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: l10n.customersSearchHint,
                    isDense: true,
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: 165,
                      child: DropdownButtonFormField<String?>(
                        initialValue: filter.status,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.customersFieldStatus,
                          isDense: true,
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(l10n.customersStatusAll),
                          ),
                          DropdownMenuItem(
                            value: 'Active',
                            child: Text(l10n.customersStatusActive),
                          ),
                          DropdownMenuItem(
                            value: 'New',
                            child: Text(l10n.customersStatusNew),
                          ),
                          DropdownMenuItem(
                            value: 'Inactive',
                            child: Text(l10n.customersStatusInactive),
                          ),
                        ],
                        onChanged: (v) => ref
                            .read(customersFilterProvider.notifier)
                            .setStatus(v),
                      ),
                    ),
                    SizedBox(
                      width: 175,
                      child: DropdownButtonFormField<String?>(
                        initialValue: filter.group,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n.customersFieldGroup,
                          isDense: true,
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(l10n.customersGroupAll),
                          ),
                          DropdownMenuItem(
                            value: 'Standard',
                            child: Text(l10n.customersGroupStandard),
                          ),
                          DropdownMenuItem(
                            value: 'VIP',
                            child: Text(l10n.customersGroupVip),
                          ),
                          DropdownMenuItem(
                            value: 'Wholesale',
                            child: Text(l10n.customersGroupWholesale),
                          ),
                          DropdownMenuItem(
                            value: 'Enterprise',
                            child: Text(l10n.customersGroupEnterprise),
                          ),
                          DropdownMenuItem(
                            value: 'Partner',
                            child: Text(l10n.customersGroupPartner),
                          ),
                        ],
                        onChanged: (v) => ref
                            .read(customersFilterProvider.notifier)
                            .setGroup(v),
                      ),
                    ),
                    ActionChip(
                      avatar: Icon(
                        filter.sortOrder == 'asc'
                            ? LucideIcons.arrowUp
                            : LucideIcons.arrowDown,
                        size: 14,
                      ),
                      label: Text(switch (filter.sortBy) {
                        'name' => l10n.customersSortName,
                        'totalRevenue' => l10n.customersSortRevenue,
                        'ordersCount' => l10n.customersSortOrders,
                        _ => l10n.customersSortNewest,
                      }),
                      onPressed: () {
                        const cycle = [
                          'createdAt',
                          'name',
                          'totalRevenue',
                          'ordersCount',
                        ];
                        final nextIdx =
                            (cycle.indexOf(filter.sortBy) + 1) % cycle.length;
                        ref
                            .read(customersFilterProvider.notifier)
                            .setSort(cycle[nextIdx]);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Directory List
                listAsync.when(
                  loading: () => const AfabListSkeleton(count: 4),
                  error: (err, _) => AfabErrorState(
                    title: l10n.errorGenericTitle,
                    message: err.toString(),
                    retryLabel: l10n.commonRetry,
                    onRetry: () => ref.invalidate(customersListProvider),
                  ),
                  data: (page) {
                    if (page.content.isEmpty) {
                      return AfabEmptyState(
                        icon: LucideIcons.users,
                        title: l10n.customersEmptyTitle,
                        description: l10n.customersEmptyDesc,
                        actionLabel: isEditable ? l10n.customersAddBtn : null,
                        onAction: isEditable
                            ? () => showAddEditCustomerSheet(context)
                            : null,
                      );
                    }
                    return Column(
                      children: [
                        for (final c in page.content) ...[
                          _CustomerDirectoryCard(
                            customer: c,
                            currency: fallbackCurr,
                            selected: isExpanded && selectedId == c.id,
                            onTap: () => _openCustomer(c, isExpanded),
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
                                        .read(customersFilterProvider.notifier)
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
                                        .read(customersFilterProvider.notifier)
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
                          icon: LucideIcons.users,
                          title: l10n.customersDetailsTitle,
                          description: l10n.customersDetailsPrompt,
                        ),
                      )
                    : CustomerDetailsPane(
                        customerId: selectedId,
                        onArchived: () => ref
                            .read(selectedCustomerIdProvider.notifier)
                            .select(null),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CustomerCountKpiCard extends StatelessWidget {
  const _CustomerCountKpiCard({
    required this.title,
    required this.value,
    required this.changeText,
    required this.isPositive,
    required this.subLabel,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String value;
  final String changeText;
  final bool isPositive;
  final String subLabel;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    final deltaColor = isPositive ? colors.success : colors.danger;
    return AfabCard(
      topAccentColor: accentColor,
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
            child: Icon(icon, size: 17, color: colors.textMuted),
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
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AfabStatusBadge(
                label: changeText,
                variant: isPositive
                    ? AfabBadgeVariant.success
                    : AfabBadgeVariant.danger,
              ),
              Text(
                subLabel,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: deltaColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerSegmentsDonutCard extends StatelessWidget {
  const _CustomerSegmentsDonutCard({required this.donut});

  final CustomerOverviewDonutDto donut;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final total = donut.activeCount + donut.inactiveCount + donut.newCount;

    return AfabCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.customersOverviewTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (total == 0)
            AfabEmptyState(
              icon: LucideIcons.pieChart,
              title: l10n.commonNoData,
              description: l10n.customersEmptyDesc,
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 28,
                      sectionsSpace: 2,
                      sections: [
                        if (donut.activeCount > 0)
                          PieChartSectionData(
                            value: donut.activeCount.toDouble(),
                            color: colors.success,
                            radius: 20,
                            showTitle: false,
                          ),
                        if (donut.newCount > 0)
                          PieChartSectionData(
                            value: donut.newCount.toDouble(),
                            color: colors.info,
                            radius: 20,
                            showTitle: false,
                          ),
                        if (donut.inactiveCount > 0)
                          PieChartSectionData(
                            value: donut.inactiveCount.toDouble(),
                            color: colors.textMuted,
                            radius: 20,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SegmentLegendRow(
                        color: colors.success,
                        label: l10n.customersStatusActive,
                        count: donut.activeCount,
                        pct: donut.activePct,
                      ),
                      const SizedBox(height: 8),
                      _SegmentLegendRow(
                        color: colors.info,
                        label: l10n.customersStatusNew,
                        count: donut.newCount,
                        pct: donut.newPct,
                      ),
                      const SizedBox(height: 8),
                      _SegmentLegendRow(
                        color: colors.textMuted,
                        label: l10n.customersStatusInactive,
                        count: donut.inactiveCount,
                        pct: donut.inactivePct,
                      ),
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

class _SegmentLegendRow extends StatelessWidget {
  const _SegmentLegendRow({
    required this.color,
    required this.label,
    required this.count,
    required this.pct,
  });

  final Color color;
  final String label;
  final int count;
  final double pct;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            '$count (${pct.toStringAsFixed(0)}%)',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _CustomerDirectoryCard extends StatelessWidget {
  const _CustomerDirectoryCard({
    required this.customer,
    required this.currency,
    required this.selected,
    required this.onTap,
  });

  final CustomerDto customer;
  final String currency;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final statusVariant = switch (customer.status.toLowerCase()) {
      'active' => AfabBadgeVariant.success,
      'new' => AfabBadgeVariant.info,
      _ => AfabBadgeVariant.neutral,
    };

    return AfabCard(
      onTap: onTap,
      topAccentColor: selected ? colors.primary : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colors.secondaryBg,
            child: Text(
              customer.initials,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      customer.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    AfabStatusBadge(
                      label: customer.status,
                      variant: statusVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (customer.companyName != null &&
                        customer.companyName!.isNotEmpty)
                      customer.companyName!,
                    if (customer.customerCode.isNotEmpty) customer.customerCode,
                    if (customer.email != null && customer.email!.isNotEmpty)
                      customer.email!,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    MoneyText(
                      amount: customer.totalRevenue,
                      currency: currency,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colors.success,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (customer.outstandingBalance > Decimal.zero)
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          '${l10n.customersKpiOutstanding}: ${MoneyFormatter.formatDecimal(customer.outstandingBalance, currency: currency)}',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colors.warning,
                                  ),
                        ),
                      ),
                    Text(
                      l10n.customersOrdersCount(customer.ordersCount),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/navigation/copilot_prompt_request.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/calendar/domain/calendar_helpers.dart';
import 'package:afab_mobile/features/calendar/domain/calendar_providers.dart';
import 'package:afab_mobile/features/calendar/presentation/widgets/day_activity_sheet.dart';
import 'package:afab_mobile/features/invoices/data/invoice_dtos.dart';
import 'package:afab_mobile/features/recurring/data/recurring_dtos.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/afab_kpi_card.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:afab_mobile/shared/widgets/analytics_charts.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `BIZ-09`: Financial Calendar with per-month server date range queries,
/// optional Invoice Due / Recurring overlays, and clickable day ledger details.
class FinancialCalendarScreen extends ConsumerWidget {
  const FinancialCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final biz = ref.watch(activeBusinessProvider);
    final isEditable = !(biz?.isReadOnly ?? false);
    final baseCurrency = biz?.currency ?? 'USD';
    final dateFmt = biz?.dateFormat ?? 'YYYY-MM-DD';
    final locale = Localizations.localeOf(context).languageCode;

    final visibleMonth = ref.watch(visibleCalendarMonthProvider);
    final selectedIso = ref.watch(selectedCalendarDateProvider);
    final overlays = ref.watch(calendarOverlaysProvider);
    final summaryAsync =
        ref.watch(calendarMonthTransactionsProvider(visibleMonth));
    final dueInvoicesAsync = ref.watch(calendarDueInvoicesProvider);
    final recurringRunsAsync = ref.watch(calendarRecurringRunsProvider);

    final now = DateTime.now();
    final todayMonth = CalendarMonth.fromDateTime(now);
    final todayIso =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Group optional overlays by date (filtered to visibleMonth).
    final dueByDate = <String, List<InvoiceDto>>{};
    for (final inv in dueInvoicesAsync.value ?? const <InvoiceDto>[]) {
      final key = inv.dueDate.length >= 10
          ? inv.dueDate.substring(0, 10)
          : inv.dueDate;
      if (key.startsWith(visibleMonth.monthKey)) {
        dueByDate.putIfAbsent(key, () => []).add(inv);
      }
    }
    final recByDate = <String, List<RecurringTransactionDto>>{};
    for (final r in recurringRunsAsync.value ?? const <RecurringTransactionDto>[]) {
      final key = r.nextExecutionDate.length >= 10
          ? r.nextExecutionDate.substring(0, 10)
          : r.nextExecutionDate;
      if (key.startsWith(visibleMonth.monthKey)) {
        recByDate.putIfAbsent(key, () => []).add(r);
      }
    }

    final monthLabel = DateFormat.yMMMM(locale == 'ar' ? 'ar' : 'en_US').format(
      DateTime(visibleMonth.year, visibleMonth.month, 1),
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isExpanded = AfabBreakpoints.isExpandedTablet(width);
          final kpiCols = width >= 1024
              ? 4
              : AfabBreakpoints.kpiColumnsForWidth(width);
          final showInlineCellAmounts = width >= 600;

          final selectedDayTxs =
              summaryAsync.value?.byDate[selectedIso]?.transactions ?? const [];
          final selectedDayDue = dueByDate[selectedIso] ?? const <InvoiceDto>[];
          final selectedDayRec =
              recByDate[selectedIso] ?? const <RecurringTransactionDto>[];

          void onSelectDay(String isoDate) {
            ref.read(selectedCalendarDateProvider.notifier).select(isoDate);
            if (!isExpanded) {
              showDayActivitySheet(
                context,
                isoDate: isoDate,
                dateFormat: dateFmt,
                baseCurrency: baseCurrency,
                isEditable: isEditable,
                transactions: summaryAsync.value?.byDate[isoDate]?.transactions ??
                    const [],
                dueInvoices: dueByDate[isoDate] ?? const [],
                recurringRuns: recByDate[isoDate] ?? const [],
              );
            }
          }

          final calendarMainColumn = RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(calendarMonthTransactionsProvider(visibleMonth));
              await ref.read(
                calendarMonthTransactionsProvider(visibleMonth).future,
              );
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                isExpanded ? 24 : 16,
                16,
                16,
                32,
              ),
              children: [
                // Header
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
                          l10n.calendarTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.calendarSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        IconButton(
                          tooltip: l10n.moreHubAskCopilotTooltip,
                          icon: Icon(
                            LucideIcons.sparkles,
                            color: colors.primary,
                            size: 20,
                          ),
                          onPressed: () => context.go(
                            '/copilot',
                            extra: CopilotPromptRequest(
                              prompt:
                                  'Analyze my financial cash flow schedule for ${visibleMonth.monthKey} focusing on $selectedIso.',
                              screenContext: {
                                'page': 'calendar',
                                'month': visibleMonth.monthKey,
                                'selectedDate': selectedIso,
                              },
                            ),
                          ),
                        ),
                        if (isEditable)
                          AfabButton(
                            label: l10n.txAddButton,
                            icon: LucideIcons.plus,
                            compact: true,
                            onPressed: () => context.push(
                              '/transactions/new?date=$selectedIso',
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Month Stepper & Overlay Chips
                AfabCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: l10n.commonBack,
                                onPressed: () {
                                  final prev = visibleMonth.previous();
                                  ref
                                      .read(
                                        visibleCalendarMonthProvider.notifier,
                                      )
                                      .previousMonth();
                                  ref
                                      .read(
                                        selectedCalendarDateProvider.notifier,
                                      )
                                      .select(
                                        prev == todayMonth
                                            ? todayIso
                                            : prev.firstDayIso,
                                      );
                                },
                                icon: const Icon(LucideIcons.chevronLeft),
                              ),
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  monthLabel,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              IconButton(
                                tooltip: l10n.commonContinue,
                                onPressed: () {
                                  final next = visibleMonth.next();
                                  ref
                                      .read(
                                        visibleCalendarMonthProvider.notifier,
                                      )
                                      .nextMonth();
                                  ref
                                      .read(
                                        selectedCalendarDateProvider.notifier,
                                      )
                                      .select(
                                        next == todayMonth
                                            ? todayIso
                                            : next.firstDayIso,
                                      );
                                },
                                icon: const Icon(LucideIcons.chevronRight),
                              ),
                            ],
                          ),
                          if (visibleMonth != todayMonth)
                            ActionChip(
                              label: Text(l10n.calendarTodayBtn),
                              onPressed: () {
                                ref
                                    .read(visibleCalendarMonthProvider.notifier)
                                    .jumpToToday();
                                ref
                                    .read(selectedCalendarDateProvider.notifier)
                                    .select(todayIso);
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          FilterChip(
                            label: Text(l10n.calendarOverlayTransactions),
                            selected: true,
                            onSelected: (_) {},
                          ),
                          FilterChip(
                            label: Text(l10n.calendarOverlayInvoicesDue),
                            selected: overlays.showInvoicesDue,
                            onSelected: (_) => ref
                                .read(calendarOverlaysProvider.notifier)
                                .toggleInvoicesDue(),
                          ),
                          FilterChip(
                            label: Text(l10n.calendarOverlayRecurring),
                            selected: overlays.showRecurringRuns,
                            onSelected: (_) => ref
                                .read(calendarOverlaysProvider.notifier)
                                .toggleRecurringRuns(),
                          ),
                        ],
                      ),
                      if (overlays.anyOptionalActive) ...[
                        const SizedBox(height: 8),
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
                              Icon(LucideIcons.info, size: 15, color: colors.info),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.calendarOverlayNotice,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Monthly KPIs + Calendar Grid
                summaryAsync.when(
                  loading: () => const AfabCard(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: AfabLoader(size: 48)),
                    ),
                  ),
                  error: (err, _) => AfabErrorState(
                    title: l10n.errorGenericTitle,
                    message: err.toString(),
                    retryLabel: l10n.commonRetry,
                    onRetry: () => ref.invalidate(
                      calendarMonthTransactionsProvider(visibleMonth),
                    ),
                  ),
                  data: (summary) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (summary.truncated) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              l10n.calendarTruncatedNotice,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: colors.warning),
                            ),
                          ),
                        ],
                        AfabKpiWrapGrid(
                          columns: kpiCols,
                          children: [
                            AfabKpiCard(
                              title: l10n.calendarKpiInflow,
                              amount: summary.monthlyInflow,
                              currency: baseCurrency,
                              changeText: visibleMonth.monthKey,
                              isPositive: true,
                              periodComparisonLabel: l10n.txStatusCompleted,
                              icon: LucideIcons.arrowUpRight,
                              topAccentColor: colors.success,
                            ),
                            AfabKpiCard(
                              title: l10n.calendarKpiOutflow,
                              amount: summary.monthlyOutflow,
                              currency: baseCurrency,
                              changeText: visibleMonth.monthKey,
                              isPositive: false,
                              periodComparisonLabel: l10n.txStatusCompleted,
                              icon: LucideIcons.arrowDownLeft,
                              topAccentColor: colors.danger,
                            ),
                            _CalendarCountKpi(
                              title: l10n.calendarKpiPending,
                              count: summary.pendingCount,
                              caption: l10n.calendarAwaitingSettlement,
                              accentColor: colors.warning,
                              icon: LucideIcons.clock,
                            ),
                            _CalendarCountKpi(
                              title: l10n.calendarKpiEntries,
                              count: summary.totalCount,
                              caption: l10n.calendarEntriesCount(
                                summary.totalCount,
                              ),
                              accentColor: colors.primary,
                              icon: LucideIcons.calendarDays,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        AfabCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              // Weekday header row (Gregorian Sunday..Saturday)
                              Row(
                                children: [
                                  for (var i = 0; i < 7; i++)
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        child: Text(
                                          DateFormat.E(
                                            locale == 'ar' ? 'ar' : 'en_US',
                                          ).format(
                                            DateTime.utc(2026, 11, 1 + i),
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: colors.textMuted,
                                              ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: visibleMonth.firstWeekdayOffset +
                                    visibleMonth.daysInMonth,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  mainAxisSpacing: 4,
                                  crossAxisSpacing: 4,
                                  mainAxisExtent:
                                      showInlineCellAmounts ? 74 : 56,
                                ),
                                itemBuilder: (ctx, index) {
                                  if (index < visibleMonth.firstWeekdayOffset) {
                                    return const SizedBox.shrink();
                                  }
                                  final day = index -
                                      visibleMonth.firstWeekdayOffset +
                                      1;
                                  final iso = visibleMonth.dayIso(day);
                                  final metrics = summary.byDate[iso];
                                  final dayDue = dueByDate[iso] ?? const [];
                                  final dayRec = recByDate[iso] ?? const [];
                                  final isSelected = iso == selectedIso;
                                  final isToday = iso == todayIso;
                                  final count = (metrics?.transactions.length ?? 0) +
                                      dayDue.length +
                                      dayRec.length;

                                  return _CalendarDayCell(
                                    day: day,
                                    isToday: isToday,
                                    isSelected: isSelected,
                                    count: count,
                                    metrics: metrics,
                                    hasDue: dayDue.isNotEmpty,
                                    hasRecurring: dayRec.isNotEmpty,
                                    showAmounts: showInlineCellAmounts,
                                    currency: baseCurrency,
                                    onTap: () => onSelectDay(iso),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        if (!isExpanded) ...[
                          const SizedBox(height: 14),
                          AfabCard(
                            child: DayActivityContent(
                              isoDate: selectedIso,
                              dateFormat: dateFmt,
                              baseCurrency: baseCurrency,
                              isEditable: isEditable,
                              transactions: selectedDayTxs,
                              dueInvoices: selectedDayDue,
                              recurringRuns: selectedDayRec,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          );

          if (!isExpanded) return calendarMainColumn;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 62, child: calendarMainColumn),
              VerticalDivider(width: 1, color: colors.border),
              Expanded(
                flex: 38,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: AfabCard(
                    child: DayActivityContent(
                      isoDate: selectedIso,
                      dateFormat: dateFmt,
                      baseCurrency: baseCurrency,
                      isEditable: isEditable,
                      transactions: selectedDayTxs,
                      dueInvoices: selectedDayDue,
                      recurringRuns: selectedDayRec,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CalendarCountKpi extends StatelessWidget {
  const _CalendarCountKpi({
    required this.title,
    required this.count,
    required this.caption,
    required this.accentColor,
    required this.icon,
  });

  final String title;
  final int count;
  final String caption;
  final Color accentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
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
            child: Icon(icon, size: 17, color: accentColor),
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
              '$count',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.count,
    this.metrics,
    required this.hasDue,
    required this.hasRecurring,
    required this.showAmounts,
    required this.currency,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final bool isSelected;
  final int count;
  final CalendarDayMetrics? metrics;
  final bool hasDue;
  final bool hasRecurring;
  final bool showAmounts;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    final hasIn = (metrics?.completedIncome ?? Decimal.zero) > Decimal.zero;
    final hasOut = (metrics?.completedExpense ?? Decimal.zero) > Decimal.zero;

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Day $day, $count entries',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.12)
                : colors.surfaceInset,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? colors.primary
                  : (isToday
                      ? colors.primary.withValues(alpha: 0.5)
                      : colors.border),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          '$day',
                          maxLines: 1,
                          softWrap: false,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: isToday || isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isToday || isSelected
                                        ? colors.primary
                                        : colors.textPrimary,
                                  ),
                        ),
                      ),
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          '$count',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (showAmounts && (hasIn || hasOut))
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasIn)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: MoneyText(
                          amount: metrics!.completedIncome,
                          currency: currency,
                          showSign: true,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(fontSize: 10, color: colors.success),
                        ),
                      ),
                    if (hasOut)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: MoneyText(
                          amount: -metrics!.completedExpense,
                          currency: currency,
                          showSign: true,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(fontSize: 10, color: colors.danger),
                        ),
                      ),
                  ],
                )
              else
                Wrap(
                  spacing: 3,
                  runSpacing: 2,
                  children: [
                    if (hasIn) _Dot(color: colors.success),
                    if (hasOut) _Dot(color: colors.danger),
                    if (hasDue) _Dot(color: colors.warning),
                    if (hasRecurring) _Dot(color: colors.info),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:afab_mobile/core/navigation/copilot_prompt_request.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/color_parser.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/budgets/data/budget_dtos.dart';
import 'package:afab_mobile/features/budgets/data/budgets_repository.dart';
import 'package:afab_mobile/features/budgets/domain/budgets_providers.dart';
import 'package:afab_mobile/features/budgets/presentation/widgets/create_edit_budget_sheet.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `BIZ-07`: Budgets Management & Deterministic Threshold Alerts.
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  Future<void> _confirmArchive(
    BuildContext context,
    WidgetRef ref,
    BudgetDto budget,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.budgetsArchiveConfirmTitle),
        content: Text(l10n.budgetsArchiveConfirmDesc(budget.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.customersArchiveAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(budgetsRepositoryProvider).archiveBudget(budget.id);
      if (!context.mounted) return;
      invalidateBudgetProviders(ref);
      AfabToast.showSuccess(context, l10n.budgetsArchivedToast);
    } on AppFailure catch (e) {
      if (context.mounted) AfabToast.showError(context, e.message);
    }
  }

  void _askCopilot(BuildContext context, BudgetDto b) {
    final pct = b.percentageConsumed.toDouble().toStringAsFixed(1);
    context.go(
      '/copilot',
      extra: CopilotPromptRequest(
        prompt:
            'Analyze my budget "${b.name}" ($pct% consumed: ${b.actualSpending} / ${b.budgetAmount} ${b.currency}, ${b.startDate} to ${b.endDate}) and list the transactions driving it.',
        autoSend: true,
        screenContext: {
          'page': 'budgets',
          'budgetId': b.id,
          'budgetName': b.name,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final biz = ref.watch(activeBusinessProvider);
    final isEditable = !(biz?.isReadOnly ?? false);
    final fallbackCurr = biz?.currency ?? 'USD';
    final dateFmt = biz?.dateFormat ?? 'YYYY-MM-DD';
    final locale = Localizations.localeOf(context).languageCode;

    final includeArchived = ref.watch(includeArchivedBudgetsProvider);
    final summaryAsync = ref.watch(budgetOverviewSummaryProvider);
    final listAsync = ref.watch(budgetListProvider);

    return Scaffold(
      floatingActionButton: isEditable
          ? FloatingActionButton.extended(
              heroTag: 'budgets_new_fab',
              onPressed: () => showCreateEditBudgetSheet(context),
              icon: const Icon(LucideIcons.plus),
              label: Text(l10n.budgetsNewBtn),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isExpanded = AfabBreakpoints.isExpandedTablet(width);
          final kpiCols = width >= 1024
              ? 4
              : AfabBreakpoints.kpiColumnsForWidth(width);
          final cardCols = width >= 1200 ? 3 : (width >= 600 ? 2 : 1);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(budgetOverviewSummaryProvider);
              ref.invalidate(budgetListProvider);
              await Future.wait([
                ref.read(budgetOverviewSummaryProvider.future),
                ref.read(budgetListProvider.future),
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.budgetsTitle,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(width: 4),
                            Tooltip(
                              message: l10n.budgetsAggregationTip,
                              child: Icon(
                                LucideIcons.info,
                                size: 16,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.budgetsSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    AfabSegmentedBar<bool>(
                      items: [
                        AfabSegmentItem(
                          value: false,
                          label: l10n.budgetsFilterActiveOnly,
                        ),
                        AfabSegmentItem(
                          value: true,
                          label: l10n.budgetsFilterIncludeArchived,
                        ),
                      ],
                      selectedValue: includeArchived,
                      onSelected: (v) => ref
                          .read(includeArchivedBudgetsProvider.notifier)
                          .setIncludeArchived(v),
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
                    onRetry: () =>
                        ref.invalidate(budgetOverviewSummaryProvider),
                  ),
                  data: (summary) {
                    final curr = summary.currency.isNotEmpty
                        ? summary.currency
                        : fallbackCurr;
                    return AfabKpiWrapGrid(
                      columns: kpiCols,
                      children: [
                        _BudgetCountKpiCard(
                          title: l10n.budgetsKpiActive,
                          value: '${summary.activeBudgetCount}',
                          hint: l10n.budgetsTotalLimitHint(
                            MoneyFormatter.formatDecimal(
                              summary.totalBudgeted,
                              currency: curr,
                            ),
                          ),
                          icon: LucideIcons.piggyBank,
                          accentColor: colors.primary,
                        ),
                        AfabKpiCard(
                          title: l10n.budgetsKpiSpent,
                          amount: summary.totalSpent,
                          currency: curr,
                          changeText: l10n.dashboardBudgetsRemaining,
                          isPositive: true,
                          periodComparisonLabel: MoneyFormatter.formatDecimal(
                            summary.totalRemaining,
                            currency: curr,
                          ),
                          icon: LucideIcons.wallet,
                          topAccentColor: colors.info,
                        ),
                        _BudgetCountKpiCard(
                          title: l10n.budgetsKpiApproaching,
                          value: '${summary.approachingCount}',
                          hint: l10n.budgetsAlertApproaching,
                          icon: LucideIcons.triangleAlert,
                          accentColor: colors.warning,
                        ),
                        _BudgetCountKpiCard(
                          title: l10n.budgetsKpiOver,
                          value: '${summary.overBudgetCount}',
                          hint: l10n.budgetsAlertOver,
                          icon: LucideIcons.circleAlert,
                          accentColor: colors.danger,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 18),
                listAsync.when(
                  loading: () => const AfabListSkeleton(count: 3),
                  error: (err, _) => AfabErrorState(
                    title: l10n.errorGenericTitle,
                    message: err.toString(),
                    retryLabel: l10n.commonRetry,
                    onRetry: () => ref.invalidate(budgetListProvider),
                  ),
                  data: (budgets) {
                    if (budgets.isEmpty) {
                      return AfabEmptyState(
                        icon: LucideIcons.piggyBank,
                        title: l10n.budgetsEmptyTitle,
                        description: l10n.budgetsEmptyDesc,
                        actionLabel:
                            isEditable ? l10n.budgetsCreateFirstBtn : null,
                        onAction: isEditable
                            ? () => showCreateEditBudgetSheet(context)
                            : null,
                      );
                    }
                    final cards = [
                      for (final b in budgets)
                        _BudgetCard(
                          budget: b,
                          dateFormat: dateFmt,
                          locale: locale,
                          isEditable: isEditable,
                          onAskAi: () => _askCopilot(context, b),
                          onEdit: (isEditable && !b.isArchived)
                              ? () => showCreateEditBudgetSheet(
                                    context,
                                    editingBudget: b,
                                  )
                              : null,
                          onArchive: (isEditable && !b.isArchived)
                              ? () => _confirmArchive(context, ref, b)
                              : null,
                        ),
                    ];
                    if (cardCols == 1) {
                      return Column(
                        children: [
                          for (final card in cards) ...[
                            card,
                            const SizedBox(height: 12),
                          ],
                        ],
                      );
                    }
                    return AfabKpiWrapGrid(columns: cardCols, children: cards);
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

class _BudgetCountKpiCard extends StatelessWidget {
  const _BudgetCountKpiCard({
    required this.title,
    required this.value,
    required this.hint,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String value;
  final String hint;
  final IconData icon;
  final Color accentColor;

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
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.dateFormat,
    required this.locale,
    required this.isEditable,
    required this.onAskAi,
    this.onEdit,
    this.onArchive,
  });

  final BudgetDto budget;
  final String dateFormat;
  final String locale;
  final bool isEditable;
  final VoidCallback onAskAi;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final (barColor, badgeVariant, alertLabel) =
        switch (budget.alertLevel.toUpperCase()) {
      'OVER_BUDGET' => (
          colors.danger,
          AfabBadgeVariant.danger,
          l10n.budgetsAlertOver,
        ),
      'APPROACHING' => (
          colors.warning,
          AfabBadgeVariant.warning,
          l10n.budgetsAlertApproaching,
        ),
      _ => (
          colors.success,
          AfabBadgeVariant.success,
          l10n.budgetsAlertOnTrack,
        ),
    };

    final periodLabel = switch (budget.periodType) {
      'QUARTERLY' => l10n.budgetsPeriodQuarterly,
      'YEARLY' => l10n.budgetsPeriodYearly,
      'CUSTOM' => l10n.budgetsPeriodCustom,
      _ => l10n.budgetsPeriodMonthly,
    };

    final pctVal = budget.percentageConsumed.toDouble();
    final progress = (pctVal / 100.0).clamp(0.0, 1.0);
    final startStr = AfabDateFormatter.formatIsoDate(
      budget.startDate,
      dateFormat: dateFormat,
      locale: locale,
    );
    final endStr = AfabDateFormatter.formatIsoDate(
      budget.endDate,
      dateFormat: dateFormat,
      locale: locale,
    );

    return AfabCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          budget.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        AfabStatusBadge(
                          label: alertLabel,
                          variant: badgeVariant,
                        ),
                        if (budget.isArchived)
                          AfabStatusBadge(
                            label: l10n.budgetsStatusArchived,
                            variant: AfabBadgeVariant.neutral,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (budget.categoryColor != null) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: ColorParser.parseHex(
                                budget.categoryColor,
                                colors.primary,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            '${budget.categoryName ?? l10n.budgetsAllBusinessExpenses} · $periodLabel ($startStr → $endStr)',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: l10n.budgetsAskCopilot,
                    icon: Icon(
                      LucideIcons.sparkles,
                      size: 18,
                      color: colors.primary,
                    ),
                    onPressed: onAskAi,
                  ),
                  if (onEdit != null)
                    IconButton(
                      tooltip: l10n.commonEdit,
                      icon: Icon(
                        LucideIcons.pencil,
                        size: 18,
                        color: colors.textMuted,
                      ),
                      onPressed: onEdit,
                    ),
                  if (onArchive != null)
                    IconButton(
                      tooltip: l10n.customersArchiveAction,
                      icon: Icon(
                        LucideIcons.trash2,
                        size: 18,
                        color: colors.danger,
                      ),
                      onPressed: onArchive,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  MoneyText(
                    amount: budget.actualSpending,
                    currency: budget.currency,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text('/', style: Theme.of(context).textTheme.bodySmall),
                  MoneyText(
                    amount: budget.budgetAmount,
                    currency: budget.currency,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  '${pctVal.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: barColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label: '${budget.name}: ${pctVal.toStringAsFixed(1)}% ${budget.alertLevel}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      budget.overBudgetAmount > Decimal.zero
                          ? '${l10n.dashboardBudgetsOverBy}: '
                          : '${l10n.dashboardBudgetsRemaining}: ',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: budget.overBudgetAmount > Decimal.zero
                                ? colors.danger
                                : null,
                          ),
                    ),
                  ),
                  MoneyText(
                    amount: budget.overBudgetAmount > Decimal.zero
                        ? budget.overBudgetAmount
                        : budget.remainingAmount,
                    currency: budget.currency,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: budget.overBudgetAmount > Decimal.zero
                              ? colors.danger
                              : colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              Text(
                l10n.budgetsAlertAt(budget.alertThresholdPercent),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

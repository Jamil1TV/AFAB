import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BudgetOverviewCard extends StatelessWidget {
  const BudgetOverviewCard({
    super.key,
    required this.budgets,
  });

  final BudgetSummaryDto? budgets;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final items = budgets?.budgets.take(6).toList() ?? const <BudgetProgressDto>[];

    return AfabCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dashboardBudgetsTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    budgets != null && budgets!.activeBudgetCount > 0
                        ? l10n.dashboardBudgetsSubtitleActive(
                            budgets!.activeBudgetCount,
                            budgets!.overBudgetCount,
                            budgets!.approachingCount,
                          )
                        : l10n.dashboardBudgetsSubtitleEmpty,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
              final manageButton = TextButton(
                onPressed: () => context.go('/budgets'),
                child: Text(l10n.dashboardBudgetsManageLink),
              );

              if (constraints.maxWidth < 310) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleBlock,
                    const SizedBox(height: 4),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: manageButton,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: titleBlock),
                  manageButton,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            AfabEmptyState(
              icon: LucideIcons.piggyBank,
              title: l10n.commonNoData,
              description: l10n.dashboardBudgetsEmpty,
              actionLabel: l10n.dashboardBudgetsManageLink,
              onAction: () => context.go('/budgets'),
            )
          else
            for (var i = 0; i < items.length; i++) ...[
              _BudgetBar(item: items[i], colors: colors),
              if (i < items.length - 1) const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _BudgetBar extends StatelessWidget {
  const _BudgetBar({required this.item, required this.colors});

  final BudgetProgressDto item;
  final AfabColors colors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (barColor, badgeVariant, statusLabel) =
        switch (item.alertLevel.toUpperCase()) {
      'OVER_BUDGET' => (
          colors.danger,
          AfabBadgeVariant.danger,
          l10n.dashboardBudgetsOverLabel,
        ),
      'APPROACHING' => (
          colors.warning,
          AfabBadgeVariant.warning,
          l10n.dashboardBudgetsApproachingLabel,
        ),
      _ => (
          colors.success,
          AfabBadgeVariant.success,
          l10n.dashboardBudgetsOnTrackLabel,
        ),
    };
    final progress = (item.percentageConsumed / 100.0).clamp(0.0, 1.0);

    return AfabInsetPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(width: 8),
              AfabStatusBadge(label: statusLabel, variant: badgeVariant),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: colors.border,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  '${item.percentageConsumed.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: barColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        item.overBudgetAmount.toDouble() > 0
                            ? '${l10n.dashboardBudgetsOverBy}: '
                            : '${l10n.dashboardBudgetsRemaining}: ',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    MoneyText(
                      amount: item.overBudgetAmount.toDouble() > 0
                          ? item.overBudgetAmount
                          : item.remainingAmount,
                      currency: item.currency,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
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

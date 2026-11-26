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

class RecentTransactionsCard extends StatelessWidget {
  const RecentTransactionsCard({
    super.key,
    required this.transactions,
    required this.currency,
  });

  final List<RecentTransactionItemDto> transactions;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;

    return AfabCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.dashboardRecentTransactionsTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/transactions'),
                child: Text(l10n.commonViewAll),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (transactions.isEmpty)
            AfabEmptyState(
              icon: LucideIcons.arrowRightLeft,
              title: l10n.commonNoData,
              description: l10n.dashboardRecentTransactionsEmpty,
            )
          else
            for (var i = 0; i < transactions.length; i++) ...[
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: transactions[i].id.isNotEmpty
                    ? () => context.push('/transactions/${transactions[i].id}')
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _TxRow(item: transactions[i], currency: currency),
                ),
              ),
              if (i < transactions.length - 1)
                Divider(height: 16, color: colors.border),
            ],
        ],
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  const _TxRow({required this.item, required this.currency});

  final RecentTransactionItemDto item;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    final tint = item.isCredit ? colors.success : colors.danger;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            item.initials,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: tint,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                item.date,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            MoneyText(
              amount: item.isCredit ? item.rawAmount : -item.rawAmount,
              currency: currency,
              showSign: true,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: tint,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            AfabStatusBadge(
              label: item.status,
              variant: switch (item.status.toUpperCase()) {
                'COMPLETED' => AfabBadgeVariant.success,
                'PENDING' => AfabBadgeVariant.warning,
                'CANCELLED' => AfabBadgeVariant.danger,
                _ => AfabBadgeVariant.neutral,
              },
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TopCustomersCard extends StatelessWidget {
  const TopCustomersCard({
    super.key,
    required this.customers,
    required this.currency,
  });

  final List<TopCustomerItemDto> customers;
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
                  l10n.dashboardCustomersTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/customers'),
                child: Text(l10n.commonViewAll),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (customers.isEmpty)
            AfabEmptyState(
              icon: LucideIcons.users,
              title: l10n.commonNoData,
              description: l10n.dashboardCustomersEmpty,
            )
          else
            for (var i = 0; i < customers.length; i++) ...[
              InkWell(
                onTap: () => context.push('/customers/${customers[i].id}'),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: colors.secondaryBg,
                        child: Text(
                          customers[i].avatar,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
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
                            Text(
                              customers[i].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              l10n.dashboardCustomersInRevenue,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      MoneyText(
                        amount: customers[i].revenue,
                        currency: currency,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: colors.success,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              if (i < customers.length - 1)
                Divider(height: 16, color: colors.border),
            ],
        ],
      ),
    );
  }
}

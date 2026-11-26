import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Expense categories donut card.
/// Fixes Web `ExpenseCategories.tsx` `$0.00` bug by reading numeric
/// `ExpenseCategorySliceDto.numericValue` (`value` field) instead of parsing
/// `"USD 500.00"`.
class ExpenseCategoriesCard extends StatelessWidget {
  const ExpenseCategoriesCard({
    super.key,
    required this.categories,
    required this.currency,
  });

  final List<ExpenseCategorySliceDto> categories;
  final String currency;

  Color _parseColor(String raw, Color fallback) {
    final clean = raw.trim().replaceFirst('#', '');
    if (RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(clean)) {
      return Color(int.parse('FF$clean', radix: 16));
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final total = categories.fold<Decimal>(
      Decimal.zero,
      (sum, item) => sum + item.numericValue,
    );

    return AfabCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardExpenseCategoriesTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          if (categories.isEmpty || total <= Decimal.zero)
            AfabEmptyState(
              icon: LucideIcons.pieChart,
              title: l10n.commonNoData,
              description: l10n.dashboardExpenseCategoriesEmpty,
            )
          else ...[
            SizedBox(
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      centerSpaceRadius: 48,
                      sectionsSpace: 2,
                      sections: [
                        for (var i = 0; i < categories.length; i++)
                          PieChartSectionData(
                            value: categories[i].numericValue.toDouble(),
                            color: _parseColor(
                              categories[i].colorHex,
                              colors.chartPalette[i % colors.chartPalette.length],
                            ),
                            radius: 24,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 84,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.dashboardExpenseCategoriesTotal,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 2),
                        MoneyText(
                          amount: total,
                          currency: currency,
                          compact: true,
                          alignment: Alignment.center,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < categories.length; i++) ...[
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _parseColor(
                        categories[i].colorHex,
                        colors.chartPalette[i % colors.chartPalette.length],
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      categories[i].name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  MoneyText(
                    amount: categories[i].numericValue,
                    currency: currency,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              if (i < categories.length - 1) const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

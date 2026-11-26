import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class RevenueAreaChart extends StatelessWidget {
  const RevenueAreaChart({
    super.key,
    required this.points,
    required this.currency,
  });

  final List<RevenueDataPointDto> points;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final locale = Localizations.localeOf(context).languageCode;
    final hasNonZero =
        points.any((p) => p.revenue > 0 || p.expenses > 0);
    final displayPoints = points.isNotEmpty
        ? points
        : const [
            RevenueDataPointDto(month: '2026-01', name: 'Jan', revenue: 0, expenses: 0),
            RevenueDataPointDto(month: '2026-02', name: 'Feb', revenue: 0, expenses: 0),
          ];

    var maxVal = 100.0;
    for (final p in displayPoints) {
      if (p.revenue > maxVal) maxVal = p.revenue;
      if (p.expenses > maxVal) maxVal = p.expenses;
    }

    return AfabCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dashboardRevenueChartTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.dashboardRevenueChartSubtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (!hasNonZero)
                AfabStatusBadge(
                  label: l10n.dashboardAwaitingData,
                  variant: AfabBadgeVariant.neutral,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            children: [
              _LegendItem(color: colors.primary, label: l10n.dashboardRevenueLabel),
              _LegendItem(color: colors.info, label: l10n.dashboardExpensesLabel),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxVal * 1.15,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: colors.border,
                      strokeWidth: 1,
                      dashArray: const [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (value, meta) => Text(
                          MoneyFormatter.formatCompact(
                            MoneyFormatter.parseDecimal(value),
                            currency: currency,
                          ),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= displayPoints.length) {
                            return const SizedBox.shrink();
                          }
                          final label = AfabDateFormatter.formatYearMonthShort(
                            displayPoints[idx].month,
                            locale,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              label,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xE60C101C),
                      getTooltipItems: (spots) {
                        return spots.map((s) {
                          final isRev = s.barIndex == 0;
                          final lbl = isRev
                              ? l10n.dashboardRevenueLabel
                              : l10n.dashboardExpensesLabel;
                          return LineTooltipItem(
                            '$lbl: ${MoneyFormatter.formatNum(s.y, currency: currency)}',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < displayPoints.length; i++)
                          FlSpot(i.toDouble(), displayPoints[i].revenue),
                      ],
                      isCurved: true,
                      color: colors.primary,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colors.primary.withValues(alpha: 0.14),
                      ),
                    ),
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < displayPoints.length; i++)
                          FlSpot(i.toDouble(), displayPoints[i].expenses),
                      ],
                      isCurved: true,
                      color: colors.info,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: colors.info.withValues(alpha: 0.10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

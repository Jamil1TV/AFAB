import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/color_parser.dart';
import 'package:afab_mobile/features/expenses/data/expense_dtos.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AfabKpiWrapGrid extends StatelessWidget {
  const AfabKpiWrapGrid({
    super.key,
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

/// Interactive daily Area Chart handling empty and single-point series cleanly
/// without `fl_chart` `minX == maxX` crashes.
class DailyTrendAreaChart extends StatelessWidget {
  const DailyTrendAreaChart({
    super.key,
    required this.title,
    required this.totalAmount,
    required this.currency,
    required this.points,
    required this.emptyText,
    required this.accentColor,
    this.badgeDotColor,
    this.subtitle,
  });

  final String title;
  final Decimal totalAmount;
  final String currency;
  final List<DailyOverviewPointDto> points;
  final String emptyText;
  final Color accentColor;
  final Color? badgeDotColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;

    var maxVal = 100.0;
    for (final p in points) {
      if (p.amount > maxVal) maxVal = p.amount;
    }

    final isSingle = points.length == 1;
    final minX = isSingle ? -0.5 : 0.0;
    final maxX = isSingle
        ? 0.5
        : (points.isEmpty ? 1.0 : (points.length - 1).toDouble());
    final step = points.length <= 6
        ? 1.0
        : (points.length / 5).ceilToDouble();

    return AfabCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: (badgeDotColor ?? accentColor).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color:
                        (badgeDotColor ?? accentColor).withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: badgeDotColor ?? accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    MoneyText(
                      amount: totalAmount,
                      currency: currency,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (points.isEmpty)
            AfabEmptyState(
              icon: LucideIcons.trendingUp,
              title: l10n.commonNoData,
              description: emptyText,
            )
          else
            SizedBox(
              height: 210,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: LineChart(
                  LineChartData(
                    minX: minX,
                    maxX: maxX,
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
                          getTitlesWidget: (val, _) => Text(
                            MoneyFormatter.formatCompact(
                              MoneyFormatter.parseDecimal(val),
                              currency: currency,
                            ),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: step,
                          getTitlesWidget: (val, _) {
                            final idx = val.round();
                            if ((val - idx).abs() > 0.05 ||
                                idx < 0 ||
                                idx >= points.length) {
                              return const SizedBox.shrink();
                            }
                            final rawDate = points[idx].date;
                            final shortLabel = rawDate.length >= 10
                                ? rawDate.substring(5, 10)
                                : rawDate;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                shortLabel,
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
                        getTooltipItems: (spots) => spots.map((s) {
                          final idx = s.x.round();
                          final dateStr =
                              (idx >= 0 && idx < points.length)
                                  ? '${points[idx].date}\n'
                                  : '';
                          return LineTooltipItem(
                            '$dateStr${MoneyFormatter.formatNum(s.y, currency: currency)}',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < points.length; i++)
                            FlSpot(i.toDouble(), points[i].amount),
                        ],
                        isCurved: points.length > 2,
                        color: accentColor,
                        barWidth: 2.5,
                        dotData: FlDotData(show: points.length <= 2),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              accentColor.withValues(alpha: 0.34),
                              accentColor.withValues(alpha: 0.0),
                            ],
                          ),
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

class CategoryBreakdownDonutCard extends StatelessWidget {
  const CategoryBreakdownDonutCard({
    super.key,
    required this.title,
    required this.centerSubtitle,
    required this.totalAmount,
    required this.currency,
    required this.items,
    required this.emptyText,
    required this.fallbackPalette,
  });

  final String title;
  final String centerSubtitle;
  final Decimal totalAmount;
  final String currency;
  final List<CategoryBreakdownItemDto> items;
  final String emptyText;
  final List<Color> fallbackPalette;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final hasPositive = items.any((i) => i.amount > Decimal.zero);

    return AfabCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          if (items.isEmpty || !hasPositive)
            AfabEmptyState(
              icon: LucideIcons.layers,
              title: l10n.commonNoData,
              description: emptyText,
            )
          else ...[
            SizedBox(
              height: 175,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      centerSpaceRadius: 48,
                      sectionsSpace: 2,
                      sections: [
                        for (var i = 0; i < items.length; i++)
                          PieChartSectionData(
                            value: items[i].amount.toDouble(),
                            color: ColorParser.parseHex(
                              items[i].color,
                              fallbackPalette[i % fallbackPalette.length],
                            ),
                            radius: 24,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        centerSubtitle,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: 90,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: MoneyText(
                            amount: totalAmount,
                            currency: currency,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < items.length && i < 5; i++) ...[
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: ColorParser.parseHex(
                        items[i].color,
                        fallbackPalette[i % fallbackPalette.length],
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textPrimary,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  MoneyText(
                    amount: items[i].amount,
                    currency: currency,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
              if (i < items.length - 1 && i < 4) const SizedBox(height: 8),
            ],
          ],
        ],
      ),
    );
  }
}

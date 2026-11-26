import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AfabKpiCard extends StatelessWidget {
  const AfabKpiCard({
    super.key,
    required this.title,
    required this.amount,
    required this.currency,
    required this.changeText,
    required this.isPositive,
    required this.periodComparisonLabel,
    required this.icon,
    this.sparklineData = const [],
    this.onAskAi,
    this.askAiTooltip,
    this.topAccentColor,
  });

  final String title;
  final Decimal amount;
  final String currency;
  final String changeText;
  final bool isPositive;
  final String periodComparisonLabel;
  final IconData icon;
  final List<double> sparklineData;
  final VoidCallback? onAskAi;
  final String? askAiTooltip;
  final Color? topAccentColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    final deltaColor = isPositive ? colors.success : colors.danger;
    final hasSeries = sparklineData.length >= 2 &&
        sparklineData.any((element) => element != 0);

    return AfabCard(
      topAccentColor: topAccentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: colors.surfaceInset,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: Icon(icon, size: 16, color: colors.textMuted),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onAskAi != null) ...[
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: IconButton(
                          tooltip: askAiTooltip,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onAskAi,
                          icon: Icon(
                            LucideIcons.sparkles,
                            size: 14,
                            color: colors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerEnd,
                        child: SizedBox(
                          width: 46,
                          height: 24,
                          child: _Sparkline(
                            points:
                                hasSeries ? sparklineData : const [0, 0, 0],
                            color: hasSeries ? deltaColor : colors.textMuted,
                            dashed: !hasSeries,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: MoneyText(
              amount: amount,
              currency: currency,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: deltaColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? LucideIcons.trendingUp
                            : LucideIcons.trendingDown,
                        size: 12,
                        color: deltaColor,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          changeText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: deltaColor,
                                    fontWeight: FontWeight.w700,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                periodComparisonLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({
    required this.points,
    required this.color,
    required this.dashed,
  });

  final List<double> points;
  final Color color;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i]),
    ];
    final minVal = points.reduce((a, b) => a < b ? a : b);
    final maxVal = points.reduce((a, b) => a > b ? a : b);
    final pad = (maxVal - minVal).abs() < 0.001 ? 1.0 : (maxVal - minVal) * 0.2;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        minY: minVal - pad,
        maxY: maxVal + pad,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: !dashed,
            color: dashed ? color.withValues(alpha: 0.4) : color,
            barWidth: 2,
            isStrokeCapRound: true,
            dashArray: dashed ? const [4, 3] : null,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';

import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/ai/data/ai_dtos.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CopilotChartCard extends StatelessWidget {
  const CopilotChartCard({super.key, required this.chart});

  final AiChartSpecDto chart;

  static const List<Color> _palette = [
    Color(0xFF7C3AED),
    Color(0xFF10B981),
    Color(0xFF0EA5E9),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFFEC4899),
  ];

  Color _resolveSeriesColor(String token, int index, AfabColors colors) {
    return switch (token.toLowerCase()) {
      'primary' => colors.primary,
      'emerald' => colors.success,
      'rose' => colors.danger,
      'amber' => colors.warning,
      'sky' => colors.info,
      _ => _palette[index % _palette.length],
    };
  }

  double _numVal(Map<String, dynamic> row, String key) {
    final v = row[key];
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  Future<void> _exportCsv(BuildContext context) async {
    final xKey = chart.xKey.isEmpty ? 'name' : chart.xKey;
    final keys = [xKey, ...chart.series.map((s) => s.key)];
    String escape(String s) => '"${s.replaceAll('"', '""')}"';
    final rows = <String>[
      keys.map(escape).join(','),
      for (final row in chart.data)
        keys.map((k) => escape('${row[k] ?? ''}')).join(','),
    ];
    try {
      final dir = await getTemporaryDirectory();
      final slug = chart.title
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');
      final file = File(
        '${dir.path}/${slug.isEmpty ? 'copilot-chart' : slug}.csv',
      );
      await file.writeAsString('\uFEFF${rows.join('\r\n')}');
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: 'text/csv')]),
      );
    } catch (e) {
      if (context.mounted) {
        AfabToast.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (chart.data.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final colors = context.afabColors;
    final curr = chart.currency ?? 'USD';
    final chartHeight = MediaQuery.sizeOf(context).width < 360 ? 190.0 : 210.0;

    return AfabInsetPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chart.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (chart.subtitle != null &&
                        chart.subtitle!.trim().isNotEmpty)
                      Text(
                        chart.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _exportCsv(context),
                icon: const Icon(LucideIcons.download, size: 13),
                label: const Text('CSV'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: chartHeight,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: switch (chart.chartType) {
                'donut' || 'pie' => _buildDonut(colors, curr),
                'line' || 'area' => _buildLineOrArea(
                    colors,
                    curr,
                    fillArea: chart.chartType == 'area',
                  ),
                _ => _buildBar(colors, curr),
              },
            ),
          ),
          if (chart.series.length > 1) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                for (var i = 0; i < chart.series.length; i++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: _resolveSeriesColor(
                            chart.series[i].colorToken,
                            i,
                            colors,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        chart.series[i].label,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
              ],
            ),
          ] else if (chart.series.isEmpty) ...[
            const SizedBox(height: 4),
            Text(
              l10n.commonNoData,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDonut(AfabColors colors, String currency) {
    final key = chart.series.isNotEmpty ? chart.series.first.key : 'value';
    final xKey = chart.xKey.isEmpty ? 'name' : chart.xKey;
    final total = chart.data.fold<double>(
      0,
      (sum, row) => sum + _numVal(row, key).abs(),
    );

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 34,
              sectionsSpace: 2,
              sections: [
                for (var i = 0; i < chart.data.length; i++)
                  PieChartSectionData(
                    value: _numVal(chart.data[i], key).abs().clamp(0.01, 1e12),
                    color: _palette[i % _palette.length],
                    radius: 36,
                    showTitle: total > 0 &&
                        (_numVal(chart.data[i], key).abs() / total) >= 0.08,
                    title: total > 0
                        ? '${((_numVal(chart.data[i], key).abs() / total) * 100).round()}%'
                        : '',
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < chart.data.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _palette[i % _palette.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${chart.data[i][xKey] ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          MoneyFormatter.formatCompact(
                            Decimal.parse(
                              _numVal(chart.data[i], key).toStringAsFixed(2),
                            ),
                            currency: currency,
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLineOrArea(
    AfabColors colors,
    String currency, {
    required bool fillArea,
  }) {
    final xKey = chart.xKey.isEmpty ? 'name' : chart.xKey;
    final series = chart.series.isNotEmpty
        ? chart.series
        : const [
            AiChartSeriesSpecDto(
              key: 'value',
              label: 'Value',
              colorToken: 'primary',
            ),
          ];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: colors.border.withValues(alpha: 0.6), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (v, _) => Text(
                MoneyFormatter.formatCompact(
                  Decimal.parse(v.toStringAsFixed(0)),
                  currency: currency,
                ),
                style: TextStyle(fontSize: 10, color: colors.textMuted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: chart.data.length > 6
                  ? (chart.data.length / 4).ceilToDouble()
                  : 1,
              getTitlesWidget: (v, _) {
                final idx = v.round();
                if (idx < 0 || idx >= chart.data.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${chart.data[idx][xKey] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: colors.textMuted),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          for (var si = 0; si < series.length; si++)
            LineChartBarData(
              isCurved: chart.data.length > 2,
              color: _resolveSeriesColor(series[si].colorToken, si, colors),
              barWidth: 2.5,
              dotData: FlDotData(show: chart.data.length <= 12),
              belowBarData: BarAreaData(
                show: fillArea,
                color: _resolveSeriesColor(series[si].colorToken, si, colors)
                    .withValues(alpha: 0.14),
              ),
              spots: [
                for (var di = 0; di < chart.data.length; di++)
                  FlSpot(di.toDouble(), _numVal(chart.data[di], series[si].key)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBar(AfabColors colors, String currency) {
    final xKey = chart.xKey.isEmpty ? 'name' : chart.xKey;
    final series = chart.series.isNotEmpty
        ? chart.series
        : const [
            AiChartSeriesSpecDto(
              key: 'value',
              label: 'Value',
              colorToken: 'primary',
            ),
          ];

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: colors.border.withValues(alpha: 0.6), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (v, _) => Text(
                MoneyFormatter.formatCompact(
                  Decimal.parse(v.toStringAsFixed(0)),
                  currency: currency,
                ),
                style: TextStyle(fontSize: 10, color: colors.textMuted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final idx = v.round();
                if (idx < 0 || idx >= chart.data.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${chart.data[idx][xKey] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: colors.textMuted),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var di = 0; di < chart.data.length; di++)
            BarChartGroupData(
              x: di,
              barRods: [
                for (var si = 0; si < series.length; si++)
                  BarChartRodData(
                    toY: _numVal(chart.data[di], series[si].key),
                    color: _resolveSeriesColor(
                      series[si].colorToken,
                      si,
                      colors,
                    ),
                    width: series.length > 1 ? 8 : 14,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

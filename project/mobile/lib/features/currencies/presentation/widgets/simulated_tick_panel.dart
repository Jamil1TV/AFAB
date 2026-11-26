import 'dart:async';
import 'dart:math' as math;

import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_segmented_bar.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum SimulatedChartStyle { wave, candles }

class _SimCandle {
  const _SimCandle({
    required this.open,
    required this.close,
    required this.high,
    required this.low,
    required this.timeLabel,
    required this.volume,
  });

  final double open;
  final double close;
  final double high;
  final double low;
  final String timeLabel;
  final double volume;
}

/// Client-side 1s simulated tick chart anchored to live mid-market `spotRate`.
/// Clearly labeled "Simulated 1s Tick (Anchored to Spot)" per ADR-06, never claiming
/// to be an external WebSocket feed. Automatically pauses on background lifecycle.
class SimulatedTickPanel extends StatefulWidget {
  const SimulatedTickPanel({
    super.key,
    required this.pairSymbol,
    required this.spotRate,
    this.showTradeFeed = true,
  });

  final String pairSymbol;
  final double spotRate;
  final bool showTradeFeed;

  @override
  State<SimulatedTickPanel> createState() => _SimulatedTickPanelState();
}

class _SimulatedTickPanelState extends State<SimulatedTickPanel>
    with WidgetsBindingObserver {
  SimulatedChartStyle _style = SimulatedChartStyle.candles;
  String _interval = '1s';
  bool _paused = false;
  Timer? _timer;
  int _tickIndex = 0;
  final List<_SimCandle> _candles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _seedInitial();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant SimulatedTickPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pairSymbol != widget.pairSymbol ||
        (oldWidget.spotRate - widget.spotRate).abs() > 0.00001) {
      _seedInitial();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed && !_paused) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  void _seedInitial() {
    _candles.clear();
    _tickIndex = 0;
    final anchor = widget.spotRate <= 0 ? 1.0 : widget.spotRate;
    for (var i = 0; i < 20; i++) {
      _candles.add(_nextCandle(anchor, i));
    }
    _tickIndex = 20;
  }

  _SimCandle _nextCandle(double anchor, int step) {
    final prevClose = _candles.isEmpty ? anchor : _candles.last.close;
    final wave = math.sin(step * 0.55) * (anchor * 0.0018) +
        math.cos(step * 0.27) * (anchor * 0.0009);
    final close = math.max(anchor * 0.5, anchor + wave);
    final span = (close - prevClose).abs();
    final wick = math.max(anchor * 0.0004, span * 0.45);
    final high = math.max(prevClose, close) + wick;
    final low = math.max(0.0001, math.min(prevClose, close) - wick);
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    return _SimCandle(
      open: prevClose,
      close: close,
      high: high,
      low: low,
      timeLabel: timeStr,
      volume: 1200 + (math.sin(step * 0.9).abs() * 3800),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    final period = switch (_interval) {
      '5s' => const Duration(seconds: 5),
      '1m' => const Duration(seconds: 10),
      '15m' => const Duration(seconds: 15),
      _ => const Duration(seconds: 1),
    };
    _timer = Timer.periodic(period, (_) {
      if (!mounted || _paused) return;
      setState(() {
        final anchor = widget.spotRate <= 0 ? 1.0 : widget.spotRate;
        _candles.add(_nextCandle(anchor, _tickIndex++));
        if (_candles.length > 28) {
          _candles.removeAt(0);
        }
      });
    });
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    if (_paused) {
      _timer?.cancel();
    } else {
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final latest = _candles.isNotEmpty ? _candles.last.close : widget.spotRate;

    return AfabCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      widget.pairSymbol,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: l10n.currenciesSimulatedTooltip,
                    child: AfabStatusBadge(
                      label: l10n.currenciesSimulatedBadge,
                      variant: AfabBadgeVariant.info,
                      icon: LucideIcons.activity,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AfabSegmentedBar<SimulatedChartStyle>(
                    items: [
                      AfabSegmentItem(
                        value: SimulatedChartStyle.candles,
                        label: l10n.currenciesChartCandles,
                      ),
                      AfabSegmentItem(
                        value: SimulatedChartStyle.wave,
                        label: l10n.currenciesChartWave,
                      ),
                    ],
                    selectedValue: _style,
                    onSelected: (s) => setState(() => _style = s),
                  ),
                  ActionChip(
                    avatar: Icon(
                      _paused ? LucideIcons.play : LucideIcons.pause,
                      size: 14,
                    ),
                    label: Text(
                      _paused ? l10n.currenciesResume : l10n.currenciesPause,
                    ),
                    onPressed: _togglePause,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final iv in const ['1s', '5s', '1m', '15m'])
                ChoiceChip(
                  label: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(iv),
                  ),
                  selected: _interval == iv,
                  onSelected: (_) {
                    setState(() => _interval = iv);
                    if (!_paused) _startTimer();
                  },
                ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  latest.toStringAsFixed(4),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: _style == SimulatedChartStyle.candles
                  ? CustomPaint(
                      painter: _SimulatedCandlePainter(
                        candles: _candles,
                        borderColor: colors.border,
                        labelColor: colors.textMuted,
                      ),
                      child: const SizedBox.expand(),
                    )
                  : LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: math.max(1, _candles.length - 1).toDouble(),
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
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (var i = 0; i < _candles.length; i++)
                                FlSpot(i.toDouble(), _candles[i].close),
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
                        ],
                      ),
                    ),
            ),
          ),
          if (widget.showTradeFeed && _candles.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.currenciesSimulatedTrades,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  l10n.currenciesSpreadFooter,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final c in _candles.reversed.take(6)) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        c.close >= c.open ? 'BUY' : 'SELL',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: c.close >= c.open
                                  ? const Color(0xFF0ECB81)
                                  : const Color(0xFFF6465D),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        c.close.toStringAsFixed(4),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        c.volume.toStringAsFixed(0),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        c.timeLabel,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SimulatedCandlePainter extends CustomPainter {
  _SimulatedCandlePainter({
    required this.candles,
    required this.borderColor,
    required this.labelColor,
  });

  final List<_SimCandle> candles;
  final Color borderColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    var minVal = candles.first.low;
    var maxVal = candles.first.high;
    for (final c in candles) {
      if (c.low < minVal) minVal = c.low;
      if (c.high > maxVal) maxVal = c.high;
    }
    final range = (maxVal - minVal).abs();
    final pad = range < 0.0001 ? 0.01 : range * 0.15;
    minVal -= pad;
    maxVal += pad;
    final span = maxVal - minVal;

    final gridPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final slotW = size.width / math.max(1, candles.length);
    final bodyW = math.max(3.0, slotW * 0.56);

    double yFor(double v) => size.height - ((v - minVal) / span) * size.height;

    for (var i = 0; i < candles.length; i++) {
      final c = candles[i];
      final bull = c.close >= c.open;
      final color = bull ? const Color(0xFF0ECB81) : const Color(0xFFF6465D);
      final cx = i * slotW + slotW / 2;

      final wickPaint = Paint()
        ..color = color
        ..strokeWidth = 1.4;
      canvas.drawLine(
        Offset(cx, yFor(c.high)),
        Offset(cx, yFor(c.low)),
        wickPaint,
      );

      final top = yFor(math.max(c.open, c.close));
      final bottom = yFor(math.min(c.open, c.close));
      final rect = Rect.fromLTWH(
        cx - bodyW / 2,
        top,
        bodyW,
        math.max(2.0, bottom - top),
      );
      canvas.drawRect(rect, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _SimulatedCandlePainter oldDelegate) => true;
}

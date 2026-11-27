import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Atmospheric Gemini-style multi-layered fog backdrop behind the AI Copilot canvas.
///
/// Continuously drifts and shifts smoothly through distinct cyclic palettes for
/// Dark Mode and Light Mode. When [activeMode] is `false` (empty welcome state),
/// the fog blooms softly from the bottom edge behind the prompt suggestions and
/// composer pill; when [activeMode] is `true` (active thread or thinking), it
/// glides smoothly to the top edge behind the status bar, header, and message stream.
///
/// Uses a [Ticker] + [ValueNotifier] + [CustomPainter] inside a [RepaintBoundary]
/// and full-canvas radial shaders (`Matrix4`-transformed) with 6-stop Gaussian
/// alpha falloff so there are zero hard arcs or circular borders.
class CopilotAuroraBackdrop extends StatefulWidget {
  const CopilotAuroraBackdrop({
    super.key,
    required this.sending,
    this.activeMode = false,
    this.onPaint,
  });

  final bool sending;
  final bool activeMode;
  @visibleForTesting
  final VoidCallback? onPaint;

  static const _darkPrimaryCycle = <Color>[
    Color(0xFF3B4CCA), // Deep royal indigo
    Color(0xFF0E7490), // Deep oceanic teal
    Color(0xFF15803D), // Atmospheric emerald mist
    Color(0xFF6D28D9), // Rich twilight violet
    Color(0xFF1D4ED8), // Midnight sapphire
  ];

  static const _darkSecondaryCycle = <Color>[
    Color(0xFF0284C7), // Sapphire mist
    Color(0xFF65A30D), // Warm chartreuse-olive fog
    Color(0xFF9333EA), // Orchid dusk
    Color(0xFF0D9488), // Sea-teal fog
    Color(0xFF4F46E5), // Electric indigo
  ];

  static const _darkAccentCycle = <Color>[
    Color(0xFF312E81), // Deep horizon indigo
    Color(0xFF0369A1), // Deep sky fog
    Color(0xFF047857), // Emerald horizon
    Color(0xFF5B21B6), // Velvet plum
    Color(0xFF1E40AF), // Cobalt horizon
  ];

  static const _lightPrimaryCycle = <Color>[
    Color(0xFFA5B4FC), // Airy periwinkle mist
    Color(0xFF7DD3FC), // Crystal sky mist
    Color(0xFF6EE7B7), // Spring mint fog
    Color(0xFFD8B4FE), // Soft lavender mist
    Color(0xFF93C5FD), // Pale azure fog
  ];

  static const _lightSecondaryCycle = <Color>[
    Color(0xFF67E8F9), // Aqua veil
    Color(0xFFBEF264), // Sunlit citrus-mint fog
    Color(0xFFF9A8D4), // Rose-orchid mist
    Color(0xFF5EEAD4), // Seafoam mist
    Color(0xFFC4B5FD), // Soft iris mist
  ];

  static const _lightAccentCycle = <Color>[
    Color(0xFFC7D2FE), // Cloud indigo
    Color(0xFFBAE6FD), // Pale glacier blue
    Color(0xFFA7F3D0), // Gossamer jade
    Color(0xFFF5D0FE), // Petal lilac
    Color(0xFFFEF08A), // Soft sunlight glow
  ];

  /// Samples the cyclic aurora colors at normalized loop position [phase] in `[0, 1)`.
  static ({Color primary, Color secondary, Color accent}) samplePalette(
    double phase, {
    required bool isDark,
  }) {
    final p = phase - phase.floorToDouble();
    final primaryCycle = isDark ? _darkPrimaryCycle : _lightPrimaryCycle;
    final secondaryCycle = isDark ? _darkSecondaryCycle : _lightSecondaryCycle;
    final accentCycle = isDark ? _darkAccentCycle : _lightAccentCycle;

    return (
      primary: _sampleCycle(primaryCycle, p),
      secondary: _sampleCycle(secondaryCycle, p + 0.18),
      accent: _sampleCycle(accentCycle, p + 0.42),
    );
  }

  static Color _sampleCycle(List<Color> stops, double t) {
    final wrapped = t - t.floorToDouble();
    final scaled = wrapped * stops.length;
    final index = scaled.floor() % stops.length;
    final nextIndex = (index + 1) % stops.length;
    final localT = scaled - scaled.floorToDouble();
    return Color.lerp(stops[index], stops[nextIndex], localT)!;
  }

  @override
  State<CopilotAuroraBackdrop> createState() => _CopilotAuroraBackdropState();
}

class _CopilotAuroraBackdropState extends State<CopilotAuroraBackdrop>
    with TickerProviderStateMixin {
  static const double _staticReducedMotionPhase = 0.12;
  static const double _idleCyclesPerSecond = 1.0 / 20.0;
  static const double _sendingCyclesPerSecond = 1.0 / 10.0;
  static const int _minRepaintIntervalUs = 33000;

  late final Ticker _ticker;
  late final AnimationController _activeCtrl;
  late final CurvedAnimation _activeCurve;
  late final AnimationController _modeCtrl;
  late final CurvedAnimation _modeCurve;
  final ValueNotifier<double> _phase = ValueNotifier<double>(0.0);

  Duration? _lastPaintElapsed;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _activeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
      value: widget.sending ? 1.0 : 0.0,
    );
    _activeCurve = CurvedAnimation(
      parent: _activeCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _modeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
      value: (widget.activeMode || widget.sending) ? 1.0 : 0.0,
    );
    _modeCurve = CurvedAnimation(
      parent: _modeCtrl,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    _ticker = createTicker(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      if (_ticker.isActive) {
        _ticker.stop();
      }
      _lastPaintElapsed = null;
      _phase.value = _staticReducedMotionPhase;
      _activeCtrl.value = widget.sending ? 1.0 : 0.0;
      _modeCtrl.value = (widget.activeMode || widget.sending) ? 1.0 : 0.0;
    } else if (!_ticker.isActive) {
      _lastPaintElapsed = null;
      _ticker.start();
    }
  }

  @override
  void didUpdateWidget(covariant CopilotAuroraBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sending != widget.sending) {
      if (_reduceMotion) {
        _activeCtrl.value = widget.sending ? 1.0 : 0.0;
      } else if (widget.sending) {
        _activeCtrl.forward();
      } else {
        _activeCtrl.reverse();
      }
    }
    final oldTopMode = oldWidget.activeMode || oldWidget.sending;
    final newTopMode = widget.activeMode || widget.sending;
    if (oldTopMode != newTopMode) {
      if (_reduceMotion) {
        _modeCtrl.value = newTopMode ? 1.0 : 0.0;
      } else if (newTopMode) {
        _modeCtrl.forward();
      } else {
        _modeCtrl.reverse();
      }
    }
  }

  void _onTick(Duration elapsed) {
    final prev = _lastPaintElapsed;
    if (prev == null) {
      _lastPaintElapsed = elapsed;
      return;
    }

    final dtMicros = (elapsed - prev).inMicroseconds;
    if (dtMicros < _minRepaintIntervalUs) return;
    _lastPaintElapsed = elapsed;

    final clampedDt = math.min(dtMicros / 1000000.0, 0.1);
    final speed = widget.sending
        ? _sendingCyclesPerSecond
        : _idleCyclesPerSecond;
    final next = _phase.value + clampedDt * speed;
    _phase.value = next - next.floorToDouble();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _activeCurve.dispose();
    _activeCtrl.dispose();
    _modeCurve.dispose();
    _modeCtrl.dispose();
    _phase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    return RepaintBoundary(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _AuroraFogPainter(
            phaseListenable: _phase,
            activeAnimation: _activeCurve,
            modeAnimation: _modeCurve,
            isDark: colors.isDark,
            canvasBackground: colors.background,
            onPaint: widget.onPaint,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _AuroraFogPainter extends CustomPainter {
  _AuroraFogPainter({
    required this.phaseListenable,
    required this.activeAnimation,
    required this.modeAnimation,
    required this.isDark,
    required this.canvasBackground,
    this.onPaint,
  }) : super(
          repaint: Listenable.merge([
            phaseListenable,
            activeAnimation,
            modeAnimation,
          ]),
        );

  final ValueNotifier<double> phaseListenable;
  final Animation<double> activeAnimation;
  final Animation<double> modeAnimation;
  final bool isDark;
  final Color canvasBackground;
  final VoidCallback? onPaint;

  final Paint _fogPaint = Paint()..isAntiAlias = true;
  final Paint _fadePaint = Paint();

  static const _gaussianStops = <double>[0.0, 0.18, 0.38, 0.60, 0.82, 1.0];
  static const _gaussianFalloff = <double>[1.0, 0.72, 0.40, 0.16, 0.04, 0.0];

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    onPaint?.call();

    final phase = phaseListenable.value;
    final active = activeAnimation.value.clamp(0.0, 1.0);
    final topMode = modeAnimation.value.clamp(0.0, 1.0);
    final theta = phase * math.pi * 2.0;

    final palette = CopilotAuroraBackdrop.samplePalette(
      phase,
      isDark: isDark,
    );

    final primaryAlpha = isDark
        ? _lerp(0.40, 0.56, math.max(active, topMode * 0.55))
        : _lerp(0.28, 0.42, math.max(active, topMode * 0.50));
    final secondaryAlpha = isDark
        ? _lerp(0.30, 0.44, math.max(active, topMode * 0.55))
        : _lerp(0.22, 0.34, math.max(active, topMode * 0.50));
    final accentAlpha = isDark
        ? _lerp(0.22, 0.34, math.max(active, topMode * 0.55))
        : _lerp(0.16, 0.26, math.max(active, topMode * 0.50));

    // When topMode == 0 (Welcome screen), fog rises softly from bottom (0.78..0.94h).
    // When topMode == 1 (Active/thinking), fog drifts near the top edge (0.04..0.22h).
    final primaryY =
        size.height * _lerp(0.88 + 0.05 * math.cos(theta), 0.10 + 0.06 * math.cos(theta * 2.0), topMode);
    final secondaryY =
        size.height * _lerp(0.76 + 0.07 * math.sin(theta * 2.0 + 1.1), 0.18 + 0.08 * math.sin(theta * 2.0 + 1.3), topMode);
    final accentY =
        size.height * _lerp(0.95 + 0.04 * math.sin(theta + 0.5), 0.03 + 0.05 * math.sin(theta * 3.0), topMode);

    // Restrict fill rect to the settled half-screen band when fully in Welcome
    // or Active mode to eliminate full-screen overdraw; span full canvas only mid-transition.
    final Rect bandRect;
    if (topMode >= 0.99) {
      bandRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.80);
    } else if (topMode <= 0.01) {
      bandRect = Rect.fromLTWH(
        0,
        size.height * 0.18,
        size.width,
        size.height * 0.82,
      );
    } else {
      bandRect = Offset.zero & size;
    }

    // 1. Wide base horizontal fog bank
    _paintFogField(
      canvas: canvas,
      bandRect: bandRect,
      cx: size.width * (0.34 + 0.24 * math.sin(theta)),
      cy: primaryY,
      rx: size.width * _lerp(1.18, 1.34, active),
      ry: size.height * _lerp(0.42, 0.54, active),
      color: palette.primary,
      peakAlpha: primaryAlpha,
    );

    // 2. Counter-drifting warm/cool atmospheric plume
    _paintFogField(
      canvas: canvas,
      bandRect: bandRect,
      cx: size.width * (0.68 + 0.24 * math.cos(theta + 0.9)),
      cy: secondaryY,
      rx: size.width * _lerp(1.06, 1.24, active),
      ry: size.height * _lerp(0.36, 0.48, active),
      color: palette.secondary,
      peakAlpha: secondaryAlpha,
    );

    // 3. Horizon bloom fog band anchoring the top/bottom bleed
    _paintFogField(
      canvas: canvas,
      bandRect: bandRect,
      cx: size.width * (0.50 + 0.28 * math.sin(theta * 2.0 + 2.0)),
      cy: accentY,
      rx: size.width * _lerp(1.30, 1.46, active),
      ry: size.height * _lerp(0.32, 0.44, active),
      color: palette.accent,
      peakAlpha: accentAlpha,
    );

    // Soft atmospheric vignette fade on the quiet opposite half so contrast
    // against background stays seamless with zero edges or bands.
    final fadeStartY = topMode > 0.5 ? size.height * 0.48 : size.height * 0.52;
    final fadeEndY = topMode > 0.5 ? size.height * 0.84 : size.height * 0.16;
    _fadePaint.shader = ui.Gradient.linear(
      Offset(0, fadeStartY),
      Offset(0, fadeEndY),
      [
        canvasBackground.withValues(alpha: 0.0),
        canvasBackground.withValues(alpha: isDark ? 0.55 : 0.45),
      ],
    );
    canvas.drawRect(bandRect, _fadePaint);
  }

  void _paintFogField({
    required Canvas canvas,
    required Rect bandRect,
    required double cx,
    required double cy,
    required double rx,
    required double ry,
    required Color color,
    required double peakAlpha,
  }) {
    if (rx <= 0 || ry <= 0 || peakAlpha <= 0.005) return;

    final matrix = Matrix4.identity()
      ..translateByDouble(cx, cy, 0.0, 1.0)
      ..scaleByDouble(rx, ry, 1.0, 1.0);

    final colors = [
      for (final factor in _gaussianFalloff)
        color.withValues(alpha: peakAlpha * factor),
    ];

    _fogPaint.shader = ui.Gradient.radial(
      Offset.zero,
      1.0,
      colors,
      _gaussianStops,
      TileMode.clamp,
      matrix.storage,
    );

    canvas.drawRect(bandRect, _fogPaint);
  }

  @override
  bool shouldRepaint(covariant _AuroraFogPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.canvasBackground != canvasBackground ||
        oldDelegate.onPaint != onPaint ||
        oldDelegate.phaseListenable != phaseListenable ||
        oldDelegate.activeAnimation != activeAnimation ||
        oldDelegate.modeAnimation != modeAnimation;
  }
}

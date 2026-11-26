import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Native AFAB geometric "A" monogram loader inspired by `afab-loader.tsx`,
/// automatically simplifying when `MediaQuery.disableAnimationsOf(context)` is true.
class AfabLoader extends StatefulWidget {
  const AfabLoader({
    super.key,
    this.size = 64,
    this.label,
  });

  final double size;
  final String? label;

  @override
  State<AfabLoader> createState() => _AfabLoaderState();
}

class _AfabLoaderState extends State<AfabLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: reducedMotion
              ? CustomPaint(
                  painter: _AfabLogoPainter(
                    progress: 0.75,
                    primary: colors.primary,
                    secondary: colors.primaryHover,
                    border: colors.border,
                  ),
                )
              : AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _AfabLogoPainter(
                        progress: _controller.value,
                        primary: colors.primary,
                        secondary: colors.primaryHover,
                        border: colors.border,
                      ),
                    );
                  },
                ),
        ),
        if (widget.label != null && widget.label!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            widget.label!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ],
    );
  }
}

class _AfabLogoPainter extends CustomPainter {
  _AfabLogoPainter({
    required this.progress,
    required this.primary,
    required this.secondary,
    required this.border,
  });

  final double progress;
  final Color primary;
  final Color secondary;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.45;

    final trackPaint = Paint()
      ..color = border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, trackPaint);

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [primary.withValues(alpha: 0.05), primary, secondary],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    final startAngle = progress * 6.2831853;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2.6,
      false,
      sweepPaint,
    );

    final aPaint = Paint()
      ..color = primary
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.width * 0.085;

    final top = Offset(size.width * 0.5, size.height * 0.25);
    final left = Offset(size.width * 0.30, size.height * 0.72);
    final right = Offset(size.width * 0.70, size.height * 0.72);
    final barLeft = Offset(size.width * 0.37, size.height * 0.57);
    final barRight = Offset(size.width * 0.63, size.height * 0.57);

    final path = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(top.dx, top.dy)
      ..lineTo(right.dx, right.dy)
      ..moveTo(barLeft.dx, barLeft.dy)
      ..lineTo(barRight.dx, barRight.dy);
    canvas.drawPath(path, aPaint);
  }

  @override
  bool shouldRepaint(covariant _AfabLogoPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.primary != primary;
  }
}

class AfabShimmerBox extends StatelessWidget {
  const AfabShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 12,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    final base = colors.isDark ? colors.surface : const Color(0xFFE5E7EB);
    final highlight = colors.isDark ? colors.border : const Color(0xFFF3F4F6);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class AfabListSkeleton extends StatelessWidget {
  const AfabListSkeleton({
    super.key,
    this.count = 4,
    this.itemHeight = 68,
  });

  final int count;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++) ...[
          AfabShimmerBox(height: itemHeight),
          if (i < count - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

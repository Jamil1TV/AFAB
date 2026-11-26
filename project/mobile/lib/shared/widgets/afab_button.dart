import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/theme/appearance_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AfabButtonVariant {
  primary,
  secondary,
  soft,
  danger,
  premium,
  ghost,
}

class AfabButton extends ConsumerWidget {
  const AfabButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AfabButtonVariant.primary,
    this.isLoading = false,
    this.expand = false,
    this.compact = false,
    this.minHeight,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AfabButtonVariant variant;
  final bool isLoading;
  final bool expand;
  final bool compact;
  final double? minHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.afabColors;
    final appearance = ref.watch(appearanceNotifierProvider);
    final radius = BorderRadius.circular(appearance.radius.baseRadius);
    final enabled = onPressed != null && !isLoading;
    final resolvedMinHeight = minHeight ?? (compact ? 42.0 : 48.0);
    final isLarge = resolvedMinHeight >= 52;

    Color fg;
    Color bg;
    BorderSide? border;
    Gradient? gradient;
    List<BoxShadow>? shadow;

    switch (variant) {
      case AfabButtonVariant.primary:
        fg = Colors.white;
        bg = colors.primary;
        if (appearance.enableGlow && enabled) {
          shadow = [
            BoxShadow(
              color: colors.glowColor,
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ];
        }
      case AfabButtonVariant.secondary:
        fg = colors.textPrimary;
        bg = colors.surface;
        border = BorderSide(color: colors.border);
      case AfabButtonVariant.soft:
        fg = colors.primary;
        bg = colors.primary.withValues(alpha: 0.12);
        border = BorderSide(color: colors.primary.withValues(alpha: 0.3));
      case AfabButtonVariant.danger:
        fg = Colors.white;
        bg = const Color(0xFFDC2626);
      case AfabButtonVariant.premium:
        fg = Colors.white;
        bg = colors.primary;
        gradient = LinearGradient(
          colors: [colors.primary, colors.primaryHover],
        );
        if (appearance.enableGlow && enabled) {
          shadow = [
            BoxShadow(
              color: colors.glowColor,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ];
        }
      case AfabButtonVariant.ghost:
        fg = colors.textMuted;
        bg = Colors.transparent;
    }

    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontSize: isLarge ? 15.5 : null,
                  fontWeight: isLarge ? FontWeight.w700 : FontWeight.w600,
                ),
          ),
        ),
      ],
    );

    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: Container(
        constraints: BoxConstraints(minHeight: resolvedMinHeight),
        decoration: BoxDecoration(
          color: gradient == null ? bg : null,
          gradient: gradient,
          borderRadius: radius,
          border: border != null ? Border.fromBorderSide(border) : null,
          boxShadow: shadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 14 : 18,
                vertical: isLarge ? 14 : (compact ? 10 : 12),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

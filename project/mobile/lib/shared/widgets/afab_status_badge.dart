import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:flutter/material.dart';

enum AfabBadgeVariant {
  neutral,
  success,
  warning,
  danger,
  info,
  primary,
}

class AfabStatusBadge extends StatelessWidget {
  const AfabStatusBadge({
    super.key,
    required this.label,
    this.variant = AfabBadgeVariant.neutral,
    this.icon,
  });

  final String label;
  final AfabBadgeVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    final (bg, fg, border) = switch (variant) {
      AfabBadgeVariant.neutral => (
          colors.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFF3F4F6),
          colors.textMuted,
          Colors.transparent,
        ),
      AfabBadgeVariant.success => (
          colors.successBg,
          colors.success,
          colors.success.withValues(alpha: 0.25),
        ),
      AfabBadgeVariant.warning => (
          colors.warningBg,
          colors.warning,
          colors.warning.withValues(alpha: 0.25),
        ),
      AfabBadgeVariant.danger => (
          colors.dangerBg,
          colors.danger,
          colors.danger.withValues(alpha: 0.25),
        ),
      AfabBadgeVariant.info => (
          colors.infoBg,
          colors.info,
          colors.info.withValues(alpha: 0.25),
        ),
      AfabBadgeVariant.primary => (
          colors.primary.withValues(alpha: 0.12),
          colors.primary,
          colors.primary.withValues(alpha: 0.28),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

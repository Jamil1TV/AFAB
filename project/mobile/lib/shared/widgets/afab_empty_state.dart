import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AfabEmptyState extends StatelessWidget {
  const AfabEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.surfaceInset,
              shape: BoxShape.circle,
              border: Border.all(color: colors.border),
            ),
            child: Icon(icon, size: 24, color: colors.textMuted),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            AfabButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: AfabButtonVariant.soft,
              compact: true,
            ),
          ],
        ],
      ),
    );
  }
}

class AfabErrorState extends StatelessWidget {
  const AfabErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.dangerBg,
                shape: BoxShape.circle,
                border: Border.all(color: colors.danger.withValues(alpha: 0.3)),
              ),
              child: Icon(
                LucideIcons.triangleAlert,
                size: 26,
                color: colors.danger,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            AfabButton(
              label: retryLabel,
              icon: LucideIcons.refreshCw,
              onPressed: onRetry,
              variant: AfabButtonVariant.secondary,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}

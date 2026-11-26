import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

abstract final class AfabToast {
  static void showSuccess(BuildContext context, String message) {
    final colors = context.afabColors;
    _show(context, message, colors.success, LucideIcons.circleCheck);
  }

  static void showError(BuildContext context, String message) {
    final colors = context.afabColors;
    _show(context, message, colors.danger, LucideIcons.circleAlert);
  }

  static void showInfo(BuildContext context, String message) {
    final colors = context.afabColors;
    _show(context, message, colors.info, LucideIcons.info);
  }

  static void _show(
    BuildContext context,
    String message,
    Color accent,
    IconData icon,
  ) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final colors = context.afabColors;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: colors.surface,
        elevation: 6,
        content: Row(
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: accent.withValues(alpha: 0.4)),
        ),
      ),
    );
  }
}

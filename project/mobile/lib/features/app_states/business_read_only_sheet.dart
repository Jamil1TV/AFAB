import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/network/global_events.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/shared/widgets/afab_bottom_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<void> showBusinessReadOnlySheet(
  BuildContext context,
  BusinessReadOnlyEvent event,
) {
  final l10n = context.l10n;
  final colors = context.afabColors;
  return showAfabBottomSheet<void>(
    context: context,
    title: l10n.planReadOnlyTitle,
    builder: (sheetCtx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AfabInsetPanel(
            borderColor: colors.warning.withValues(alpha: 0.4),
            child: Row(
              children: [
                Icon(LucideIcons.lock, size: 22, color: colors.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.planReadOnlyMessage(event.businessName ?? ''),
                    style: Theme.of(sheetCtx).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AfabButton(
            label: l10n.businessSwitcherManagePlans,
            icon: LucideIcons.slidersHorizontal,
            variant: AfabButtonVariant.primary,
            expand: true,
            onPressed: () {
              Navigator.of(sheetCtx).pop();
              context.go('/plans');
            },
          ),
          const SizedBox(height: 10),
          AfabButton(
            label: l10n.commonClose,
            variant: AfabButtonVariant.secondary,
            expand: true,
            onPressed: () => Navigator.of(sheetCtx).pop(),
          ),
        ],
      );
    },
  );
}

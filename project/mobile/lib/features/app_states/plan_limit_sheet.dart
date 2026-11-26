import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/network/global_events.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/shared/widgets/afab_bottom_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

String _friendlyFeatureName(String raw) => switch (raw) {
      'business.max' => 'Workspaces',
      'ai.messages_per_month' => 'AI Copilot Messages',
      'ai.chat.queries_per_month' => 'AI Queries',
      'ai.chat.tokens_per_month' => 'AI Tokens',
      'export.per_month' => 'Report Exports',
      'invoices.per_month' => 'Monthly Invoices',
      _ => raw,
    };

Future<void> showPlanLimitSheet(
  BuildContext context,
  PlanLimitReachedEvent event,
) {
  final l10n = context.l10n;
  final colors = context.afabColors;
  final progress =
      event.limit > 0 ? (event.used / event.limit).clamp(0.0, 1.0) : 1.0;

  return showAfabBottomSheet<void>(
    context: context,
    title: l10n.planLimitTitle,
    builder: (sheetCtx) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AfabInsetPanel(
            borderColor: colors.warning.withValues(alpha: 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.crown, size: 22, color: colors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.planLimitMessage(
                          _friendlyFeatureName(event.feature),
                          event.used,
                          event.limit,
                          event.upgradeTo.toUpperCase(),
                        ),
                        style: Theme.of(sheetCtx).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    color: colors.warning,
                    backgroundColor: colors.warningBg,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AfabButton(
            label: l10n.dashboardUpgradeBtn,
            icon: LucideIcons.sparkles,
            variant: AfabButtonVariant.premium,
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

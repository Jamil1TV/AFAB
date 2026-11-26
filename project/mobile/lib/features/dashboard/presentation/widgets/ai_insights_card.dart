import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/ai/domain/ai_providers.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AiInsightsCard extends ConsumerWidget {
  const AiInsightsCard({
    super.key,
    required this.pulse,
  });

  final AiPulseDto? pulse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final alerts = pulse?.alerts.take(2).toList() ?? const <PulseAlertDto>[];

    return AfabCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.dashboardAiTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              AfabStatusBadge(
                label: l10n.dashboardAiLivePulse,
                variant: AfabBadgeVariant.primary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (alerts.isEmpty)
            AfabEmptyState(
              icon: LucideIcons.activity,
              title: l10n.dashboardAiAwaitingActivity,
              description: l10n.dashboardAiAwaitingActivityDesc,
            )
          else
            for (final alert in alerts) ...[
              AfabInsetPanel(
                borderColor: alert.severity.toUpperCase() == 'HIGH'
                    ? colors.danger.withValues(alpha: 0.35)
                    : colors.border,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AfabStatusBadge(
                          label: alert.severity.toUpperCase(),
                          variant: switch (alert.severity.toUpperCase()) {
                            'HIGH' => AfabBadgeVariant.danger,
                            'MEDIUM' => AfabBadgeVariant.warning,
                            _ => AfabBadgeVariant.info,
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            alert.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      alert.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        onPressed: () => ref
                            .read(copilotLauncherProvider.notifier)
                            .openCopilot(
                              prompt: alert.copilotPrompt,
                              autoSend: true,
                              screenContext: {
                                'source': 'AIInsightsCard',
                                'alertType': alert.type,
                              },
                            ),
                        icon: const Icon(LucideIcons.arrowUpRight, size: 15),
                        label: Text(l10n.dashboardAiInvestigate),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 6),
          AfabButton(
            label: l10n.dashboardAiAskBtn,
            icon: LucideIcons.sparkles,
            variant: AfabButtonVariant.soft,
            expand: true,
            compact: true,
            onPressed: () => ref
                .read(copilotLauncherProvider.notifier)
                .openCopilot(screenContext: const {'page': 'dashboard'}),
          ),
        ],
      ),
    );
  }
}

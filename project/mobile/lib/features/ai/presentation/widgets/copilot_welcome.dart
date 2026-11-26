import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CopilotWelcome extends ConsumerWidget {
  const CopilotWelcome({
    super.key,
    required this.disabled,
    required this.onSendPrompt,
    required this.onPrefillPrompt,
    required this.onOpenAttachmentPicker,
  });

  final bool disabled;
  final ValueChanged<String> onSendPrompt;
  final ValueChanged<String> onPrefillPrompt;
  final VoidCallback onOpenAttachmentPicker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final pulseAsync = ref.watch(aiPulseProvider);
    final pulse = pulseAsync.value;
    final width = MediaQuery.sizeOf(context).width;
    final bentoCols = width > AfabBreakpoints.phoneMax ? 2 : 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 740),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.sparkles,
                          size: 14,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l10n.aiHeroBadge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${l10n.aiHeroTitleStart}${l10n.aiHeroTitleHighlight}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.aiWelcomeSubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textMuted,
                      ),
                ),
                const SizedBox(height: 18),

                // Live Financial Pulse Strip
                AfabCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (pulse != null)
                        Wrap(
                          spacing: 16,
                          runSpacing: 10,
                          alignment: WrapAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.aiPulseMonthNet,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                const SizedBox(height: 2),
                                MoneyText(
                                  amount: pulse.safeMonthNetProfit,
                                  currency: pulse.currency,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: pulse.safeMonthNetProfit >=
                                                Decimal.zero
                                            ? colors.success
                                            : colors.danger,
                                      ),
                                ),
                              ],
                            ),
                            _PulseMetricChip(
                              label: l10n.aiPulseOverdue,
                              value: pulse.overdueCount > 0
                                  ? '${pulse.overdueCount}'
                                  : l10n.aiPulseAllClear,
                              dotColor: pulse.overdueCount > 0
                                  ? colors.danger
                                  : colors.success,
                            ),
                            _PulseMetricChip(
                              label: l10n.aiPulseAlerts,
                              value: (pulse.highCount + pulse.mediumCount) > 0
                                  ? '${pulse.highCount + pulse.mediumCount}'
                                  : l10n.aiPulseHealthy,
                              dotColor:
                                  (pulse.highCount + pulse.mediumCount) > 0
                                      ? colors.warning
                                      : colors.success,
                            ),
                          ],
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            AfabStatusBadge(
                              label: l10n.aiCapPrivate,
                              variant: AfabBadgeVariant.primary,
                            ),
                            AfabStatusBadge(
                              label: l10n.aiCapMath,
                              variant: AfabBadgeVariant.success,
                            ),
                            AfabStatusBadge(
                              label: l10n.aiCapMultilingual,
                              variant: AfabBadgeVariant.info,
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      AfabButton(
                        label: l10n.aiMorningBriefButton,
                        icon: LucideIcons.sunrise,
                        expand: true,
                        onPressed: disabled
                            ? null
                            : () => onSendPrompt(l10n.aiMorningBriefPrompt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Bento Action Grid (1 or 2 columns)
                LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = 10.0;
                    final tileWidth = bentoCols == 2
                        ? (constraints.maxWidth - gap) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        _BentoPromptTile(
                          width: tileWidth,
                          icon: LucideIcons.trendingUp,
                          tag: l10n.aiPromptPnlTag,
                          title: l10n.aiPromptPnlTitle,
                          subtitle: l10n.aiPromptPnlShortDesc,
                          onTap: disabled
                              ? null
                              : () => onSendPrompt(l10n.aiPromptPnlText),
                        ),
                        _BentoPromptTile(
                          width: tileWidth,
                          icon: LucideIcons.activity,
                          tag: l10n.aiCapMath,
                          title: l10n.aiPromptForecastTitle,
                          subtitle: l10n.aiPromptForecastShortDesc,
                          onTap: disabled
                              ? null
                              : () => onSendPrompt(l10n.aiPromptForecastText),
                        ),
                        _BentoPromptTile(
                          width: tileWidth,
                          icon: LucideIcons.receiptText,
                          tag: l10n.aiPromptScanBadge,
                          title: l10n.aiPromptScanTitle,
                          subtitle: l10n.aiPromptScanShortDesc,
                          onTap: disabled ? null : onOpenAttachmentPicker,
                        ),
                        _BentoPromptTile(
                          width: tileWidth,
                          icon: LucideIcons.languages,
                          tag: l10n.aiComposerLanguages,
                          title: l10n.aiPromptDerjaTitle,
                          subtitle: l10n.aiPromptDerjaShortDesc,
                          onTap: disabled
                              ? null
                              : () => onSendPrompt(l10n.aiPromptDerjaText),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),

                // Quick Suggestion Pills
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ActionChip(
                      avatar: const Icon(LucideIcons.fileWarning, size: 14),
                      label: Text(l10n.aiPromptInvoicesTitle),
                      onPressed: disabled
                          ? null
                          : () => onSendPrompt(l10n.aiPromptInvoicesText),
                    ),
                    ActionChip(
                      avatar: const Icon(LucideIcons.piggyBank, size: 14),
                      label: Text(l10n.aiPromptBudgetsTitle),
                      onPressed: disabled
                          ? null
                          : () => onSendPrompt(l10n.aiPromptBudgetsText),
                    ),
                    ActionChip(
                      avatar: const Icon(LucideIcons.plusCircle, size: 14),
                      label: Text(l10n.aiPromptQuickCaptureChip),
                      onPressed: disabled
                          ? null
                          : () =>
                              onPrefillPrompt(l10n.aiPromptQuickCapturePrefill),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PulseMetricChip extends StatelessWidget {
  const _PulseMetricChip({
    required this.label,
    required this.value,
    required this.dotColor,
  });

  final String label;
  final String value;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(value, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ],
    );
  }
}

class _BentoPromptTile extends StatelessWidget {
  const _BentoPromptTile({
    required this.width,
    required this.icon,
    required this.tag,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final double width;
  final IconData icon;
  final String tag;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AfabInsetPanel(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: colors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:afab_mobile/shared/widgets/afab_brand_logo.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
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
    final pulse = ref.watch(aiPulseProvider).value;

    final prompts = <({IconData icon, String label, VoidCallback? onTap})>[
      (
        icon: LucideIcons.trendingUp,
        label: l10n.aiPromptPnlTitle,
        onTap: disabled ? null : () => onSendPrompt(l10n.aiPromptPnlText),
      ),
      (
        icon: LucideIcons.activity,
        label: l10n.aiPromptForecastTitle,
        onTap: disabled ? null : () => onSendPrompt(l10n.aiPromptForecastText),
      ),
      (
        icon: LucideIcons.scanLine,
        label: l10n.aiPromptScanTitle,
        onTap: disabled ? null : onOpenAttachmentPicker,
      ),
      (
        icon: LucideIcons.receiptText,
        label: l10n.aiPromptInvoicesTitle,
        onTap: disabled ? null : () => onSendPrompt(l10n.aiPromptInvoicesText),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactHeight = constraints.maxHeight < 460;
        final isNarrow = constraints.maxWidth < 360;

        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            20,
            isCompactHeight ? 12 : 28,
            20,
            isCompactHeight ? 8 : 12,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - (isCompactHeight ? 20 : 40))
                  .clamp(0.0, double.infinity),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Upper open-canvas emblem & headline (mirrors Gemini starter hero)
                    Padding(
                      padding: EdgeInsets.only(top: isCompactHeight ? 4 : 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AfabBrandLogo(
                            size: isCompactHeight ? 44 : 56,
                            showGlowRing: true,
                          ),
                          SizedBox(height: isCompactHeight ? 12 : 18),
                          Text(
                            '${l10n.aiHeroTitleStart}${l10n.aiHeroTitleHighlight}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontSize: isCompactHeight
                                      ? 21
                                      : (isNarrow ? 23 : 27),
                                  fontWeight: FontWeight.w500,
                                  height: 1.22,
                                  letterSpacing: -0.4,
                                ),
                          ),
                          if (pulse != null) ...[
                            SizedBox(height: isCompactHeight ? 10 : 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Wrap(
                                  spacing: 3,
                                  runSpacing: 2,
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      '${l10n.aiPulseMonthNet}: ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: colors.textMuted),
                                    ),
                                    MoneyText(
                                      amount: pulse.safeMonthNetProfit,
                                      currency: pulse.currency,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: pulse.safeMonthNetProfit >=
                                                    Decimal.zero
                                                ? colors.success
                                                : colors.danger,
                                          ),
                                    ),
                                  ],
                                ),
                                _PulseDotPill(
                                  label: l10n.aiPulseOverdue,
                                  value: pulse.overdueCount > 0
                                      ? '${pulse.overdueCount}'
                                      : l10n.aiPulseAllClear,
                                  dotColor: pulse.overdueCount > 0
                                      ? colors.danger
                                      : colors.success,
                                ),
                                _PulseDotPill(
                                  label: l10n.aiPulseAlerts,
                                  value:
                                      (pulse.highCount + pulse.mediumCount) > 0
                                          ? '${pulse.highCount + pulse.mediumCount}'
                                          : l10n.aiPulseHealthy,
                                  dotColor:
                                      (pulse.highCount + pulse.mediumCount) > 0
                                          ? colors.warning
                                          : colors.success,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: isCompactHeight ? 16 : 28),

                    // Lower borderless prompt rows & Morning CFO Brief pill above composer
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final item in prompts)
                          _MinimalPromptRow(
                            icon: item.icon,
                            label: item.label,
                            onTap: item.onTap,
                          ),
                        SizedBox(height: isCompactHeight ? 10 : 14),
                        Center(
                          child: AfabButton(
                            label: l10n.aiMorningBriefButton,
                            icon: LucideIcons.sunrise,
                            variant: AfabButtonVariant.soft,
                            compact: true,
                            onPressed: disabled
                                ? null
                                : () => onSendPrompt(l10n.aiMorningBriefPrompt),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PulseDotPill extends StatelessWidget {
  const _PulseDotPill({
    required this.label,
    required this.value,
    required this.dotColor,
  });

  final String label;
  final String value;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            '$label: $value',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _MinimalPromptRow extends StatelessWidget {
  const _MinimalPromptRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    return Opacity(
      opacity: onTap == null ? 0.5 : 1.0,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
            child: Row(
              children: [
                Icon(icon, size: 18, color: colors.textMuted),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: colors.textPrimary,
                          height: 1.32,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/theme/appearance_settings.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `SET-08`: Language & Directionality Settings (`System`, `EN`, `AR`).
class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    const body = LanguageSettingsBody();
    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.languageSettingsTitle)),
      body: body,
    );
  }
}

class LanguageSettingsBody extends ConsumerWidget {
  const LanguageSettingsBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final activeLocale = ref.watch(localeNotifierProvider);
    final pref = ref.read(localeNotifierProvider.notifier).preference;
    final biz = ref.watch(activeBusinessProvider);
    final curr = biz?.currency ?? 'USD';
    final numFmt = biz?.numberFormat ?? 'US';
    final dateFmt = biz?.dateFormat ?? 'YYYY-MM-DD';

    Future<void> selectPref(AfabLocalePreference next) async {
      await ref.read(localeNotifierProvider.notifier).setPreference(next);
      if (context.mounted) {
        AfabToast.showSuccess(context, context.l10n.languageUpdatedToast);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LanguageOptionCard(
                emblem: null,
                title: l10n.languageSystemTitle,
                subtitle: l10n.languageSystemSub,
                selected: pref == AfabLocalePreference.system,
                onTap: () => selectPref(AfabLocalePreference.system),
              ),
              const SizedBox(height: 10),
              // Native self-labels stay legible even when UI is in the other language.
              _LanguageOptionCard(
                emblem: 'EN',
                title: 'English',
                subtitle: l10n.languageEnglishSub,
                selected: pref == AfabLocalePreference.en,
                onTap: () => selectPref(AfabLocalePreference.en),
              ),
              const SizedBox(height: 10),
              _LanguageOptionCard(
                emblem: 'ع',
                title: 'العربية',
                subtitle: l10n.languageArabicSub,
                selected: pref == AfabLocalePreference.ar,
                onTap: () => selectPref(AfabLocalePreference.ar),
              ),
              const SizedBox(height: 18),

              // Live Formatting & Directionality Preview
              AfabCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.languages,
                          size: 17,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.languagePreviewTitle,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        AfabStatusBadge(
                          label: activeLocale.languageCode == 'ar' ? 'RTL' : 'LTR',
                          variant: AfabBadgeVariant.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AfabInsetPanel(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.languagePreviewDir(
                              activeLocale.languageCode == 'ar' ? 'RTL' : 'LTR',
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AfabDateFormatter.formatDateTime(
                              DateTime(2026, 10, 20),
                              dateFormat: dateFmt,
                              locale: activeLocale.languageCode,
                            ),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 6),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              MoneyFormatter.formatDecimal(
                                Decimal.parse('1250.000'),
                                currency: curr,
                                numberFormat: numFmt,
                              ),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: colors.primary,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // AI Copilot 5-Language Independence Notice
              AfabInsetPanel(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.sparkles,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.languageCopilotNote,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOptionCard extends StatelessWidget {
  const _LanguageOptionCard({
    required this.emblem,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String? emblem;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? colors.primary.withValues(alpha: 0.08) : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? colors.primary : colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 68),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: selected
                          ? colors.primary.withValues(alpha: 0.16)
                          : colors.surfaceInset,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: emblem != null
                        ? Text(
                            emblem!,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: selected
                                      ? colors.primary
                                      : colors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          )
                        : Icon(
                            LucideIcons.globe,
                            size: 20,
                            color: selected ? colors.primary : colors.textMuted,
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: selected ? colors.primary : colors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

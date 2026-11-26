import 'package:afab_mobile/core/config/business_constants.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/auth/presentation/widgets/auth_error_localizer.dart';
import 'package:afab_mobile/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:afab_mobile/shared/widgets/afab_bottom_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `AUTH-08`: 3-step business configuration wizard completing
/// `PUT /api/v1/business/{businessId}`.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 1;
  String _country = 'United Arab Emirates';
  String _industry = 'Technology & Software';
  String _businessType = 'Limited Liability Company (LLC)';
  String _currency = 'USD';
  String _timezone = 'Asia/Dubai';
  int _fiscalYearStartMonth = 1;
  bool _submitting = false;
  String? _errorBanner;

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _errorBanner = null;
    });
    try {
      await ref.read(authNotifierProvider.notifier).completeOnboarding(
            country: _country,
            industry: _industry,
            businessType: _businessType,
            currency: _currency,
            timezone: _timezone,
            fiscalYearStartMonth: _fiscalYearStartMonth,
          );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorBanner = localizeAuthFailure(context, e));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _pickOption({
    required String title,
    required List<({String id, String label})> items,
    required String selectedId,
    required ValueChanged<String> onSelected,
  }) async {
    await showAfabBottomSheet<void>(
      context: context,
      title: title,
      builder: (sheetCtx) {
        var query = '';
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final colors = ctx.afabColors;
            final filtered = query.trim().isEmpty
                ? items
                : items
                    .where(
                      (i) => i.label
                          .toLowerCase()
                          .contains(query.trim().toLowerCase()),
                    )
                    .toList();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: context.l10n.onboardingSearchHint,
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                  ),
                  onChanged: (v) => setModalState(() => query = v),
                ),
                const SizedBox(height: 12),
                for (final item in filtered)
                  ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    title: Text(item.label),
                    trailing: item.id == selectedId
                        ? Icon(LucideIcons.check, size: 18, color: colors.primary)
                        : null,
                    onTap: () {
                      onSelected(item.id);
                      Navigator.of(sheetCtx).pop();
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final locale = Localizations.localeOf(context).languageCode;

    final stepTitle = switch (_step) {
      1 => l10n.onboardingStep1Title,
      2 => l10n.onboardingStep2Title,
      _ => l10n.onboardingStep3Title,
    };
    final stepSubtitle = switch (_step) {
      1 => l10n.onboardingStep1Subtitle,
      2 => l10n.onboardingStep2Subtitle,
      _ => l10n.onboardingStep3Subtitle,
    };

    return AuthScaffold(
      maxWidth: 520,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.onboardingStep(_step),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                switch (_step) {
                  1 => l10n.onboardingStep1Tab,
                  2 => l10n.onboardingStep2Tab,
                  _ => l10n.onboardingStep3Tab,
                },
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: _step / 3.0,
              minHeight: 6,
              backgroundColor: colors.border,
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
          const SizedBox(height: 20),
          Text(stepTitle, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(
            stepSubtitle,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: 20),
          if (_errorBanner != null) ...[
            AfabInsetPanel(
              borderColor: colors.danger.withValues(alpha: 0.45),
              child: Text(
                _errorBanner!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.danger, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_step == 1) ...[
            _PickerField(
              label: l10n.onboardingCountryLabel,
              value: BusinessConstants.localizedCountry(_country, locale),
              icon: LucideIcons.globe,
              onTap: () => _pickOption(
                title: l10n.onboardingCountryLabel,
                selectedId: _country,
                items: BusinessConstants.countries
                    .map((c) => (id: c.nameEn, label: c.label(locale)))
                    .toList(),
                onSelected: (v) => setState(() => _country = v),
              ),
            ),
            const SizedBox(height: 14),
            _PickerField(
              label: l10n.onboardingIndustryLabel,
              value: BusinessConstants.industries
                  .firstWhere(
                    (i) => i.nameEn == _industry,
                    orElse: () => BusinessConstants.industries.first,
                  )
                  .label(locale),
              icon: LucideIcons.briefcase,
              onTap: () => _pickOption(
                title: l10n.onboardingIndustryLabel,
                selectedId: _industry,
                items: BusinessConstants.industries
                    .map((i) => (id: i.nameEn, label: i.label(locale)))
                    .toList(),
                onSelected: (v) => setState(() => _industry = v),
              ),
            ),
            const SizedBox(height: 14),
            _PickerField(
              label: l10n.onboardingBusinessTypeLabel,
              value: BusinessConstants.businessTypes
                  .firstWhere(
                    (b) => b.nameEn == _businessType,
                    orElse: () => BusinessConstants.businessTypes.first,
                  )
                  .label(locale),
              icon: LucideIcons.building2,
              onTap: () => _pickOption(
                title: l10n.onboardingBusinessTypeLabel,
                selectedId: _businessType,
                items: BusinessConstants.businessTypes
                    .map((b) => (id: b.nameEn, label: b.label(locale)))
                    .toList(),
                onSelected: (v) => setState(() => _businessType = v),
              ),
            ),
          ] else if (_step == 2) ...[
            _PickerField(
              label: l10n.onboardingCurrencyLabel,
              value: BusinessConstants.currencies
                  .firstWhere(
                    (c) => c.code == _currency,
                    orElse: () => BusinessConstants.currencies.first,
                  )
                  .label(locale),
              icon: LucideIcons.coins,
              onTap: () => _pickOption(
                title: l10n.onboardingCurrencyLabel,
                selectedId: _currency,
                items: BusinessConstants.currencies
                    .map((c) => (id: c.code, label: c.label(locale)))
                    .toList(),
                onSelected: (v) => setState(() => _currency = v),
              ),
            ),
            const SizedBox(height: 14),
            _PickerField(
              label: l10n.onboardingTimezoneLabel,
              value: BusinessConstants.timezones
                  .firstWhere(
                    (t) => t.id == _timezone,
                    orElse: () => BusinessConstants.timezones.first,
                  )
                  .label(locale),
              icon: LucideIcons.clock,
              onTap: () => _pickOption(
                title: l10n.onboardingTimezoneLabel,
                selectedId: _timezone,
                items: BusinessConstants.timezones
                    .map((t) => (id: t.id, label: t.label(locale)))
                    .toList(),
                onSelected: (v) => setState(() => _timezone = v),
              ),
            ),
            const SizedBox(height: 14),
            _PickerField(
              label: l10n.onboardingFiscalYearLabel,
              value:
                  BusinessConstants.localizedMonth(_fiscalYearStartMonth, locale),
              icon: LucideIcons.calendar,
              onTap: () => _pickOption(
                title: l10n.onboardingFiscalYearLabel,
                selectedId: '$_fiscalYearStartMonth',
                items: BusinessConstants.months
                    .map((m) => (id: m.id, label: m.label(locale)))
                    .toList(),
                onSelected: (v) => setState(
                  () => _fiscalYearStartMonth = int.tryParse(v) ?? 1,
                ),
              ),
            ),
          ] else ...[
            AfabInsetPanel(
              child: Column(
                children: [
                  _SummaryRow(
                    label: l10n.onboardingSummaryCountry,
                    value: BusinessConstants.localizedCountry(_country, locale),
                  ),
                  _SummaryRow(
                    label: l10n.onboardingSummaryIndustry,
                    value: BusinessConstants.industries
                        .firstWhere(
                          (i) => i.nameEn == _industry,
                          orElse: () => BusinessConstants.industries.first,
                        )
                        .label(locale),
                  ),
                  _SummaryRow(
                    label: l10n.onboardingSummaryBusinessType,
                    value: BusinessConstants.businessTypes
                        .firstWhere(
                          (b) => b.nameEn == _businessType,
                          orElse: () => BusinessConstants.businessTypes.first,
                        )
                        .label(locale),
                  ),
                  _SummaryRow(
                    label: l10n.onboardingSummaryCurrency,
                    value: _currency,
                  ),
                  _SummaryRow(
                    label: l10n.onboardingSummaryTimezone,
                    value: _timezone,
                  ),
                  _SummaryRow(
                    label: l10n.onboardingSummaryFiscalYear,
                    value: BusinessConstants.localizedMonth(
                      _fiscalYearStartMonth,
                      locale,
                    ),
                    isLast: true,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              if (_step > 1) ...[
                Expanded(
                  child: AfabButton(
                    label: l10n.commonBack,
                    variant: AfabButtonVariant.secondary,
                    onPressed:
                        _submitting ? null : () => setState(() => _step--),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: AfabButton(
                  label: _step < 3
                      ? l10n.commonContinue
                      : l10n.onboardingLaunchDashboard,
                  icon: _step < 3 ? null : LucideIcons.rocket,
                  isLoading: _submitting,
                  onPressed: () {
                    if (_step < 3) {
                      setState(() => _step++);
                    } else {
                      _submit();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: colors.surfaceInset,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.inputBorder),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: colors.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Icon(LucideIcons.chevronDown, size: 18, color: colors.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

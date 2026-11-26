import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/theme/appearance_settings.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/settings/data/settings_repository.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_segmented_bar.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:decimal/decimal.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `SET-05`: Real-Time Appearance, Dark Surfaces, Accents, Typography & Live Preview.
class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    const body = AppearanceSettingsBody();
    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appearanceTitle)),
      body: body,
    );
  }
}

class AppearanceSettingsBody extends ConsumerStatefulWidget {
  const AppearanceSettingsBody({super.key});

  @override
  ConsumerState<AppearanceSettingsBody> createState() =>
      _AppearanceSettingsBodyState();
}

class _AppearanceSettingsBodyState
    extends ConsumerState<AppearanceSettingsBody> {
  final _scrollCtrl = ScrollController();
  final _previewKey = GlobalKey();
  late final TextEditingController _hexCtrl;
  String _previewTab = 'month';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _hexCtrl = TextEditingController(
      text: ref.read(appearanceNotifierProvider).customPrimaryHex,
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _hexCtrl.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    if (_saving) return;
    setState(() => _saving = true);
    final settings = ref.read(appearanceNotifierProvider);
    await ref.read(appearanceNotifierProvider.notifier).update(settings);

    try {
      final updated = await ref.read(settingsRepositoryProvider).updateProfile({
        'compactMode': settings.density == AfabDensity.compact,
      });
      await ref.read(authNotifierProvider.notifier).updateCachedUser(updated);
      if (mounted) {
        AfabToast.showSuccess(context, context.l10n.appearanceSavedToast);
      }
    } on AppFailure {
      if (mounted) {
        AfabToast.showInfo(context, context.l10n.appearanceSavedLocalOffline);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetDefaults() async {
    await ref.read(appearanceNotifierProvider.notifier).resetDefaults();
    final next = ref.read(appearanceNotifierProvider);
    _hexCtrl.text = next.customPrimaryHex;
  }

  void _jumpToPreview() {
    final ctx = _previewKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final settings = ref.watch(appearanceNotifierProvider);
    final notifier = ref.read(appearanceNotifierProvider.notifier);

    final (resolvedPrimary, _, _, _, _, _) = settings.resolveAccent();
    final lowContrast =
        ThemeData.estimateBrightnessForColor(resolvedPrimary) == Brightness.light;

    final controlsColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Device-local notice + Reset/Save row
        AfabInsetPanel(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.smartphone, size: 17, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.appearanceDeviceLocalNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            AfabButton(
              label: l10n.appearanceResetBtn,
              icon: LucideIcons.rotateCcw,
              variant: AfabButtonVariant.secondary,
              compact: true,
              onPressed: _resetDefaults,
            ),
            AfabButton(
              label: l10n.appearanceSaveBtn,
              icon: LucideIcons.check,
              variant: AfabButtonVariant.primary,
              compact: true,
              isLoading: _saving,
              onPressed: _savePreferences,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 1. Theme Mode
        AfabCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appearanceThemeModeTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ModeTile(
                      icon: LucideIcons.sun,
                      label: l10n.appearanceModeLight,
                      selected: settings.themeMode == ThemeMode.light,
                      onTap: () => notifier.setThemeMode(ThemeMode.light),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ModeTile(
                      icon: LucideIcons.moon,
                      label: l10n.appearanceModeDark,
                      selected: settings.themeMode == ThemeMode.dark,
                      onTap: () => notifier.setThemeMode(ThemeMode.dark),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ModeTile(
                      icon: LucideIcons.laptop,
                      label: l10n.appearanceModeSystem,
                      selected: settings.themeMode == ThemeMode.system,
                      onTap: () => notifier.setThemeMode(ThemeMode.system),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Dark Surface Mood (Exposes all 4 presets!)
        AfabCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appearanceDarkSurfaceTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, c) {
                  final tileW = (c.maxWidth - 10) / 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final surf in AfabDarkSurface.values)
                        SizedBox(
                          width: tileW,
                          child: _DarkSurfaceTile(
                            surfacePreset: surf,
                            label: switch (surf) {
                              AfabDarkSurface.midnight =>
                                l10n.appearanceSurfaceMidnight,
                              AfabDarkSurface.oled => l10n.appearanceSurfaceOled,
                              AfabDarkSurface.slate =>
                                l10n.appearanceSurfaceSlate,
                              AfabDarkSurface.charcoal =>
                                l10n.appearanceSurfaceCharcoal,
                            },
                            selected: settings.darkSurface == surf,
                            onTap: () => notifier.update(
                              settings.copyWith(darkSurface: surf),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. Brand Accent Presets + Custom Hex
        AfabCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appearanceAccentTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final preset in AfabAccentPreset.values
                      .where((p) => p != AfabAccentPreset.custom))
                    Semantics(
                      selected: settings.accentPreset == preset,
                      button: true,
                      child: InkWell(
                        onTap: () => notifier.update(
                          settings.copyWith(accentPreset: preset),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: settings.accentPreset == preset
                                ? preset.primary.withValues(alpha: 0.14)
                                : colors.surfaceInset,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: settings.accentPreset == preset
                                  ? preset.primary
                                  : colors.border,
                              width: settings.accentPreset == preset ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: preset.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                preset.id.toUpperCase(),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: _hexCtrl,
                  maxLength: 7,
                  onChanged: (v) {
                    final clean = v.trim();
                    if (RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(clean)) {
                      notifier.update(
                        settings.copyWith(
                          accentPreset: AfabAccentPreset.custom,
                          customPrimaryHex: clean.toUpperCase(),
                        ),
                      );
                    }
                  },
                  decoration: InputDecoration(
                    labelText: l10n.appearanceCustomHex,
                    counterText: '',
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(10),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: resolvedPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.border),
                      ),
                    ),
                    helperText: lowContrast ? l10n.appearanceLowContrastWarn : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 4. Typography & Font Family
        AfabCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appearanceTypographyTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              for (final font in AfabFontFamilyPreset.values) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _FontOptionTile(
                    preset: font,
                    isAr: isAr,
                    selected: settings.fontFamily == font,
                    onTap: () => notifier.update(
                      settings.copyWith(fontFamily: font),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 5. Font Size Scale & Corner Radius
        AfabCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appearanceFontSizeTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in AfabFontSizePreset.values)
                    ChoiceChip(
                      label: Text('${s.id.toUpperCase()} (${(s.scale * 100).round()}%)'),
                      selected: settings.fontSize == s,
                      onSelected: (_) => notifier.update(
                        settings.copyWith(fontSize: s),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.appearanceRadiusTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in AfabRadiusPreset.values)
                    ChoiceChip(
                      label: Text('${r.id.toUpperCase()} · ${r.baseRadius.round()}dp'),
                      selected: settings.radius == r,
                      onSelected: (_) => notifier.update(
                        settings.copyWith(radius: r),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 6. Density & Visual Effects
        AfabCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appearanceDensityEffectsTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 10),
              AfabSegmentedBar<AfabDensity>(
                items: [
                  AfabSegmentItem(
                    value: AfabDensity.comfortable,
                    label: l10n.appearanceDensityComfortable,
                  ),
                  AfabSegmentItem(
                    value: AfabDensity.compact,
                    label: l10n.appearanceDensityCompact,
                  ),
                ],
                selectedValue: settings.density,
                onSelected: (d) => notifier.update(
                  settings.copyWith(density: d),
                ),
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.enableGlow,
                onChanged: (v) => notifier.update(
                  settings.copyWith(enableGlow: v),
                ),
                title: Text(l10n.appearanceEnableGlow),
              ),
              Divider(height: 1, color: colors.border),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.smoothTransitions,
                onChanged: (v) => notifier.update(
                  settings.copyWith(smoothTransitions: v),
                ),
                title: Text(l10n.appearanceSmoothTransitions),
              ),
            ],
          ),
        ),
      ],
    );

    final previewCard = KeyedSubtree(
      key: _previewKey,
      child: AfabCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.appearanceLivePreviewTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                AfabStatusBadge(
                  label: settings.customPrimaryHex.toUpperCase(),
                  variant: AfabBadgeVariant.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            AfabInsetPanel(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          MoneyFormatter.formatDecimal(
                            Decimal.parse('124850.00'),
                            currency: 'USD',
                          ),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      const AfabStatusBadge(
                        label: '+14.2%',
                        variant: AfabBadgeVariant.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 76,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            color: colors.primary,
                            barWidth: 2.5,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: colors.primary.withValues(alpha: 0.16),
                            ),
                            spots: const [
                              FlSpot(0, 12),
                              FlSpot(1, 18),
                              FlSpot(2, 15),
                              FlSpot(3, 24),
                              FlSpot(4, 29),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  AfabSegmentedBar<String>(
                    items: const [
                      AfabSegmentItem(value: 'day', label: 'Day'),
                      AfabSegmentItem(value: 'week', label: 'Week'),
                      AfabSegmentItem(value: 'month', label: 'Month'),
                    ],
                    selectedValue: _previewTab,
                    onSelected: (v) => setState(() => _previewTab = v),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AfabButton(
                        label: 'Primary',
                        variant: AfabButtonVariant.primary,
                        compact: true,
                        onPressed: () {},
                      ),
                      AfabButton(
                        label: 'Secondary',
                        variant: AfabButtonVariant.secondary,
                        compact: true,
                        onPressed: () {},
                      ),
                      AfabStatusBadge(
                        label: l10n.editProfileVerified,
                        variant: AfabBadgeVariant.success,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;
        return Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: controlsColumn),
                            const SizedBox(width: 16),
                            Expanded(flex: 5, child: previewCard),
                          ],
                        )
                      : Column(
                          children: [
                            controlsColumn,
                            const SizedBox(height: 16),
                            previewCard,
                            const SizedBox(height: 56),
                          ],
                        ),
                ),
              ),
            ),
            if (!wide)
              PositionedDirectional(
                end: 16,
                bottom: 14,
                child: FloatingActionButton.extended(
                  heroTag: 'appearance_live_preview_fab',
                  onPressed: _jumpToPreview,
                  icon: const Icon(LucideIcons.eye, size: 16),
                  label: Text(l10n.appearanceLivePreviewJump),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color:
            selected ? colors.primary.withValues(alpha: 0.1) : colors.surfaceInset,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? colors.primary : colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? colors.primary : colors.textMuted,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: selected ? colors.primary : colors.textPrimary,
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

class _DarkSurfaceTile extends StatelessWidget {
  const _DarkSurfaceTile({
    required this.surfacePreset,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AfabDarkSurface surfacePreset;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: surfacePreset.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? colors.primary : surfacePreset.border,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: surfacePreset.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: surfacePreset.border),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (selected)
                  Icon(LucideIcons.check, size: 15, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FontOptionTile extends StatelessWidget {
  const _FontOptionTile({
    required this.preset,
    required this.isAr,
    required this.selected,
    required this.onTap,
  });

  final AfabFontFamilyPreset preset;
  final bool isAr;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    final sampleStyle = switch (preset) {
      AfabFontFamilyPreset.inter =>
        isAr ? GoogleFonts.cairo(fontSize: 14) : GoogleFonts.inter(fontSize: 14),
      AfabFontFamilyPreset.serif => isAr
          ? GoogleFonts.amiri(fontSize: 14)
          : GoogleFonts.playfairDisplay(fontSize: 14),
      AfabFontFamilyPreset.mono => GoogleFonts.jetBrainsMono(fontSize: 14),
      AfabFontFamilyPreset.geometric => isAr
          ? GoogleFonts.cairo(fontSize: 14)
          : GoogleFonts.montserrat(fontSize: 14),
      AfabFontFamilyPreset.kufi => isAr
          ? GoogleFonts.reemKufi(fontSize: 14)
          : GoogleFonts.cinzel(fontSize: 14),
      AfabFontFamilyPreset.system => const TextStyle(fontSize: 14),
    };

    return Material(
      color:
          selected ? colors.primary.withValues(alpha: 0.08) : colors.surfaceInset,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? colors.primary : colors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.id.toUpperCase(),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAr ? 'AFAB المالية · 124,850' : 'AFAB Finance · \$124,850',
                      style: sampleStyle.copyWith(color: colors.textPrimary),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(LucideIcons.check, size: 16, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

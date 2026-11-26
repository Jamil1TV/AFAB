import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/theme/appearance_settings.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AuthScaffold extends ConsumerWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.maxWidth = 480,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.afabColors;
    final l10n = context.l10n;
    final viewportSize = MediaQuery.sizeOf(context);
    final isExpanded = AfabBreakpoints.isExpandedTablet(viewportSize.width) &&
        viewportSize.height >= 520;
    final isTight = viewportSize.width < 360 || viewportSize.height < 640;

    final topControls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _UtilityPill(
          colors: colors,
          child: IconButton(
            tooltip: l10n.moreHubThemeMode,
            constraints: const BoxConstraints.tightFor(width: 38, height: 36),
            padding: EdgeInsets.zero,
            onPressed: () => ref
                .read(appearanceNotifierProvider.notifier)
                .toggleLightDark(Theme.of(context).brightness),
            icon: Icon(
              colors.isDark ? LucideIcons.sun : LucideIcons.moon,
              size: 18,
              color: colors.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _UtilityPill(
          colors: colors,
          child: InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: () =>
                ref.read(localeNotifierProvider.notifier).toggleLocale(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.languages,
                    size: 16,
                    color: colors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.languageSwitchShort,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    Widget buildFormCard() {
      final baseTheme = Theme.of(context);
      return Theme(
        data: baseTheme.copyWith(
          inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isTight ? 13 : 16,
            ),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.isDark
                ? colors.surface.withValues(alpha: 0.92)
                : colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colors.isDark
                  ? colors.primary.withValues(alpha: 0.22)
                  : colors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.isDark
                    ? Colors.black.withValues(alpha: 0.42)
                    : colors.primary.withValues(alpha: 0.06),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            type: MaterialType.transparency,
            child: Padding(
              padding: isTight
                  ? const EdgeInsets.all(16)
                  : const EdgeInsets.fromLTRB(22, 26, 22, 24),
              child: child,
            ),
          ),
        ),
      );
    }

    Widget withBackdrop(Widget content) {
      return Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors.isDark
                    ? [
                        const Color(0xFF040816),
                        const Color(0xFF0B142C),
                        colors.background,
                      ]
                    : [
                        const Color(0xFFF4F7FE),
                        const Color(0xFFEFF4FF),
                        colors.background,
                      ],
              ),
            ),
          ),
          Positioned(
            top: -120,
            left: -80,
            right: -80,
            height: 320,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 0.9,
                    colors: [
                      colors.primary.withValues(
                        alpha: colors.isDark ? 0.22 : 0.10,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          content,
        ],
      );
    }

    if (!isExpanded) {
      return Scaffold(
        body: withBackdrop(
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [topControls],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      isTight ? 12 : 16,
                      isTight ? 8 : 16,
                      isTight ? 12 : 16,
                      28,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: _AuthBrandEmblem(
                                size: isTight ? 68 : 92,
                              ),
                            ),
                            SizedBox(height: isTight ? 10 : 14),
                            Text(
                              l10n.appTitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontSize: isTight ? 24 : 28,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing:
                                        Directionality.of(context) ==
                                                TextDirection.rtl
                                            ? 0
                                            : 2.0,
                                    color: colors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.appTagline,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: isTight ? 12.5 : 14,
                                    color: colors.textMuted,
                                  ),
                            ),
                            SizedBox(height: isTight ? 18 : 26),
                            buildFormCard(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: withBackdrop(
        SafeArea(
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.surface.withValues(
                          alpha: colors.isDark ? 0.90 : 1.0,
                        ),
                        colors.secondaryBg,
                      ],
                    ),
                    border: Border.all(color: colors.border),
                  ),
                  child: LayoutBuilder(
                    builder: (context, panelConstraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: panelConstraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const _AuthBrandEmblem(size: 62),
                                    const SizedBox(width: 14),
                                    Flexible(
                                      child: Text(
                                        l10n.appTitle,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing:
                                                  Directionality.of(context) ==
                                                          TextDirection.rtl
                                                      ? 0
                                                      : 1.5,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.primary
                                            .withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.sparkles,
                                            size: 15,
                                            color: colors.primary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            l10n.appTitle,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  color: colors.primary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      l10n.appTagline,
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayLarge,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      l10n.dashboardUpgradeDesc,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(color: colors.textMuted),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'AFAB Mobile • 100% Multi-Tenant Isolated',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 24, 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [topControls],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 20,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxWidth),
                            child: buildFormCard(),
                          ),
                        ),
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

class _UtilityPill extends StatelessWidget {
  const _UtilityPill({required this.colors, required this.child});

  final AfabColors colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface.withValues(alpha: colors.isDark ? 0.78 : 0.92),
      shape: StadiumBorder(
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _AuthBrandEmblem extends StatelessWidget {
  const _AuthBrandEmblem({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    final isDark = colors.isDark;
    final logoAsset = isDark
        ? 'assets/branding/splash_logo_dark.png'
        : 'assets/branding/splash_logo_light.png';
    final fallbackAsset = isDark
        ? 'assets/images/afab-logo-dark.png'
        : 'assets/images/logo.png';

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: isDark ? 0.78 : 0.45),
            const Color(0xFF0EA5E9).withValues(alpha: isDark ? 0.55 : 0.30),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: isDark ? 0.34 : 0.18),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF020817) : Colors.white,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          logoAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Image.asset(
            fallbackAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Center(
              child: Icon(
                LucideIcons.sparkles,
                size: size * 0.42,
                color: colors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

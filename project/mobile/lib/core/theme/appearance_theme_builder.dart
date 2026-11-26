import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/theme/appearance_settings.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppearanceThemeBuilder {
  static ThemeData build({
    required AppearanceSettings settings,
    required Brightness brightness,
    required Locale locale,
  }) {
    final isDark = brightness == Brightness.dark;
    final (
      primary,
      primaryHover,
      lightTint,
      darkSecondary,
      darkSecondaryFg,
      glowColor,
    ) = settings.resolveAccent();

    final colors = isDark
        ? AfabColors.dark(
            primary: primary,
            primaryHover: primaryHover,
            darkSecondary: darkSecondary,
            darkSecondaryFg: darkSecondaryFg,
            glowColor: glowColor,
            background: settings.darkSurface.background,
            surface: settings.darkSurface.surface,
            surfaceInset: settings.darkSurface.surfaceInset,
            border: settings.darkSurface.border,
          )
        : AfabColors.light(
            primary: primary,
            primaryHover: primaryHover,
            lightTint: lightTint,
            glowColor: glowColor,
          );

    final baseRadius = settings.radius.baseRadius;
    final cardRadius = settings.radius.cardRadius;
    final isCompact = settings.density == AfabDensity.compact;
    final scale = settings.fontSize.scale * (isCompact ? 0.92 : 1.0);

    final baseTextTheme =
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final themedText = _buildTypography(
      baseTextTheme: baseTextTheme,
      fontFamily: settings.fontFamily,
      locale: locale,
      textPrimary: colors.textPrimary,
      textMuted: colors.textMuted,
      scale: scale,
    );

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: Colors.white,
      secondary: colors.secondaryBg,
      onSecondary: colors.secondaryFg,
      error: colors.danger,
      onError: Colors.white,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      outline: colors.border,
      surfaceContainerLowest: colors.background,
      surfaceContainerLow: colors.surfaceInset,
      surfaceContainer: colors.surface,
      surfaceContainerHigh: colors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      textTheme: themedText,
      extensions: [colors],
      dividerColor: colors.border,
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: colors.border)),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: colors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(settings.radius.modalRadius),
          side: BorderSide(color: colors.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(settings.radius.modalRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceInset,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: isCompact ? 11 : 14,
        ),
        hintStyle: themedText.bodyMedium?.copyWith(color: colors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(baseRadius),
          borderSide: BorderSide(color: colors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(baseRadius),
          borderSide: BorderSide(color: colors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(baseRadius),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(baseRadius),
          borderSide: BorderSide(color: colors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(baseRadius),
          borderSide: BorderSide(color: colors.danger, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.secondaryBg,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return themedText.labelSmall?.copyWith(
            color: selected ? colors.primary : colors.textMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.secondaryBg,
        selectedIconTheme: IconThemeData(color: colors.primary),
        unselectedIconTheme: IconThemeData(color: colors.textMuted),
        selectedLabelTextStyle: themedText.labelMedium?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: themedText.labelMedium?.copyWith(
          color: colors.textMuted,
          fontWeight: FontWeight.w500,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(baseRadius),
        ),
      ),
      pageTransitionsTheme: settings.smoothTransitions
          ? const PageTransitionsTheme()
          : const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: _NoAnimPageTransitionBuilder(),
                TargetPlatform.iOS: _NoAnimPageTransitionBuilder(),
              },
            ),
    );
  }

  static TextTheme _buildTypography({
    required TextTheme baseTextTheme,
    required AfabFontFamilyPreset fontFamily,
    required Locale locale,
    required Color textPrimary,
    required Color textMuted,
    required double scale,
  }) {
    final isAr = locale.languageCode == 'ar';
    TextTheme bodyTheme;
    TextTheme headingTheme;

    switch (fontFamily) {
      case AfabFontFamilyPreset.inter:
        bodyTheme = isAr
            ? GoogleFonts.cairoTextTheme(baseTextTheme)
            : GoogleFonts.interTextTheme(baseTextTheme);
        headingTheme = isAr
            ? GoogleFonts.cairoTextTheme(baseTextTheme)
            : GoogleFonts.poppinsTextTheme(baseTextTheme);
      case AfabFontFamilyPreset.serif:
        bodyTheme = isAr
            ? GoogleFonts.amiriTextTheme(baseTextTheme)
            : GoogleFonts.playfairDisplayTextTheme(baseTextTheme);
        headingTheme = bodyTheme;
      case AfabFontFamilyPreset.mono:
        bodyTheme = GoogleFonts.jetBrainsMonoTextTheme(baseTextTheme);
        headingTheme = bodyTheme;
      case AfabFontFamilyPreset.geometric:
        bodyTheme = isAr
            ? GoogleFonts.cairoTextTheme(baseTextTheme)
            : GoogleFonts.montserratTextTheme(baseTextTheme);
        headingTheme = bodyTheme;
      case AfabFontFamilyPreset.kufi:
        bodyTheme = isAr
            ? GoogleFonts.reemKufiTextTheme(baseTextTheme)
            : GoogleFonts.cinzelTextTheme(baseTextTheme);
        headingTheme = bodyTheme;
      case AfabFontFamilyPreset.system:
        bodyTheme = baseTextTheme;
        headingTheme = baseTextTheme;
    }

    TextStyle style(TextStyle? s, double size, FontWeight weight, Color color) {
      return (s ?? const TextStyle()).copyWith(
        fontSize: size * scale,
        fontWeight: weight,
        color: color,
      );
    }

    return bodyTheme.copyWith(
      displayLarge: style(headingTheme.displayLarge, 32, FontWeight.w700, textPrimary),
      headlineLarge: style(headingTheme.headlineLarge, 26, FontWeight.w700, textPrimary),
      headlineMedium: style(headingTheme.headlineMedium, 22, FontWeight.w600, textPrimary),
      titleLarge: style(headingTheme.titleLarge, 18, FontWeight.w700, textPrimary),
      titleMedium: style(headingTheme.titleMedium, 16, FontWeight.w600, textPrimary),
      titleSmall: style(bodyTheme.titleSmall, 14, FontWeight.w600, textPrimary),
      bodyLarge: style(bodyTheme.bodyLarge, 16, FontWeight.w400, textPrimary),
      bodyMedium: style(bodyTheme.bodyMedium, 14, FontWeight.w400, textPrimary),
      bodySmall: style(bodyTheme.bodySmall, 12, FontWeight.w400, textMuted),
      labelLarge: style(bodyTheme.labelLarge, 14, FontWeight.w600, textPrimary),
      labelMedium: style(bodyTheme.labelMedium, 12, FontWeight.w500, textMuted),
      labelSmall: style(bodyTheme.labelSmall, 11, FontWeight.w600, textMuted),
    );
  }
}

class _NoAnimPageTransitionBuilder extends PageTransitionsBuilder {
  const _NoAnimPageTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

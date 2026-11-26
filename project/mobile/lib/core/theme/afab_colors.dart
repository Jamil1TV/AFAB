import 'package:flutter/material.dart';

/// Semantic AFAB design tokens matching `Web/project/frontend/DESIGN_SYSTEM.md`,
/// `app/globals.css`, and `lib/appearance.ts`.
@immutable
class AfabColors extends ThemeExtension<AfabColors> {
  const AfabColors({
    required this.background,
    required this.surface,
    required this.surfaceInset,
    required this.border,
    required this.inputBorder,
    required this.textPrimary,
    required this.textMuted,
    required this.primary,
    required this.primaryHover,
    required this.secondaryBg,
    required this.secondaryFg,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.danger,
    required this.dangerBg,
    required this.info,
    required this.infoBg,
    required this.glowColor,
    required this.chartPalette,
    required this.isDark,
  });

  final Color background;
  final Color surface;
  final Color surfaceInset;
  final Color border;
  final Color inputBorder;
  final Color textPrimary;
  final Color textMuted;
  final Color primary;
  final Color primaryHover;
  final Color secondaryBg;
  final Color secondaryFg;
  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;
  final Color danger;
  final Color dangerBg;
  final Color info;
  final Color infoBg;
  final Color glowColor;
  final List<Color> chartPalette;
  final bool isDark;

  static AfabColors light({
    required Color primary,
    required Color primaryHover,
    required Color lightTint,
    required Color glowColor,
  }) {
    return AfabColors(
      background: const Color(0xFFF8F9FB),
      surface: const Color(0xFFFFFFFF),
      surfaceInset: const Color(0xFFF9FAFB),
      border: const Color(0xFFE5E7EB),
      inputBorder: const Color(0xFFE5E7EB),
      textPrimary: const Color(0xFF111827),
      textMuted: const Color(0xFF6B7280),
      primary: primary,
      primaryHover: primaryHover,
      secondaryBg: lightTint,
      secondaryFg: primaryHover,
      success: const Color(0xFF10B981),
      successBg: const Color(0xFFECFDF5),
      warning: const Color(0xFFF59E0B),
      warningBg: const Color(0xFFFFFBEB),
      danger: const Color(0xFFEF4444),
      dangerBg: const Color(0xFFFEF2F2),
      info: const Color(0xFF0EA5E9),
      infoBg: const Color(0xFFF0F9FF),
      glowColor: glowColor,
      chartPalette: [
        primary,
        const Color(0xFF0EA5E9),
        const Color(0xFF10B981),
        const Color(0xFFF59E0B),
        const Color(0xFFEC4899),
        const Color(0xFF6366F1),
      ],
      isDark: false,
    );
  }

  static AfabColors dark({
    required Color primary,
    required Color primaryHover,
    required Color darkSecondary,
    required Color darkSecondaryFg,
    required Color glowColor,
    required Color background,
    required Color surface,
    required Color surfaceInset,
    required Color border,
  }) {
    return AfabColors(
      background: background,
      surface: surface,
      surfaceInset: surfaceInset,
      border: border,
      inputBorder: const Color(0xFF1F2937),
      textPrimary: const Color(0xFFF9FAFB),
      textMuted: const Color(0xFF9CA3AF),
      primary: primary,
      primaryHover: primaryHover,
      secondaryBg: darkSecondary,
      secondaryFg: darkSecondaryFg,
      success: const Color(0xFF34D399),
      successBg: const Color(0x1A10B981),
      warning: const Color(0xFFFBBF24),
      warningBg: const Color(0x1AF59E0B),
      danger: const Color(0xFFF87171),
      dangerBg: const Color(0x1AEF4444),
      info: const Color(0xFF38BDF8),
      infoBg: const Color(0x1A0EA5E9),
      glowColor: glowColor,
      chartPalette: [
        primary,
        const Color(0xFF38BDF8),
        const Color(0xFF34D399),
        const Color(0xFFFBBF24),
        const Color(0xFFF472B6),
        const Color(0xFF818CF8),
      ],
      isDark: true,
    );
  }

  @override
  AfabColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceInset,
    Color? border,
    Color? inputBorder,
    Color? textPrimary,
    Color? textMuted,
    Color? primary,
    Color? primaryHover,
    Color? secondaryBg,
    Color? secondaryFg,
    Color? success,
    Color? successBg,
    Color? warning,
    Color? warningBg,
    Color? danger,
    Color? dangerBg,
    Color? info,
    Color? infoBg,
    Color? glowColor,
    List<Color>? chartPalette,
    bool? isDark,
  }) {
    return AfabColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceInset: surfaceInset ?? this.surfaceInset,
      border: border ?? this.border,
      inputBorder: inputBorder ?? this.inputBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      secondaryBg: secondaryBg ?? this.secondaryBg,
      secondaryFg: secondaryFg ?? this.secondaryFg,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      warning: warning ?? this.warning,
      warningBg: warningBg ?? this.warningBg,
      danger: danger ?? this.danger,
      dangerBg: dangerBg ?? this.dangerBg,
      info: info ?? this.info,
      infoBg: infoBg ?? this.infoBg,
      glowColor: glowColor ?? this.glowColor,
      chartPalette: chartPalette ?? this.chartPalette,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AfabColors lerp(ThemeExtension<AfabColors>? other, double t) {
    if (other is! AfabColors) return this;
    return AfabColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceInset: Color.lerp(surfaceInset, other.surfaceInset, t)!,
      border: Color.lerp(border, other.border, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      secondaryBg: Color.lerp(secondaryBg, other.secondaryBg, t)!,
      secondaryFg: Color.lerp(secondaryFg, other.secondaryFg, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoBg: Color.lerp(infoBg, other.infoBg, t)!,
      glowColor: Color.lerp(glowColor, other.glowColor, t)!,
      chartPalette: t < 0.5 ? chartPalette : other.chartPalette,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension AfabThemeX on BuildContext {
  AfabColors get afabColors =>
      Theme.of(this).extension<AfabColors>() ??
      AfabColors.light(
        primary: const Color(0xFF8B5CF6),
        primaryHover: const Color(0xFF7C3AED),
        lightTint: const Color(0xFFF5F3FF),
        glowColor: const Color(0x598B5CF6),
      );
}

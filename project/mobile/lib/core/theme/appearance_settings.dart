import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/core/theme/native_theme_sync.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AfabAccentPreset {
  purple(
    id: 'purple',
    primary: Color(0xFF8B5CF6),
    primaryHover: Color(0xFF7C3AED),
    lightTint: Color(0xFFF5F3FF),
    darkSecondary: Color(0xFF191832),
  ),
  blue(
    id: 'blue',
    primary: Color(0xFF3B82F6),
    primaryHover: Color(0xFF2563EB),
    lightTint: Color(0xFFEFF6FF),
    darkSecondary: Color(0xFF172554),
  ),
  emerald(
    id: 'emerald',
    primary: Color(0xFF10B981),
    primaryHover: Color(0xFF059669),
    lightTint: Color(0xFFECFDF5),
    darkSecondary: Color(0xFF064E3B),
  ),
  amber(
    id: 'amber',
    primary: Color(0xFFF59E0B),
    primaryHover: Color(0xFFD97706),
    lightTint: Color(0xFFFFFBEB),
    darkSecondary: Color(0xFF451A03),
  ),
  rose(
    id: 'rose',
    primary: Color(0xFFF43F5E),
    primaryHover: Color(0xFFE11D48),
    lightTint: Color(0xFFFFF1F2),
    darkSecondary: Color(0xFF4C0519),
  ),
  cyan(
    id: 'cyan',
    primary: Color(0xFF06B6D4),
    primaryHover: Color(0xFF0891B2),
    lightTint: Color(0xFFECFEFF),
    darkSecondary: Color(0xFF083344),
  ),
  magenta(
    id: 'magenta',
    primary: Color(0xFFD946EF),
    primaryHover: Color(0xFFC026D3),
    lightTint: Color(0xFFFDF4FF),
    darkSecondary: Color(0xFF4A044E),
  ),
  slate(
    id: 'slate',
    primary: Color(0xFF64748B),
    primaryHover: Color(0xFF475569),
    lightTint: Color(0xFFF8FAFC),
    darkSecondary: Color(0xFF1E293B),
  ),
  custom(
    id: 'custom',
    primary: Color(0xFF8B5CF6),
    primaryHover: Color(0xFF7C3AED),
    lightTint: Color(0xFFF5F3FF),
    darkSecondary: Color(0xFF191832),
  );

  const AfabAccentPreset({
    required this.id,
    required this.primary,
    required this.primaryHover,
    required this.lightTint,
    required this.darkSecondary,
  });

  final String id;
  final Color primary;
  final Color primaryHover;
  final Color lightTint;
  final Color darkSecondary;

  static AfabAccentPreset fromId(String? id) {
    return AfabAccentPreset.values.firstWhere(
      (p) => p.id == id,
      orElse: () => AfabAccentPreset.purple,
    );
  }
}

enum AfabDarkSurface {
  midnight(
    id: 'midnight',
    background: Color(0xFF060813),
    surface: Color(0xFF0C101C),
    surfaceInset: Color(0xFF080C18),
    border: Color(0xFF171F2C),
  ),
  oled(
    id: 'oled',
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    surfaceInset: Color(0xFF050505),
    border: Color(0xFF171717),
  ),
  slate(
    id: 'slate',
    background: Color(0xFF090D16),
    surface: Color(0xFF0F172A),
    surfaceInset: Color(0xFF0B1120),
    border: Color(0xFF1E293B),
  ),
  charcoal(
    id: 'charcoal',
    background: Color(0xFF111318),
    surface: Color(0xFF181B22),
    surfaceInset: Color(0xFF13161C),
    border: Color(0xFF232730),
  );

  const AfabDarkSurface({
    required this.id,
    required this.background,
    required this.surface,
    required this.surfaceInset,
    required this.border,
  });

  final String id;
  final Color background;
  final Color surface;
  final Color surfaceInset;
  final Color border;

  static AfabDarkSurface fromId(String? id) {
    return AfabDarkSurface.values.firstWhere(
      (s) => s.id == id,
      orElse: () => AfabDarkSurface.midnight,
    );
  }
}

enum AfabRadiusPreset {
  sm('sm', 8.0),
  md('md', 12.0),
  lg('lg', 16.0);

  const AfabRadiusPreset(this.id, this.baseRadius);
  final String id;
  final double baseRadius;

  double get cardRadius => baseRadius * 1.33;
  double get modalRadius => math.min(28.0, baseRadius * 2.0);

  static AfabRadiusPreset fromId(String? id) {
    return AfabRadiusPreset.values.firstWhere(
      (r) => r.id == id,
      orElse: () => AfabRadiusPreset.md,
    );
  }
}

enum AfabFontFamilyPreset {
  inter('inter'),
  serif('serif'),
  mono('mono'),
  geometric('geometric'),
  kufi('kufi'),
  system('system');

  const AfabFontFamilyPreset(this.id);
  final String id;

  static AfabFontFamilyPreset fromId(String? id) {
    return AfabFontFamilyPreset.values.firstWhere(
      (f) => f.id == id,
      orElse: () => AfabFontFamilyPreset.inter,
    );
  }
}

enum AfabFontSizePreset {
  sm('sm', 0.875),
  md('md', 1.0),
  lg('lg', 1.125),
  xl('xl', 1.25);

  const AfabFontSizePreset(this.id, this.scale);
  final String id;
  final double scale;

  static AfabFontSizePreset fromId(String? id) {
    return AfabFontSizePreset.values.firstWhere(
      (s) => s.id == id,
      orElse: () => AfabFontSizePreset.md,
    );
  }
}

enum AfabDensity {
  comfortable('comfortable'),
  compact('compact');

  const AfabDensity(this.id);
  final String id;

  static AfabDensity fromId(String? id) {
    return id == 'compact' ? AfabDensity.compact : AfabDensity.comfortable;
  }
}

@immutable
class AppearanceSettings {
  const AppearanceSettings({
    this.themeMode = ThemeMode.system,
    this.accentPreset = AfabAccentPreset.purple,
    this.customPrimaryHex = '#8b5cf6',
    this.darkSurface = AfabDarkSurface.midnight,
    this.radius = AfabRadiusPreset.md,
    this.density = AfabDensity.comfortable,
    this.fontFamily = AfabFontFamilyPreset.inter,
    this.fontSize = AfabFontSizePreset.md,
    this.enableGlow = true,
    this.smoothTransitions = true,
  });

  final ThemeMode themeMode;
  final AfabAccentPreset accentPreset;
  final String customPrimaryHex;
  final AfabDarkSurface darkSurface;
  final AfabRadiusPreset radius;
  final AfabDensity density;
  final AfabFontFamilyPreset fontFamily;
  final AfabFontSizePreset fontSize;
  final bool enableGlow;
  final bool smoothTransitions;

  AppearanceSettings copyWith({
    ThemeMode? themeMode,
    AfabAccentPreset? accentPreset,
    String? customPrimaryHex,
    AfabDarkSurface? darkSurface,
    AfabRadiusPreset? radius,
    AfabDensity? density,
    AfabFontFamilyPreset? fontFamily,
    AfabFontSizePreset? fontSize,
    bool? enableGlow,
    bool? smoothTransitions,
  }) {
    return AppearanceSettings(
      themeMode: themeMode ?? this.themeMode,
      accentPreset: accentPreset ?? this.accentPreset,
      customPrimaryHex: customPrimaryHex ?? this.customPrimaryHex,
      darkSurface: darkSurface ?? this.darkSurface,
      radius: radius ?? this.radius,
      density: density ?? this.density,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      enableGlow: enableGlow ?? this.enableGlow,
      smoothTransitions: smoothTransitions ?? this.smoothTransitions,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'accentPreset': accentPreset.id,
        'customPrimaryColor': customPrimaryHex,
        'darkSurface': darkSurface.id,
        'radius': radius.id,
        'density': density.id,
        'fontFamily': fontFamily.id,
        'fontSize': fontSize.id,
        'enableGlow': enableGlow,
        'smoothTransitions': smoothTransitions,
      };

  factory AppearanceSettings.fromJson(Map<String, dynamic> json) {
    final modeStr = json['themeMode']?.toString();
    final themeMode = switch (modeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return AppearanceSettings(
      themeMode: themeMode,
      accentPreset: AfabAccentPreset.fromId(json['accentPreset']?.toString()),
      customPrimaryHex: json['customPrimaryColor']?.toString() ?? '#8b5cf6',
      darkSurface: AfabDarkSurface.fromId(json['darkSurface']?.toString()),
      radius: AfabRadiusPreset.fromId(json['radius']?.toString()),
      density: AfabDensity.fromId(json['density']?.toString()),
      fontFamily:
          AfabFontFamilyPreset.fromId(json['fontFamily']?.toString()),
      fontSize: AfabFontSizePreset.fromId(json['fontSize']?.toString()),
      enableGlow: json['enableGlow'] as bool? ?? true,
      smoothTransitions: json['smoothTransitions'] as bool? ?? true,
    );
  }

  (Color primary, Color hover, Color lightTint, Color darkSecondary, Color darkSecondaryFg, Color glow)
      resolveAccent() {
    if (accentPreset != AfabAccentPreset.custom) {
      return (
        accentPreset.primary,
        accentPreset.primaryHover,
        accentPreset.lightTint,
        accentPreset.darkSecondary,
        _adjustLightness(accentPreset.primary, 30),
        accentPreset.primary.withValues(alpha: 0.35),
      );
    }
    final parsed = _parseHex(customPrimaryHex) ?? const Color(0xFF8B5CF6);
    return (
      parsed,
      _adjustLightness(parsed, -12),
      _adjustLightness(parsed, 90),
      _adjustLightness(parsed, -75),
      _adjustLightness(parsed, 30),
      parsed.withValues(alpha: 0.40),
    );
  }

  static Color? _parseHex(String hex) {
    final clean = hex.trim().replaceFirst('#', '');
    if (!RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(clean)) return null;
    final val = int.parse('FF$clean', radix: 16);
    return Color(val);
  }

  static Color _adjustLightness(Color color, int pct) {
    final delta = (255 * (pct / 100.0)).round();
    final r = ((color.r * 255).round() + delta).clamp(0, 255);
    final g = ((color.g * 255).round() + delta).clamp(0, 255);
    final b = ((color.b * 255).round() + delta).clamp(0, 255);
    return Color.fromARGB(255, r, g, b);
  }
}

class AppearanceNotifier extends Notifier<AppearanceSettings> {
  @override
  AppearanceSettings build() {
    final raw = ref.read(prefsStoreProvider).getAppearanceJson();
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final loaded = AppearanceSettings.fromJson(decoded);
          Future.microtask(() => NativeThemeSync.sync(loaded.themeMode));
          return loaded;
        }
      } catch (_) {
        // Fallback to default appearance settings.
      }
    }
    Future.microtask(() => NativeThemeSync.sync(ThemeMode.system));
    return const AppearanceSettings();
  }

  Future<void> update(AppearanceSettings next) async {
    state = next;
    unawaited(NativeThemeSync.sync(next.themeMode));
    await ref.read(prefsStoreProvider).setAppearanceJson(jsonEncode(next.toJson()));
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      update(state.copyWith(themeMode: mode));

  Future<void> toggleLightDark(Brightness currentBrightness) {
    final next = currentBrightness == Brightness.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    return setThemeMode(next);
  }

  Future<void> resetDefaults() => update(const AppearanceSettings());

  Future<void> syncCompactFromProfile(bool compactMode) {
    final target = compactMode ? AfabDensity.compact : AfabDensity.comfortable;
    if (state.density == target) return Future.value();
    return update(state.copyWith(density: target));
  }
}

final appearanceNotifierProvider =
    NotifierProvider<AppearanceNotifier, AppearanceSettings>(
  AppearanceNotifier.new,
);

enum AfabLocalePreference { system, en, ar }

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final saved = ref.read(prefsStoreProvider).getLocaleCode();
    return _resolveLocale(saved);
  }

  AfabLocalePreference get preference {
    final saved = ref.read(prefsStoreProvider).getLocaleCode();
    return switch (saved) {
      'system' => AfabLocalePreference.system,
      'ar' => AfabLocalePreference.ar,
      _ => AfabLocalePreference.en,
    };
  }

  static Locale _resolveLocale(String? saved) {
    if (saved == 'ar') return const Locale('ar');
    if (saved == 'system') {
      final sysCode =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      return sysCode == 'ar' ? const Locale('ar') : const Locale('en');
    }
    return const Locale('en');
  }

  Future<void> setPreference(AfabLocalePreference pref) async {
    final code = pref.name;
    await ref.read(prefsStoreProvider).setLocaleCode(code);
    state = _resolveLocale(code);
  }

  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode == 'ar' ? 'ar' : 'en';
    state = Locale(code);
    await ref.read(prefsStoreProvider).setLocaleCode(code);
  }

  Future<void> toggleLocale() {
    final next =
        state.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
    return setLocale(next);
  }
}

final localeNotifierProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);

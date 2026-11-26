import 'package:flutter/material.dart';

/// Defensive CSS/hex color parser handling backend legacy strings such as
/// `"var(--primary)"`, empty strings, `#RRGGBB`, or `#AARRGGBB` without throwing.
abstract final class ColorParser {
  static Color parseHex(String? raw, Color fallback) {
    if (raw == null) return fallback;
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.startsWith('var(')) {
      return fallback;
    }
    var clean = trimmed.startsWith('#') ? trimmed.substring(1) : trimmed;
    if (clean.length == 3) {
      clean = clean.split('').map((c) => '$c$c').join();
    }
    if (clean.length == 6) {
      clean = 'FF$clean';
    }
    if (clean.length != 8) {
      return fallback;
    }
    final parsed = int.tryParse(clean, radix: 16);
    if (parsed == null) return fallback;
    return Color(parsed);
  }
}

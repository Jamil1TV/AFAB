import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shared circular AFAB brand emblem that automatically picks the Light or Dark
/// brand mark based on the active theme brightness.
class AfabBrandLogo extends StatelessWidget {
  const AfabBrandLogo({
    super.key,
    this.size = 84,
    this.showGlowRing = true,
  });

  final double size;
  final bool showGlowRing;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    final isDark = colors.isDark;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cachePx = (size * dpr).round().clamp(48, 512);
    final logoAsset = isDark
        ? 'assets/branding/splash_logo_dark.png'
        : 'assets/branding/splash_logo_light.png';
    final fallbackAsset = isDark
        ? 'assets/images/afab-logo-dark.png'
        : 'assets/images/afab-logo-light.png';

    final inner = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF020817) : Colors.white,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        logoAsset,
        fit: BoxFit.cover,
        cacheWidth: cachePx,
        cacheHeight: cachePx,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => Image.asset(
          fallbackAsset,
          fit: BoxFit.cover,
          cacheWidth: cachePx,
          cacheHeight: cachePx,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => Center(
            child: Icon(
              LucideIcons.sparkles,
              size: size * 0.42,
              color: colors.primary,
            ),
          ),
        ),
      ),
    );

    if (!showGlowRing) {
      return SizedBox(width: size, height: size, child: inner);
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size >= 100 ? 4.0 : 3.5),
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
            color: colors.primary.withValues(alpha: isDark ? 0.34 : 0.16),
            blurRadius: size >= 100 ? 32 : 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: inner,
    );
  }
}

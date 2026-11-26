import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/theme/appearance_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AfabCard extends ConsumerWidget {
  const AfabCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderColor,
    this.backgroundColor,
    this.topAccentColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? backgroundColor;
  final Color? topAccentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.afabColors;
    final appearance = ref.watch(appearanceNotifierProvider);
    final isCompact = appearance.density == AfabDensity.compact;
    final radius = BorderRadius.circular(appearance.radius.cardRadius);
    final resolvedPadding = padding ??
        EdgeInsets.all(isCompact ? 14 : 18);

    Widget content = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.surface,
        borderRadius: radius,
        border: Border.all(color: borderColor ?? colors.border),
        boxShadow: colors.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (topAccentColor != null)
              Container(height: 3, color: topAccentColor),
            Padding(padding: resolvedPadding, child: child),
          ],
        ),
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}

class AfabInsetPanel extends ConsumerWidget {
  const AfabInsetPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.afabColors;
    final appearance = ref.watch(appearanceNotifierProvider);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surfaceInset,
        borderRadius: BorderRadius.circular(appearance.radius.baseRadius),
        border: Border.all(color: borderColor ?? colors.border),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}

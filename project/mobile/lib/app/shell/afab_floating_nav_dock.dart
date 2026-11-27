import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:flutter/material.dart';

/// Descriptor for a single item inside [AfabFloatingNavDock].
class AfabNavDockItem {
  const AfabNavDockItem({
    required this.icon,
    required this.label,
    this.isPrimaryAccent = false,
  });

  final IconData icon;
  final String label;
  final bool isPrimaryAccent;
}

/// Floating frosted-glass pill navigation dock tailored for an AI-first
/// financial cockpit on phones.
///
/// Renders translucent blurred glass over any canvas (including the Copilot fog)
/// with distinct styling for Light and Dark modes, a highlighted center Copilot
/// pill, and downward swipe support for manual tuck-away.
class AfabFloatingNavDock extends StatelessWidget {
  const AfabFloatingNavDock({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.onSwipeDownToHide,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AfabNavDockItem> destinations;
  final VoidCallback? onSwipeDownToHide;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    final isDark = colors.isDark;

    final capsule = RepaintBoundary(
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF181E30).withValues(alpha: 0.96),
                    const Color(0xFF101420).withValues(alpha: 0.96),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.98),
                    const Color(0xFFF4F7FC).withValues(alpha: 0.98),
                  ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.11)
                : colors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.42)
                  : const Color(0xFF0F172A).withValues(alpha: 0.09),
              blurRadius: isDark ? 24 : 22,
              offset: Offset(0, isDark ? 8 : 6),
            ),
          ],
        ),
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.15,
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                _DockItemButton(
                  item: destinations[i],
                  selected: i == selectedIndex,
                  colors: colors,
                  onTap: () => onDestinationSelected(i),
                ),
            ],
          ),
        ),
      ),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        child: onSwipeDownToHide == null
            ? capsule
            : GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragEnd: (details) {
                  if ((details.primaryVelocity ?? 0) > 180) {
                    onSwipeDownToHide!();
                  }
                },
                child: capsule,
              ),
      ),
    );
  }
}

class _DockItemButton extends StatelessWidget {
  const _DockItemButton({
    required this.item,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final AfabNavDockItem item;
  final bool selected;
  final AfabColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = colors.isDark;
    final isAccent = item.isPrimaryAccent;

    final Color iconColor;
    final Color labelColor;
    final BoxDecoration pillDecoration;

    if (isAccent) {
      if (selected) {
        iconColor = Colors.white;
        labelColor = Colors.white;
        pillDecoration = BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primary,
              const Color(0xFF0EA5E9),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: isDark ? 0.36 : 0.24),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        );
      } else {
        iconColor = colors.primary;
        labelColor = colors.primary;
        pillDecoration = BoxDecoration(
          color: colors.primary.withValues(alpha: isDark ? 0.20 : 0.12),
          borderRadius: BorderRadius.circular(22),
        );
      }
    } else if (selected) {
      iconColor = colors.primary;
      labelColor = colors.textPrimary;
      pillDecoration = BoxDecoration(
        color: colors.primary.withValues(alpha: isDark ? 0.18 : 0.11),
        borderRadius: BorderRadius.circular(22),
      );
    } else {
      iconColor = colors.textMuted;
      labelColor = colors.textMuted;
      pillDecoration = BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
      );
    }

    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            decoration: pillDecoration,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(item.icon, size: 19, color: iconColor),
                const SizedBox(height: 2),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.label,
                      maxLines: 1,
                      softWrap: false,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 10.5,
                            fontWeight: (selected || isAccent)
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: labelColor,
                            height: 1.1,
                          ),
                    ),
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

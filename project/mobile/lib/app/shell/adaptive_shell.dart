import 'package:afab_mobile/app/shell/afab_floating_nav_dock.dart';
import 'package:afab_mobile/app/shell/lifecycle_banners.dart';
import 'package:afab_mobile/app/shell/shell_app_bar.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/ai/domain/ai_providers.dart';
import 'package:afab_mobile/features/ai/presentation/global_copilot_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AdaptiveShell extends ConsumerStatefulWidget {
  const AdaptiveShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends ConsumerState<AdaptiveShell> {
  bool _sheetOpen = false;
  bool _navBarVisible = true;
  bool _dockManuallyHidden = false;
  String? _lastPath;

  void _openSheetIfNeeded() {
    if (_sheetOpen || !mounted) return;
    _sheetOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _sheetOpen = false;
        return;
      }
      try {
        await showGlobalCopilotSheet(context, ref);
      } finally {
        _sheetOpen = false;
      }
    });
  }

  bool _handleUserScroll(UserScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification.direction == ScrollDirection.reverse &&
        notification.metrics.pixels > 24 &&
        _navBarVisible) {
      setState(() => _navBarVisible = false);
    } else if ((notification.direction == ScrollDirection.forward ||
            notification.metrics.pixels <= 12) &&
        (!_navBarVisible || _dockManuallyHidden)) {
      setState(() {
        _navBarVisible = true;
        _dockManuallyHidden = false;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final width = context.screenWidth;
    final currentPath = GoRouterState.of(context).uri.path;

    if (currentPath != _lastPath) {
      _lastPath = currentPath;
      _navBarVisible = true;
      _dockManuallyHidden = false;
    }

    ref.listen<CopilotLauncherState>(copilotLauncherProvider, (prev, next) {
      if (next.isOpen && !(prev?.isOpen ?? false)) {
        _openSheetIfNeeded();
      }
    });

    final Widget scaffold;
    if (AfabBreakpoints.isPhone(width)) {
      final isPhoneCopilot = currentPath == '/copilot';
      scaffold = PopScope(
        canPop: !isPhoneCopilot,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && isPhoneCopilot) {
            widget.navigationShell.goBranch(0);
          }
        },
        child: Scaffold(
          appBar: isPhoneCopilot ? null : ShellAppBar(currentPath: currentPath),
          body: SafeArea(
            top: false,
            bottom: false,
            child: NotificationListener<UserScrollNotification>(
              onNotification: _handleUserScroll,
              child: Column(
                children: [
                  LifecycleBanners(includeTopSafeArea: isPhoneCopilot),
                  Expanded(child: widget.navigationShell),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _AutoHideBottomNavBar(
            scrollVisible: _navBarVisible,
            manuallyHidden: _dockManuallyHidden,
            colors: colors,
            onRestore: () => setState(() {
              _dockManuallyHidden = false;
              _navBarVisible = true;
            }),
            child: AfabFloatingNavDock(
              selectedIndex: widget.navigationShell.currentIndex,
              onDestinationSelected: (idx) {
                setState(() {
                  _navBarVisible = true;
                  _dockManuallyHidden = false;
                });
                widget.navigationShell.goBranch(
                  idx,
                  initialLocation: idx == widget.navigationShell.currentIndex,
                );
              },
              onSwipeDownToHide: () =>
                  setState(() => _dockManuallyHidden = true),
              destinations: [
                AfabNavDockItem(
                  icon: LucideIcons.layoutDashboard,
                  label: l10n.navHome,
                ),
                AfabNavDockItem(
                  icon: LucideIcons.arrowRightLeft,
                  label: l10n.navFinance,
                ),
                AfabNavDockItem(
                  icon: LucideIcons.sparkles,
                  label: l10n.navCopilot,
                  isPrimaryAccent: true,
                ),
                AfabNavDockItem(
                  icon: LucideIcons.fileText,
                  label: l10n.navInvoices,
                ),
                AfabNavDockItem(
                  icon: LucideIcons.layoutGrid,
                  label: l10n.navMore,
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      final extended = AfabBreakpoints.isExtendedRail(width);
      final railDestinations = <(String path, String label, IconData icon)>[
        ('/dashboard', l10n.navOverview, LucideIcons.layoutDashboard),
        ('/transactions', l10n.navTransactions, LucideIcons.arrowRightLeft),
        ('/expenses', l10n.navExpenses, LucideIcons.trendingDown),
        ('/revenue', l10n.navRevenue, LucideIcons.trendingUp),
        ('/invoices', l10n.navInvoices, LucideIcons.fileText),
        ('/customers', l10n.navCustomers, LucideIcons.users),
        ('/reports', l10n.navReports, LucideIcons.chartBar),
        ('/currencies', l10n.navCurrencies, LucideIcons.coins),
        ('/copilot', l10n.navAiAssistant, LucideIcons.sparkles),
        ('/calendar', l10n.navCalendar, LucideIcons.calendarDays),
        ('/plans', l10n.navPlans, LucideIcons.crown),
        ('/settings', l10n.navSettings, LucideIcons.settings),
      ];

      var selectedRailIndex = railDestinations.indexWhere(
        (d) => currentPath == d.$1 || currentPath.startsWith('${d.$1}/'),
      );
      if (selectedRailIndex < 0) selectedRailIndex = 0;

      scaffold = Scaffold(
        appBar: ShellAppBar(currentPath: currentPath),
        body: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border:
                    BorderDirectional(end: BorderSide(color: colors.border)),
              ),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.sizeOf(context).height - 60,
                  ),
                  child: IntrinsicHeight(
                    child: NavigationRail(
                      extended: extended,
                      selectedIndex: selectedRailIndex,
                      onDestinationSelected: (idx) {
                        context.go(railDestinations[idx].$1);
                      },
                      destinations: [
                        for (final item in railDestinations)
                          NavigationRailDestination(
                            icon: Icon(item.$3),
                            label: Text(item.$2),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  const LifecycleBanners(),
                  Expanded(child: widget.navigationShell),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
          if (!currentPath.startsWith('/copilot')) {
            ref
                .read(copilotLauncherProvider.notifier)
                .openCopilot(screenContext: {'page': currentPath});
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () {
          if (!currentPath.startsWith('/copilot')) {
            ref
                .read(copilotLauncherProvider.notifier)
                .openCopilot(screenContext: {'page': currentPath});
          }
        },
      },
      child: scaffold,
    );
  }
}

/// Leaf widget that reads keyboard insets locally so IME animations never
/// trigger rebuilds across the whole `AdaptiveShell` + `IndexedStack`.
class _AutoHideBottomNavBar extends StatelessWidget {
  const _AutoHideBottomNavBar({
    required this.scrollVisible,
    required this.manuallyHidden,
    required this.colors,
    required this.onRestore,
    required this.child,
  });

  final bool scrollVisible;
  final bool manuallyHidden;
  final AfabColors colors;
  final VoidCallback onRestore;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final visible = scrollVisible && !manuallyHidden && !keyboardOpen;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (manuallyHidden && !keyboardOpen)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: onRestore,
                child: Container(
                  width: 48,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colors.isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : colors.surface,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: colors.isDark
                          ? Colors.white.withValues(alpha: 0.14)
                          : colors.border,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.chevronUp,
                    size: 14,
                    color: colors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ClipRect(
          child: AnimatedAlign(
            duration: keyboardOpen
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            heightFactor: visible ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !visible,
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

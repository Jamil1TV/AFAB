import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/theme/appearance_settings.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `DASH-02` (Phone More Hub): Categorized access to all secondary
/// modules, quick Theme/Language switches, and Logout.
class MoreHubScreen extends ConsumerWidget {
  const MoreHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final user = ref.watch(authNotifierProvider).user;
    final locale = ref.watch(localeNotifierProvider);

    final operationItems = [
      (l10n.navExpenses, LucideIcons.trendingDown, '/expenses', colors.danger),
      (l10n.navRevenue, LucideIcons.trendingUp, '/revenue', colors.success),
      (l10n.navCategories, LucideIcons.tag, '/categories', colors.primary),
      (l10n.navCustomers, LucideIcons.users, '/customers', colors.info),
      (l10n.navCalendar, LucideIcons.calendarDays, '/calendar', colors.info),
    ];

    final intelligenceItems = [
      (l10n.navCurrencies, LucideIcons.coins, '/currencies', colors.warning),
      (l10n.navReports, LucideIcons.chartBar, '/reports', colors.primary),
    ];

    final workspaceItems = [
      (l10n.navPlans, LucideIcons.crown, '/plans', colors.warning),
      (l10n.navSettings, LucideIcons.settings, '/settings', colors.textMuted),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (user != null) ...[
          AfabCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: colors.secondaryBg,
                  child: Text(
                    user.initials,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                AfabStatusBadge(
                  label: user.planTier.toUpperCase(),
                  variant: AfabBadgeVariant.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        _SectionTitle(title: l10n.moreHubSectionOperations),
        const SizedBox(height: 10),
        _HubGrid(items: operationItems),
        const SizedBox(height: 20),
        _SectionTitle(title: l10n.moreHubSectionIntelligence),
        const SizedBox(height: 10),
        _HubGrid(items: intelligenceItems),
        const SizedBox(height: 20),
        _SectionTitle(title: l10n.moreHubSectionWorkspace),
        const SizedBox(height: 10),
        _HubGrid(items: workspaceItems),
        const SizedBox(height: 20),
        _SectionTitle(title: l10n.moreHubPreferences),
        const SizedBox(height: 10),
        AfabCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  colors.isDark ? LucideIcons.moon : LucideIcons.sun,
                  color: colors.primary,
                ),
                title: Text(l10n.moreHubThemeMode),
                trailing: Text(
                  colors.isDark ? l10n.themeDark : l10n.themeLight,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                onTap: () => ref
                    .read(appearanceNotifierProvider.notifier)
                    .toggleLightDark(Theme.of(context).brightness),
              ),
              Divider(height: 1, color: colors.border),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(LucideIcons.languages, color: colors.primary),
                title: Text(l10n.moreHubLanguage),
                trailing: Text(
                  locale.languageCode == 'ar'
                      ? l10n.languageNameAr
                      : l10n.languageNameEn,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                onTap: () =>
                    ref.read(localeNotifierProvider.notifier).toggleLocale(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AfabButton(
          label: l10n.navLogout,
          icon: LucideIcons.logOut,
          variant: AfabButtonVariant.danger,
          expand: true,
          onPressed: () async {
            await ref.read(authNotifierProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: context.afabColors.textMuted,
          ),
    );
  }
}

class _HubGrid extends StatelessWidget {
  const _HubGrid({required this.items});

  final List<(String, IconData, String, Color)> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 74,
      ),
      itemBuilder: (ctx, index) {
        final (label, icon, route, tint) = items[index];
        return AfabCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          onTap: () => ctx.go(route),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: tint),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

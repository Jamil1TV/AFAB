import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/auth/data/auth_dtos.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/settings/domain/settings_providers.dart';
import 'package:afab_mobile/features/settings/presentation/appearance_settings_screen.dart';
import 'package:afab_mobile/features/settings/presentation/business_profile_screen.dart';
import 'package:afab_mobile/features/settings/presentation/data_export_settings_screen.dart';
import 'package:afab_mobile/features/settings/presentation/general_settings_screen.dart';
import 'package:afab_mobile/features/settings/presentation/language_settings_screen.dart';
import 'package:afab_mobile/features/settings/presentation/security_settings_screen.dart';
import 'package:afab_mobile/features/settings/presentation/settings_coming_soon_screen.dart';
import 'package:afab_mobile/features/settings/presentation/signature_settings_screen.dart';
import 'package:afab_mobile/features/settings/presentation/widgets/edit_profile_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `SET-01`: Categorized Phone Settings Hub + Tablet Master-Detail Workspace
/// covering all 11 AFAB Settings sections + Sign Out.
class SettingsHomeScreen extends ConsumerWidget {
  const SettingsHomeScreen({super.key, this.initialTab});

  final SettingsTabId? initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final user = ref.watch(authNotifierProvider).user;
    final biz = ref.watch(activeBusinessProvider);

    if (initialTab != null) {
      final current = ref.read(selectedSettingsTabProvider);
      if (current != initialTab) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(selectedSettingsTabProvider.notifier).select(initialTab!);
        });
      }
    }

    Future<void> handleSignOut() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.settingsSignOutConfirmTitle),
          content: Text(l10n.settingsSignOutConfirmDesc),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.navLogout),
            ),
          ],
        ),
      );
      if (confirmed == true && context.mounted) {
        await ref.read(authNotifierProvider.notifier).logout();
        if (context.mounted) context.go('/login');
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = !AfabBreakpoints.isPhone(constraints.maxWidth);

          if (!isTablet) {
            return _PhoneSettingsHub(
              user: user,
              bizReadOnly: biz?.isReadOnly ?? false,
              bizName: biz?.name ?? user?.businessName ?? '',
              onSignOut: handleSignOut,
            );
          }

          final selectedTab = ref.watch(selectedSettingsTabProvider);
          return Row(
            children: [
              Container(
                width: 268,
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: BorderDirectional(
                    end: BorderSide(color: colors.border),
                  ),
                ),
                child: Column(
                  children: [
                    if (user != null)
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: _UserHeaderMini(
                          user: user,
                          onEdit: () =>
                              showEditProfileSheet(context, profile: user),
                        ),
                      ),
                    Divider(height: 1, color: colors.border),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(8),
                        children: [
                          for (final item in _buildTabEntries(context, user))
                            _RailTabTile(
                              entry: item,
                              selected: selectedTab == item.id,
                              onTap: () {
                                if (item.id == SettingsTabId.subscription) {
                                  context.go('/plans');
                                } else {
                                  ref
                                      .read(
                                        selectedSettingsTabProvider.notifier,
                                      )
                                      .select(item.id);
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: colors.border),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: AfabButton(
                        label: l10n.navLogout,
                        icon: LucideIcons.logOut,
                        variant: AfabButtonVariant.danger,
                        expand: true,
                        compact: true,
                        onPressed: handleSignOut,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    if (biz?.isReadOnly == true)
                      Container(
                        width: double.infinity,
                        color: colors.warningBg,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          l10n.settingsReadOnlyBanner,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    Expanded(
                      child: switch (selectedTab) {
                        SettingsTabId.general =>
                          const GeneralSettingsScreen(embedded: true),
                        SettingsTabId.businessProfile =>
                          const BusinessProfileScreen(embedded: true),
                        SettingsTabId.signature =>
                          const SignatureSettingsScreen(embedded: true),
                        SettingsTabId.subscription =>
                          const GeneralSettingsScreen(embedded: true),
                        SettingsTabId.usersPermissions =>
                          SettingsComingSoonScreen(
                            tab: ComingSoonSettingsTab.usersPermissions,
                            embedded: true,
                            onBackEmbedded: () => ref
                                .read(selectedSettingsTabProvider.notifier)
                                .select(SettingsTabId.general),
                          ),
                        SettingsTabId.notifications =>
                          SettingsComingSoonScreen(
                            tab: ComingSoonSettingsTab.notifications,
                            embedded: true,
                            onBackEmbedded: () => ref
                                .read(selectedSettingsTabProvider.notifier)
                                .select(SettingsTabId.general),
                          ),
                        SettingsTabId.security =>
                          const SecuritySettingsScreen(embedded: true),
                        SettingsTabId.integrations =>
                          SettingsComingSoonScreen(
                            tab: ComingSoonSettingsTab.integrations,
                            embedded: true,
                            onBackEmbedded: () => ref
                                .read(selectedSettingsTabProvider.notifier)
                                .select(SettingsTabId.general),
                          ),
                        SettingsTabId.dataExport =>
                          const DataExportSettingsScreen(embedded: true),
                        SettingsTabId.appearance =>
                          const AppearanceSettingsScreen(embedded: true),
                        SettingsTabId.language =>
                          const LanguageSettingsScreen(embedded: true),
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsTabEntry {
  const _SettingsTabEntry({
    required this.id,
    required this.route,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeVariant = AfabBadgeVariant.neutral,
  });

  final SettingsTabId id;
  final String route;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final AfabBadgeVariant badgeVariant;
}

List<_SettingsTabEntry> _buildTabEntries(
  BuildContext context,
  UserProfile? user,
) {
  final l10n = context.l10n;
  final lang = Localizations.localeOf(context).languageCode.toUpperCase();
  final twoFactorOn = user?.twoFactorEnabled ?? false;

  return [
    _SettingsTabEntry(
      id: SettingsTabId.general,
      route: '/settings/general',
      icon: LucideIcons.settings,
      title: l10n.settingsTabGeneral,
      subtitle: l10n.settingsTabGeneralSub,
    ),
    _SettingsTabEntry(
      id: SettingsTabId.businessProfile,
      route: '/settings/business-profile',
      icon: LucideIcons.building2,
      title: l10n.settingsTabBusinessProfile,
      subtitle: l10n.settingsTabBusinessProfileSub,
    ),
    _SettingsTabEntry(
      id: SettingsTabId.subscription,
      route: '/plans',
      icon: LucideIcons.creditCard,
      title: l10n.settingsTabSubscription,
      subtitle: l10n.settingsTabSubscriptionSub,
      badge: (user?.planTier ?? 'FREE').toUpperCase(),
      badgeVariant: AfabBadgeVariant.primary,
    ),
    _SettingsTabEntry(
      id: SettingsTabId.usersPermissions,
      route: '/settings/users-permissions',
      icon: LucideIcons.users,
      title: l10n.settingsTabUsersPermissions,
      subtitle: l10n.settingsTabUsersPermissionsSub,
      badge: l10n.settingsBadgeSoon,
    ),
    _SettingsTabEntry(
      id: SettingsTabId.security,
      route: '/settings/security',
      icon: LucideIcons.shieldCheck,
      title: l10n.settingsTabSecurity,
      subtitle: l10n.settingsTabSecuritySub,
      badge: twoFactorOn ? l10n.settingsBadge2faOn : l10n.settingsBadge2faOff,
      badgeVariant:
          twoFactorOn ? AfabBadgeVariant.success : AfabBadgeVariant.warning,
    ),
    _SettingsTabEntry(
      id: SettingsTabId.appearance,
      route: '/settings/appearance',
      icon: LucideIcons.palette,
      title: l10n.settingsTabAppearance,
      subtitle: l10n.settingsTabAppearanceSub,
    ),
    _SettingsTabEntry(
      id: SettingsTabId.signature,
      route: '/settings/signature',
      icon: LucideIcons.penTool,
      title: l10n.settingsTabSignature,
      subtitle: l10n.settingsTabSignatureSub,
      badge: l10n.settingsBadgeLocal,
    ),
    _SettingsTabEntry(
      id: SettingsTabId.language,
      route: '/settings/language',
      icon: LucideIcons.globe,
      title: l10n.settingsTabLanguage,
      subtitle: l10n.settingsTabLanguageSub,
      badge: lang,
      badgeVariant: AfabBadgeVariant.info,
    ),
    _SettingsTabEntry(
      id: SettingsTabId.notifications,
      route: '/settings/notifications',
      icon: LucideIcons.bell,
      title: l10n.settingsTabNotifications,
      subtitle: l10n.settingsTabNotificationsSub,
      badge: l10n.settingsBadgeSoon,
    ),
    _SettingsTabEntry(
      id: SettingsTabId.dataExport,
      route: '/settings/data-export',
      icon: LucideIcons.download,
      title: l10n.settingsTabDataExport,
      subtitle: l10n.settingsTabDataExportSub,
    ),
    _SettingsTabEntry(
      id: SettingsTabId.integrations,
      route: '/settings/integrations',
      icon: LucideIcons.webhook,
      title: l10n.settingsTabIntegrations,
      subtitle: l10n.settingsTabIntegrationsSub,
      badge: l10n.settingsBadgeSoon,
    ),
  ];
}

class _PhoneSettingsHub extends StatelessWidget {
  const _PhoneSettingsHub({
    required this.user,
    required this.bizReadOnly,
    required this.bizName,
    required this.onSignOut,
  });

  final UserProfile? user;
  final bool bizReadOnly;
  final String bizName;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final entries = _buildTabEntries(context, user);

    final accountGroup = entries.sublist(0, 4);
    final securityPrefsGroup = entries.sublist(4, 9);
    final dataGroup = entries.sublist(9, 11);

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user != null) ...[
            AfabCard(
              padding: const EdgeInsets.all(16),
              child: _UserHeaderMini(
                user: user!,
                bizName: bizName,
                bizReadOnly: bizReadOnly,
                onEdit: () => showEditProfileSheet(context, profile: user!),
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (bizReadOnly) ...[
            AfabInsetPanel(
              borderColor: colors.warning.withValues(alpha: 0.4),
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.lock, size: 17, color: colors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.settingsReadOnlyBanner,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          _GroupHeading(title: l10n.settingsGroupAccountWorkspace),
          const SizedBox(height: 8),
          _GroupCard(entries: accountGroup),
          const SizedBox(height: 18),

          _GroupHeading(title: l10n.settingsGroupSecurityPrefs),
          const SizedBox(height: 8),
          _GroupCard(entries: securityPrefsGroup),
          const SizedBox(height: 18),

          _GroupHeading(title: l10n.settingsGroupDataConnections),
          const SizedBox(height: 8),
          _GroupCard(entries: dataGroup),
          const SizedBox(height: 20),

          AfabButton(
            label: l10n.navLogout,
            icon: LucideIcons.logOut,
            variant: AfabButtonVariant.danger,
            expand: true,
            onPressed: onSignOut,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.settingsAppVersion,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _UserHeaderMini extends StatelessWidget {
  const _UserHeaderMini({
    required this.user,
    this.bizName = '',
    this.bizReadOnly = false,
    required this.onEdit,
  });

  final UserProfile user;
  final String bizName;
  final bool bizReadOnly;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final url = user.avatarUrl;
    final avatar = (url != null && url.startsWith('http'))
        ? ClipOval(
            child: CachedNetworkImage(
              imageUrl: url,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => CircleAvatar(
                radius: 24,
                backgroundColor: colors.primary.withValues(alpha: 0.14),
                child: Text(user.initials),
              ),
            ),
          )
        : CircleAvatar(
            radius: 24,
            backgroundColor: colors.primary.withValues(alpha: 0.14),
            child: Text(
              user.initials,
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          );

    return Row(
      children: [
        avatar,
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
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (bizName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    AfabStatusBadge(
                      label: user.planTier.toUpperCase(),
                      variant: AfabBadgeVariant.primary,
                    ),
                    AfabStatusBadge(
                      label: bizReadOnly
                          ? '$bizName (${l10n.plansStatusLocked})'
                          : bizName,
                      variant: bizReadOnly
                          ? AfabBadgeVariant.warning
                          : AfabBadgeVariant.neutral,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        IconButton(
          tooltip: l10n.settingsEditProfile,
          icon: const Icon(LucideIcons.pencil, size: 17),
          onPressed: onEdit,
        ),
      ],
    );
  }
}

class _GroupHeading extends StatelessWidget {
  const _GroupHeading({required this.title});

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

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.entries});

  final List<_SettingsTabEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    return AfabCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            Semantics(
              label:
                  '${entries[i].title}${entries[i].badge != null ? ', ${entries[i].badge}' : ''}',
              child: ListTile(
                onTap: () => context.push(entries[i].route),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(entries[i].icon, size: 18, color: colors.primary),
                ),
                title: Text(entries[i].title),
                subtitle: Text(
                  entries[i].subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (entries[i].badge != null) ...[
                      AfabStatusBadge(
                        label: entries[i].badge!,
                        variant: entries[i].badgeVariant,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: colors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            if (i < entries.length - 1) Divider(height: 1, color: colors.border),
          ],
        ],
      ),
    );
  }
}

class _RailTabTile extends StatelessWidget {
  const _RailTabTile({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final _SettingsTabEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected
            ? colors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Container(
                width: 3,
                height: 44,
                color: selected ? colors.primary : Colors.transparent,
              ),
              const SizedBox(width: 10),
              Icon(
                entry.icon,
                size: 17,
                color: selected ? colors.primary : colors.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Text(
                    entry.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: selected ? colors.primary : colors.textPrimary,
                        ),
                  ),
                ),
              ),
              if (entry.badge != null) ...[
                AfabStatusBadge(
                  label: entry.badge!,
                  variant: entry.badgeVariant,
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

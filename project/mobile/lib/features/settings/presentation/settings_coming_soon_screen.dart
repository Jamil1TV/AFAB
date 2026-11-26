import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/settings/domain/settings_providers.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum ComingSoonSettingsTab { usersPermissions, notifications, integrations }

/// Screen `SET-09`: Honest Coming Soon screen for Settings sections without
/// backend configuration APIs (`users-permissions`, `notifications`, `integrations`).
class SettingsComingSoonScreen extends ConsumerWidget {
  const SettingsComingSoonScreen({
    super.key,
    required this.tab,
    this.embedded = false,
    this.onBackEmbedded,
  });

  final ComingSoonSettingsTab tab;
  final bool embedded;
  final VoidCallback? onBackEmbedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final title = switch (tab) {
      ComingSoonSettingsTab.usersPermissions => l10n.settingsTabUsersPermissions,
      ComingSoonSettingsTab.notifications => l10n.settingsTabNotifications,
      ComingSoonSettingsTab.integrations => l10n.settingsTabIntegrations,
    };

    final body = SettingsComingSoonBody(
      tab: tab,
      onBack: embedded
          ? onBackEmbedded
          : () => context.canPop() ? context.pop() : context.go('/settings'),
    );
    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: body,
    );
  }
}

class SettingsComingSoonBody extends ConsumerWidget {
  const SettingsComingSoonBody({
    super.key,
    required this.tab,
    this.onBack,
  });

  final ComingSoonSettingsTab tab;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final biz = ref.watch(activeBusinessProvider);

    final (icon, title, description) = switch (tab) {
      ComingSoonSettingsTab.usersPermissions => (
          LucideIcons.users,
          l10n.settingsTabUsersPermissions,
          l10n.comingSoonUsersDesc,
        ),
      ComingSoonSettingsTab.notifications => (
          LucideIcons.bell,
          l10n.settingsTabNotifications,
          l10n.comingSoonNotificationsDesc,
        ),
      ComingSoonSettingsTab.integrations => (
          LucideIcons.webhook,
          l10n.settingsTabIntegrations,
          l10n.comingSoonIntegrationsDesc,
        ),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AfabCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, size: 26, color: colors.primary),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    AfabStatusBadge(
                      label: l10n.comingSoonBadge,
                      variant: AfabBadgeVariant.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        if (tab == ComingSoonSettingsTab.notifications)
                          AfabButton(
                            label: l10n.comingSoonOpenNotifCenter,
                            icon: LucideIcons.bellRing,
                            variant: AfabButtonVariant.primary,
                            compact: true,
                            onPressed: () => context.push('/notifications'),
                          ),
                        if (onBack != null)
                          AfabButton(
                            label: l10n.comingSoonBackBtn,
                            variant: AfabButtonVariant.secondary,
                            compact: true,
                            onPressed: onBack,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (tab == ComingSoonSettingsTab.usersPermissions &&
                  biz != null) ...[
                const SizedBox(height: 16),
                _ReadOnlyMembersSection(
                  businessId: biz.id,
                  isEditable: !biz.isReadOnly,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyMembersSection extends ConsumerWidget {
  const _ReadOnlyMembersSection({
    required this.businessId,
    required this.isEditable,
  });

  final String businessId;
  final bool isEditable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.afabColors;

    if (!isEditable) {
      return AfabInsetPanel(
        padding: const EdgeInsets.all(14),
        child: Row(
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
      );
    }

    final membersAsync = ref.watch(businessMembersProvider(businessId));

    return AfabCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.comingSoonMembersTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          membersAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: AfabLoader(size: 36),
              ),
            ),
            error: (err, _) {
              if (err is BusinessReadOnlyFailure) {
                return Text(
                  l10n.settingsReadOnlyBanner,
                  style: Theme.of(context).textTheme.bodySmall,
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      err.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(businessMembersProvider(businessId)),
                    child: Text(l10n.commonRetry),
                  ),
                ],
              );
            },
            data: (members) {
              if (members.isEmpty) {
                return Text(
                  l10n.comingSoonOnlyYou,
                  style: Theme.of(context).textTheme.bodySmall,
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < members.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                colors.primary.withValues(alpha: 0.12),
                            child: Text(
                              members[i].fullName.isNotEmpty
                                  ? members[i].fullName[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  members[i].fullName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    members[i].email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          AfabStatusBadge(
                            label: members[i].role,
                            variant: members[i].role == 'OWNER'
                                ? AfabBadgeVariant.primary
                                : (members[i].role == 'ADMIN'
                                    ? AfabBadgeVariant.info
                                    : AfabBadgeVariant.neutral),
                          ),
                        ],
                      ),
                    ),
                    if (i < members.length - 1)
                      Divider(height: 1, color: colors.border),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

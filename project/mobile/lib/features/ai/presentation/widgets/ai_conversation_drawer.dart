import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/ai/data/ai_dtos.dart';
import 'package:afab_mobile/features/ai/domain/ai_providers.dart';
import 'package:afab_mobile/features/ai/domain/message_direction_resolver.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AiConversationDrawerPanel extends ConsumerWidget {
  const AiConversationDrawerPanel({
    super.key,
    required this.activeConversationId,
    required this.isReadOnly,
    required this.onSelectConversation,
    required this.onNewChat,
    this.onNavigateRoute,
  });

  final String? activeConversationId;
  final bool isReadOnly;
  final ValueChanged<String> onSelectConversation;
  final VoidCallback onNewChat;
  final ValueChanged<String>? onNavigateRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final convAsync = ref.watch(aiConversationsProvider);
    final statusAsync = ref.watch(aiStatusProvider);
    final query = ref.watch(aiConversationSearchQueryProvider).trim().toLowerCase();

    final all = convAsync.value ?? const <AiConversationSummaryDto>[];
    final filtered = query.isEmpty
        ? all
        : all.where((c) => c.title.toLowerCase().contains(query)).toList();

    final grouped = <ConversationDateBucket, List<AiConversationSummaryDto>>{
      for (final b in ConversationDateBucket.values) b: [],
    };
    for (final c in filtered) {
      grouped[classifyConversationDate(c.updatedAt ?? c.createdAt)]!.add(c);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onNavigateRoute != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 2),
            child: Row(
              children: [
                _DrawerNavShortcut(
                  icon: LucideIcons.layoutDashboard,
                  label: l10n.navHome,
                  onTap: () => onNavigateRoute!('/dashboard'),
                ),
                _DrawerNavShortcut(
                  icon: LucideIcons.arrowRightLeft,
                  label: l10n.navFinance,
                  onTap: () => onNavigateRoute!('/transactions'),
                ),
                _DrawerNavShortcut(
                  icon: LucideIcons.fileText,
                  label: l10n.navInvoices,
                  onTap: () => onNavigateRoute!('/invoices'),
                ),
                _DrawerNavShortcut(
                  icon: LucideIcons.layoutGrid,
                  label: l10n.navMore,
                  onTap: () => onNavigateRoute!('/more'),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: AfabButton(
            label: l10n.aiNewChat,
            icon: LucideIcons.plus,
            variant: AfabButtonVariant.soft,
            expand: true,
            onPressed: onNewChat,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: TextField(
            onChanged: (v) => ref
                .read(aiConversationSearchQueryProvider.notifier)
                .setQuery(v),
            decoration: InputDecoration(
              hintText: l10n.aiSearchConversations,
              prefixIcon: const Icon(LucideIcons.search, size: 16),
              isDense: true,
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(LucideIcons.x, size: 15),
                      onPressed: () => ref
                          .read(aiConversationSearchQueryProvider.notifier)
                          .setQuery(''),
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: Row(
            children: [
              Text(
                l10n.aiHistoryTitle,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const Spacer(),
              Directionality(
                textDirection: TextDirection.ltr,
                child: AfabStatusBadge(
                  label: '${all.length}',
                  variant: AfabBadgeVariant.neutral,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: convAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(14),
              child: Text(err.toString()),
            ),
            data: (_) {
              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      l10n.aiNoConversations,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                children: [
                  for (final bucket in ConversationDateBucket.values)
                    if (grouped[bucket]!.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
                        child: Text(
                          switch (bucket) {
                            ConversationDateBucket.today => l10n.aiGroupToday,
                            ConversationDateBucket.yesterday =>
                              l10n.aiGroupYesterday,
                            ConversationDateBucket.week => l10n.aiGroupWeek,
                            ConversationDateBucket.earlier => l10n.aiGroupEarlier,
                          },
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colors.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      for (final conv in grouped[bucket]!)
                        _ConversationTile(
                          conversation: conv,
                          selected: conv.id == activeConversationId,
                          canDelete: !isReadOnly,
                          onTap: () => onSelectConversation(conv.id),
                          onDelete: () =>
                              _confirmDelete(context, ref, conv),
                        ),
                    ],
                ],
              );
            },
          ),
        ),
        if (statusAsync.value != null)
          _QuotaMeterCard(usage: statusAsync.value!.quota),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AiConversationSummaryDto conv,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.aiDeleteConvConfirmTitle),
        content: Text(l10n.aiDeleteConvConfirmDesc(conv.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(aiConversationsProvider.notifier)
          .deleteConversation(conv.id);
      if (conv.id == activeConversationId) {
        ref.read(aiStudioControllerProvider.notifier).startNewConversation();
      }
    } on AppFailure catch (e) {
      if (context.mounted) AfabToast.showError(context, e.message);
    }
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.selected,
    required this.canDelete,
    required this.onTap,
    required this.onDelete,
  });

  final AiConversationSummaryDto conversation;
  final bool selected;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected
            ? colors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected
                ? colors.primary.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: onTap,
          contentPadding: const EdgeInsetsDirectional.fromSTEB(10, 0, 2, 0),
          title: Text(
            conversation.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? colors.primary : colors.textPrimary,
                ),
          ),
          trailing: canDelete
              ? IconButton(
                  tooltip: context.l10n.aiDeleteConversation,
                  icon: Icon(
                    LucideIcons.trash2,
                    size: 16,
                    color: colors.textMuted,
                  ),
                  onPressed: onDelete,
                )
              : null,
        ),
      ),
    );
  }
}

class _QuotaMeterCard extends StatelessWidget {
  const _QuotaMeterCard({required this.usage});
  final AiTokenUsageDto usage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final pct = usage.tokenPercent;
    final barColor = pct >= 90
        ? colors.danger
        : (pct >= 75 ? colors.warning : colors.primary);
    final tokensLimitStr =
        usage.isTokensUnlimited ? l10n.aiUnlimited : '${usage.monthlyTokensLimit}';
    final queriesLimitStr =
        usage.isQueriesUnlimited ? '∞' : '${usage.monthlyQueriesLimit}';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: AfabInsetPanel(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(LucideIcons.zap, size: 15, color: colors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.aiTokensLabel,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                AfabStatusBadge(
                  label: usage.planName.toUpperCase(),
                  variant: AfabBadgeVariant.primary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: usage.isTokensUnlimited ? 0.1 : (pct / 100.0),
                minHeight: 7,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 6),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.aiQuotaRatio(
                      '${usage.monthlyTokensUsed}',
                      tokensLimitStr,
                    ),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                  Text(
                    '${usage.monthlyQueriesUsed}/$queriesLimitStr ${l10n.aiQueriesLabel}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                  ),
                ],
              ),
            ),
            if (pct >= 75) ...[
              const SizedBox(height: 8),
              AfabButton(
                label: l10n.aiUpgradeCta,
                compact: true,
                expand: true,
                onPressed: () => context.push('/plans'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DrawerNavShortcut extends StatelessWidget {
  const _DrawerNavShortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: colors.textMuted),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10.5,
                      color: colors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

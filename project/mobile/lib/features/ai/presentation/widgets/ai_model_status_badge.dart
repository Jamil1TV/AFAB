import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/ai/domain/ai_providers.dart';
import 'package:afab_mobile/shared/widgets/afab_bottom_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AiModelStatusBadge extends ConsumerWidget {
  const AiModelStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final state = ref.watch(aiHealthProvider);
    final h = state.health;

    late final String label;
    late final Color fg;
    late final Color bg;
    late final IconData icon;

    if (!state.backendConnected) {
      label = l10n.aiLiveBackendOffline;
      fg = colors.danger;
      bg = colors.dangerBg;
      icon = LucideIcons.wifiOff;
    } else if (h == null) {
      label = l10n.aiLiveChecking;
      fg = colors.textMuted;
      bg = colors.surfaceInset;
      icon = LucideIcons.cpu;
    } else if (!h.ollamaReachable) {
      label = l10n.aiModelOffline;
      fg = colors.warning;
      bg = colors.warningBg;
      icon = LucideIcons.triangleAlert;
    } else if (!h.chatModelReady) {
      label = l10n.aiModelMissing;
      fg = colors.warning;
      bg = colors.warningBg;
      icon = LucideIcons.download;
    } else if (h.busy) {
      label = '${h.chatModel} · ${l10n.aiLiveBusy}';
      fg = colors.primary;
      bg = colors.primary.withValues(alpha: 0.12);
      icon = LucideIcons.sparkles;
    } else if (h.chatModelLoaded) {
      label = '${h.chatModel} · ${l10n.aiLiveHotShort} · ${h.latencyMs}ms';
      fg = colors.success;
      bg = colors.successBg;
      icon = LucideIcons.zap;
    } else {
      label = '${h.chatModel} · ${l10n.aiLiveReadyShort} · ${h.latencyMs}ms';
      fg = colors.success;
      bg = colors.successBg;
      icon = LucideIcons.circleCheck;
    }

    return Semantics(
      button: true,
      label: '${l10n.aiLiveTitle}: $label',
      child: InkWell(
        onTap: () => showAiModelHealthSheet(context),
        borderRadius: BorderRadius.circular(99),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 210),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: fg.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 5),
              Flexible(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showAiModelHealthSheet(BuildContext context) {
  final isTablet = !AfabBreakpoints.isPhone(MediaQuery.sizeOf(context).width);
  if (isTablet) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: _AiModelHealthBody(showHeader: true),
          ),
        ),
      ),
    );
  }

  return showAfabBottomSheet<void>(
    context: context,
    title: context.l10n.aiLiveTitle,
    builder: (_) => const _AiModelHealthBody(showHeader: false),
  );
}

class _AiModelHealthBody extends ConsumerWidget {
  const _AiModelHealthBody({required this.showHeader});
  final bool showHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final state = ref.watch(aiHealthProvider);
    final h = state.health;
    final timeStr = state.lastChecked != null
        ? DateFormat('HH:mm:ss', 'en_US').format(state.lastChecked!)
        : '--:--:--';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.aiLiveTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              AfabStatusBadge(
                label: l10n.aiLiveRealtimeBadge,
                variant: state.backendConnected
                    ? AfabBadgeVariant.success
                    : AfabBadgeVariant.danger,
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        AfabInsetPanel(
          child: Column(
            children: [
              _HealthRow(
                label: l10n.aiLiveBackendLabel,
                statusText: state.backendConnected
                    ? l10n.aiLiveConnected
                    : l10n.aiLiveReconnecting,
                ok: state.backendConnected,
              ),
              Divider(height: 18, color: colors.border),
              _HealthRow(
                label: l10n.aiLiveOllamaLabel,
                statusText: h == null
                    ? l10n.aiLiveChecking
                    : (h.ollamaReachable
                        ? '${l10n.aiLiveOnline} (${h.latencyMs}ms)'
                        : l10n.aiLiveOffline),
                ok: h?.ollamaReachable ?? false,
              ),
              Divider(height: 18, color: colors.border),
              _HealthRow(
                label: l10n.aiLiveChatModelLabel,
                subtitle: h?.chatModel ?? 'gemma4:e4b',
                statusText: h == null
                    ? l10n.aiLiveChecking
                    : (!h.chatModelReady
                        ? l10n.aiLiveMissing
                        : (h.chatModelLoaded
                            ? l10n.aiLiveHotInGpu
                            : l10n.aiLiveColdShort)),
                ok: h?.chatModelReady ?? false,
              ),
              Divider(height: 18, color: colors.border),
              _HealthRow(
                label: l10n.aiLiveEmbedModelLabel,
                subtitle: h?.embedModel ?? 'embeddinggemma-2:270m',
                statusText: h == null
                    ? l10n.aiLiveChecking
                    : (h.embedModelReady
                        ? l10n.aiLiveReadyShort
                        : l10n.aiLiveMissing),
                ok: h?.embedModelReady ?? false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '${l10n.aiLiveLastChecked}: $timeStr',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            AfabButton(
              label:
                  state.checking ? l10n.aiLiveChecking : l10n.aiLiveCheckNow,
              icon: LucideIcons.refreshCw,
              compact: true,
              isLoading: state.checking,
              onPressed: state.checking
                  ? null
                  : () => ref.read(aiHealthProvider.notifier).checkNow(fresh: true),
            ),
          ],
        ),
      ],
    );
  }
}

class _HealthRow extends StatelessWidget {
  const _HealthRow({
    required this.label,
    required this.statusText,
    required this.ok,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final String statusText;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              if (subtitle != null && subtitle!.isNotEmpty)
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        AfabStatusBadge(
          label: statusText,
          variant: ok ? AfabBadgeVariant.success : AfabBadgeVariant.warning,
        ),
      ],
    );
  }
}

import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/ai/data/ai_dtos.dart';
import 'package:afab_mobile/features/ai/domain/message_direction_resolver.dart';
import 'package:afab_mobile/features/ai/presentation/widgets/attachment_preview_chip.dart';
import 'package:afab_mobile/features/ai/presentation/widgets/copilot_action_draft_card.dart';
import 'package:afab_mobile/features/ai/presentation/widgets/copilot_chart_card.dart';
import 'package:afab_mobile/features/ai/presentation/widgets/copilot_markdown.dart';
import 'package:afab_mobile/features/ai/presentation/widgets/copilot_memory_proposal_card.dart';
import 'package:afab_mobile/features/ai/presentation/widgets/copilot_reminder_card.dart';
import 'package:afab_mobile/shared/widgets/afab_brand_logo.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:afab_mobile/shared/widgets/money_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CopilotMessageBubble extends StatefulWidget {
  const CopilotMessageBubble({
    super.key,
    required this.message,
    required this.isReadOnly,
    this.isLatestAssistant = false,
    this.canRegenerate = false,
    this.onRegenerate,
    this.onDraftUpdated,
    this.onEvidenceNavigate,
  });

  final AiMessageDto message;
  final bool isReadOnly;
  final bool isLatestAssistant;
  final bool canRegenerate;
  final VoidCallback? onRegenerate;
  final void Function(String messageId, AiActionDraftDto updated)? onDraftUpdated;
  final ValueChanged<String>? onEvidenceNavigate;

  @override
  State<CopilotMessageBubble> createState() => _CopilotMessageBubbleState();
}

class _CopilotMessageBubbleState extends State<CopilotMessageBubble> {
  bool _thoughtExpanded = false;
  bool _detailsExpanded = false;
  bool _copied = false;

  Future<void> _copyMessage() async {
    await Clipboard.setData(ClipboardData(text: widget.message.content));
    if (!mounted) return;
    setState(() => _copied = true);
    AfabToast.showSuccess(context, context.l10n.aiCopied);
  }

  Color _evidenceTint(String type, AfabColors colors) {
    return switch (type.toUpperCase()) {
      'INVOICE' => colors.danger,
      'TRANSACTION' => colors.primary,
      'BUDGET' => colors.success,
      'MEMORY' || 'CUSTOMER' => colors.info,
      _ => colors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final msg = widget.message;
    final timeStr = msg.createdAt != null
        ? DateFormat('HH:mm', 'en_US').format(msg.createdAt!.toLocal())
        : '';
    final msgDir = MessageDirectionResolver.resolveForMessage(
      msg.content,
      responseLanguage: msg.responseLanguage,
    );

    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              width: constraints.maxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (msg.attachments.isNotEmpty) ...[
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final att in msg.attachments)
                          AttachmentPreviewChip(attachment: att, compact: true),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.82,
                    ),
                    child: GestureDetector(
                      onLongPress: _copyMessage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: colors.isDark
                              ? Colors.white.withValues(alpha: 0.085)
                              : colors.primary.withValues(alpha: 0.09),
                          border: Border.all(
                            color: colors.isDark
                                ? Colors.white.withValues(alpha: 0.07)
                                : colors.primary.withValues(alpha: 0.16),
                          ),
                          borderRadius: const BorderRadiusDirectional.only(
                            topStart: Radius.circular(24),
                            topEnd: Radius.circular(24),
                            bottomStart: Radius.circular(24),
                            bottomEnd: Radius.circular(8),
                          ),
                        ),
                        child: Directionality(
                          textDirection: msgDir,
                          child: SelectableText(
                            msg.content,
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: colors.isDark
                                          ? Colors.white.withValues(alpha: 0.94)
                                          : colors.textPrimary,
                                      fontSize: 15.5,
                                      height: 1.45,
                                    ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    final latencyStr = (msg.latencyMs != null && msg.latencyMs! > 0)
        ? '${(msg.latencyMs! / 1000).toStringAsFixed(1)}s'
        : null;
    final hasDetails = (msg.modelId != null && msg.modelId!.isNotEmpty) ||
        msg.totalTokens > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Minimal Assistant Header
          Row(
            children: [
              const AfabBrandLogo(size: 22, showGlowRing: false),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.aiCopilotName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textMuted,
                      ),
                ),
              ),
              if (msg.reasoningMode.toLowerCase() == 'deep') ...[
                const SizedBox(width: 6),
                AfabStatusBadge(
                  label: l10n.aiDeepModeBadge,
                  variant: AfabBadgeVariant.primary,
                ),
              ],
              const Spacer(),
              if (timeStr.isNotEmpty)
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    timeStr,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 11.5,
                          color: colors.textMuted,
                        ),
                  ),
                ),
            ],
          ),

          // Collapsible Deep Reasoning Trace
          if (msg.thinkingContent != null &&
              msg.thinkingContent!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () =>
                  setState(() => _thoughtExpanded = !_thoughtExpanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.brain,
                      size: 14,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.aiReasoningTrace,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colors.primary,
                          ),
                    ),
                    const Spacer(),
                    Icon(
                      _thoughtExpanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 15,
                      color: colors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            if (_thoughtExpanded)
              AfabInsetPanel(
                padding: const EdgeInsets.all(10),
                child: Directionality(
                  textDirection: msgDir,
                  child: Text(
                    msg.thinkingContent!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
          ],

          // Tools Used Strip
          if (msg.toolsUsed.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tool in msg.toolsUsed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.successBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.wrench,
                          size: 11,
                          color: colors.success,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            localizedToolLabel(l10n, tool),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: colors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],

          // Main Markdown Content (per-message BiDi directionality)
          if (msg.content.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Directionality(
              textDirection: msgDir,
              child: CopilotMarkdown(content: msg.content),
            ),
          ],

          // Charts
          if (msg.charts.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < msg.charts.length; i++) ...[
              CopilotChartCard(chart: msg.charts[i]),
              if (i < msg.charts.length - 1) const SizedBox(height: 10),
            ],
          ],

          // Action Drafts (5 types)
          if (msg.actionDrafts.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < msg.actionDrafts.length; i++) ...[
              _buildDraftCard(msg.actionDrafts[i]),
              if (i < msg.actionDrafts.length - 1) const SizedBox(height: 10),
            ],
          ],

          // Verified Sources & Evidence
          if (msg.evidence.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(LucideIcons.database, size: 14, color: colors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${l10n.aiEvidenceTitle} (${l10n.aiSourcesCount(msg.evidence.length)})',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 8.0;
                final evidenceCols =
                    constraints.maxWidth > AfabBreakpoints.phoneMax ? 2 : 1;
                final tileWidth = evidenceCols == 2
                    ? (constraints.maxWidth - gap) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final ev in msg.evidence)
                      _buildEvidenceTile(context, ev, tileWidth, colors),
                  ],
                );
              },
            ),
          ],

          // Compact Quiet Action Bar (Copy, Regenerate, Optional Details Disclosure)
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                tooltip: _copied ? l10n.aiCopied : l10n.aiCopy,
                constraints:
                    const BoxConstraints.tightFor(width: 32, height: 32),
                padding: EdgeInsets.zero,
                onPressed: _copyMessage,
                icon: Icon(
                  _copied ? LucideIcons.check : LucideIcons.copy,
                  size: 15,
                  color: _copied ? colors.success : colors.textMuted,
                ),
              ),
              if (widget.isLatestAssistant &&
                  widget.canRegenerate &&
                  widget.onRegenerate != null)
                IconButton(
                  tooltip: l10n.aiRegenerate,
                  constraints:
                      const BoxConstraints.tightFor(width: 32, height: 32),
                  padding: EdgeInsets.zero,
                  onPressed: widget.onRegenerate,
                  icon: Icon(
                    LucideIcons.rotateCcw,
                    size: 15,
                    color: colors.textMuted,
                  ),
                ),
              if (hasDetails || latencyStr != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () =>
                      setState(() => _detailsExpanded = !_detailsExpanded),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.info,
                          size: 14,
                          color: _detailsExpanded
                              ? colors.primary
                              : colors.textMuted,
                        ),
                        if (latencyStr != null) ...[
                          const SizedBox(width: 4),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              latencyStr,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    fontSize: 11.5,
                                    color: _detailsExpanded
                                        ? colors.primary
                                        : colors.textMuted,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_detailsExpanded) ...[
            const SizedBox(height: 6),
            AfabInsetPanel(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (msg.modelId != null && msg.modelId!.isNotEmpty)
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: AfabStatusBadge(
                            label: msg.modelId!,
                            variant: AfabBadgeVariant.neutral,
                          ),
                        ),
                      if (msg.totalTokens > 0)
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: AfabStatusBadge(
                            label: l10n.aiTokensUsedBadge('${msg.totalTokens}'),
                            variant: AfabBadgeVariant.neutral,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    msg.dataCoverage == 'RAG_GROUNDED'
                        ? l10n.aiCoverageRag
                        : l10n.aiCoveragePartial,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.textMuted,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDraftCard(AiActionDraftDto draft) {
    void handleUpdated(AiActionDraftDto updated) {
      widget.onDraftUpdated?.call(widget.message.id, updated);
    }

    return switch (draft.actionType) {
      'PAYMENT_REMINDER' => CopilotReminderCard(draft: draft),
      'SAVE_MEMORY' => CopilotMemoryProposalCard(
          messageId: widget.message.id,
          draft: draft,
          isReadOnly: widget.isReadOnly,
          onUpdated: handleUpdated,
        ),
      _ => CopilotActionDraftCard(
          messageId: widget.message.id,
          draft: draft,
          isReadOnly: widget.isReadOnly,
          onUpdated: handleUpdated,
        ),
    };
  }

  Widget _buildEvidenceTile(
    BuildContext context,
    AiEvidenceItemDto ev,
    double width,
    AfabColors colors,
  ) {
    final tint = _evidenceTint(ev.type, colors);
    final route = mapWebHrefToMobileRoute(ev.href);

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () {
          if (widget.onEvidenceNavigate != null) {
            widget.onEvidenceNavigate!(route);
          } else {
            context.go(route);
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.surfaceInset,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ev.type,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: tint,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const Spacer(),
                  if (ev.amount != null)
                    MoneyText(
                      amount: ev.amount!,
                      currency: ev.currency ?? 'USD',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                ev.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              if (ev.subtitle != null && ev.subtitle!.trim().isNotEmpty)
                Text(
                  ev.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

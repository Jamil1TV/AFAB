import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/ai/data/ai_dtos.dart';
import 'package:afab_mobile/features/ai/data/ai_repository.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CopilotMemoryProposalCard extends ConsumerStatefulWidget {
  const CopilotMemoryProposalCard({
    super.key,
    required this.messageId,
    required this.draft,
    required this.isReadOnly,
    required this.onUpdated,
  });

  final String messageId;
  final AiActionDraftDto draft;
  final bool isReadOnly;
  final ValueChanged<AiActionDraftDto> onUpdated;

  @override
  ConsumerState<CopilotMemoryProposalCard> createState() =>
      _CopilotMemoryProposalCardState();
}

class _CopilotMemoryProposalCardState
    extends ConsumerState<CopilotMemoryProposalCard> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final p = widget.draft.payload;
    _titleCtrl = TextEditingController(
      text: (p['title'] ?? widget.draft.summary).toString(),
    );
    _contentCtrl = TextEditingController(
      text: (p['content'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (_busy || title.isEmpty || content.isEmpty) return;
    setState(() => _busy = true);
    try {
      final updated = await ref.read(aiRepositoryProvider).approveMemoryDraft({
        'messageId': widget.messageId,
        'draftId': widget.draft.draftId,
        'memoryType':
            (widget.draft.payload['memoryType'] ?? 'TRANSACTION_CONTEXT')
                .toString(),
        'title': title,
        'content': content,
      });
      if (!mounted) return;
      AfabToast.showSuccess(context, context.l10n.aiMemoryProposalSaved);
      widget.onUpdated(updated);
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    } catch (_) {
      if (mounted) {
        AfabToast.showError(context, context.l10n.aiMemoryProposalSaveFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _dismiss() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final updated = await ref.read(aiRepositoryProvider).dismissDraft(
            messageId: widget.messageId,
            draftId: widget.draft.draftId,
          );
      if (mounted) widget.onUpdated(updated);
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;

    if (widget.draft.status == 'APPROVED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: colors.successBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.check, size: 15, color: colors.success),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${l10n.aiMemoryProposalSaved}: ${_titleCtrl.text.trim()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.success,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    if (widget.draft.status == 'DISMISSED') {
      return const SizedBox.shrink();
    }

    return AfabInsetPanel(
      borderColor: colors.info.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.brain, size: 16, color: colors.info),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.aiMemoryProposalHeading,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.info,
                      ),
                ),
              ),
              IconButton(
                onPressed: (_busy || widget.isReadOnly) ? null : _dismiss,
                icon: const Icon(LucideIcons.x, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            enabled: !widget.isReadOnly && !_busy,
            maxLength: 160,
            decoration: const InputDecoration(counterText: '', isDense: true),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contentCtrl,
            enabled: !widget.isReadOnly && !_busy,
            minLines: 2,
            maxLines: 4,
            maxLength: 2000,
            decoration: const InputDecoration(counterText: '', isDense: true),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              AfabButton(
                label: l10n.aiMemoryProposalIgnore,
                variant: AfabButtonVariant.secondary,
                compact: true,
                onPressed: (_busy || widget.isReadOnly) ? null : _dismiss,
              ),
              AfabButton(
                label: l10n.aiMemoryProposalRemember,
                icon: LucideIcons.check,
                compact: true,
                isLoading: _busy,
                onPressed: (_busy || widget.isReadOnly) ? null : _save,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

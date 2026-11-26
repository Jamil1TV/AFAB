import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/navigation/copilot_prompt_request.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/ai/domain/ai_providers.dart';
import 'package:afab_mobile/features/ai/presentation/widgets/copilot_composer.dart';
import 'package:afab_mobile/features/ai/presentation/widgets/copilot_message_bubble.dart';
import 'package:afab_mobile/features/ai/presentation/widgets/copilot_thinking_card.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `AI-02`: Global Contextual Copilot Sheet (`DraggableScrollableSheet` on
/// phone `< 600dp`, end-edge modal side sheet on tablet `>= 600dp`).
Future<void> showGlobalCopilotSheet(BuildContext context, WidgetRef ref) async {
  final width = MediaQuery.sizeOf(context).width;
  final isPhone = AfabBreakpoints.isPhone(width);

  if (isPhone) {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.50,
        maxChildSize: 0.96,
        expand: false,
        builder: (sheetCtx, scrollController) => Container(
          decoration: BoxDecoration(
            color: sheetCtx.afabColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: _GlobalCopilotSheetBody(
            isPhone: true,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  } else {
    final sheetWidth =
        width >= AfabBreakpoints.tabletRailExtendedMin ? 540.0 : 460.0;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogCtx, _, _) {
        final colors = dialogCtx.afabColors;
        return Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Material(
            color: colors.surface,
            elevation: 8,
            child: Container(
              width: sheetWidth,
              height: double.infinity,
              decoration: BoxDecoration(
                border: BorderDirectional(
                  start: BorderSide(color: colors.border),
                ),
              ),
              child: const SafeArea(
                child: _GlobalCopilotSheetBody(isPhone: false),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final isRtl = Directionality.of(ctx) == TextDirection.rtl;
        final begin = Offset(isRtl ? -1.0 : 1.0, 0);
        return SlideTransition(
          position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
    );
  }

  ref.read(copilotLauncherProvider.notifier).closeCopilot();
}

class _GlobalCopilotSheetBody extends ConsumerStatefulWidget {
  const _GlobalCopilotSheetBody({
    required this.isPhone,
    this.scrollController,
  });

  final bool isPhone;
  final ScrollController? scrollController;

  @override
  ConsumerState<_GlobalCopilotSheetBody> createState() =>
      _GlobalCopilotSheetBodyState();
}

class _GlobalCopilotSheetBodyState
    extends ConsumerState<_GlobalCopilotSheetBody> {
  final _inputCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final _internalScrollCtrl = ScrollController();
  int _lastConsumedNonce = -1;

  ScrollController get _effectiveScrollCtrl =>
      widget.scrollController ?? _internalScrollCtrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _consumeLaunchRequest(ref.read(copilotLauncherProvider).pendingRequest);
      SemanticsService.sendAnnouncement(
        View.of(context),
        context.l10n.aiDrawerTitle,
        Directionality.of(context),
      );
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _focusNode.dispose();
    _internalScrollCtrl.dispose();
    super.dispose();
  }

  void _consumeLaunchRequest(CopilotLaunchRequest? req) {
    if (req == null || req.nonce == _lastConsumedNonce) return;
    _lastConsumedNonce = req.nonce;
    ref.read(copilotLauncherProvider.notifier).clearPendingRequest();

    final controller = ref.read(globalCopilotSheetControllerProvider.notifier);
    if (req.reasoningMode != null) {
      controller.setReasoningMode(req.reasoningMode!);
    }
    if (req.screenContext.isNotEmpty) {
      controller.setPendingScreenContext(req.screenContext);
    }

    final prompt = req.prompt?.trim() ?? '';
    if (prompt.isNotEmpty) {
      if (req.autoSend) {
        if (ref.read(globalCopilotSheetControllerProvider).sending) {
          AfabToast.showInfo(context, context.l10n.aiAlreadyRespondingToast);
          return;
        }
        final uiLocale = Localizations.localeOf(context).languageCode;
        controller.sendMessage(
          rawPrompt: prompt,
          uiLocale: uiLocale,
          modeOverride: req.reasoningMode,
          screenContextOverride: req.screenContext,
        );
      } else {
        _inputCtrl.text = prompt;
        _inputCtrl.selection =
            TextSelection.collapsed(offset: _inputCtrl.text.length);
        _focusNode.requestFocus();
      }
    }
  }

  void _handleSend([String? promptOverride]) {
    final chatState = ref.read(globalCopilotSheetControllerProvider);
    final controller = ref.read(globalCopilotSheetControllerProvider.notifier);
    final text = promptOverride ?? _inputCtrl.text;
    if (text.trim().isEmpty && chatState.stagedAttachments.isEmpty) return;

    if (promptOverride == null) {
      _inputCtrl.clear();
    }
    final uiLocale = Localizations.localeOf(context).languageCode;
    controller.sendMessage(rawPrompt: text, uiLocale: uiLocale);
  }

  void _openFullView() {
    final convId =
        ref.read(globalCopilotSheetControllerProvider).activeConversationId;
    Navigator.of(context).pop();
    context.go(
      '/copilot',
      extra: convId != null && convId.isNotEmpty
          ? CopilotPromptRequest(
              prompt: '',
              autoSend: false,
              screenContext: {'conversationId': convId},
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final biz = ref.watch(activeBusinessProvider);
    final isReadOnly = biz?.isReadOnly ?? false;
    final chatState = ref.watch(globalCopilotSheetControllerProvider);

    ref.listen<CopilotLauncherState>(copilotLauncherProvider, (_, next) {
      if (next.isOpen && next.pendingRequest != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _consumeLaunchRequest(next.pendingRequest);
        });
      }
    });

    ref.listen<String?>(
      globalCopilotSheetControllerProvider.select((s) => s.restoredDraftInput),
      (_, restored) {
        if (restored != null && restored.isNotEmpty) {
          _inputCtrl.text = restored;
          _inputCtrl.selection =
              TextSelection.collapsed(offset: _inputCtrl.text.length);
          ref
              .read(globalCopilotSheetControllerProvider.notifier)
              .clearRestoredInput();
        }
      },
    );

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final contextLabel = chatState.pendingScreenContext['invoiceNumber'] ??
        chatState.pendingScreenContext['budgetName'] ??
        chatState.pendingScreenContext['metric'] ??
        chatState.pendingScreenContext['page'];

    return AnimatedPadding(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        children: [
          if (widget.isPhone)
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),

          // Sheet Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Icon(
                    LucideIcons.sparkles,
                    size: 17,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.aiDrawerTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (MediaQuery.sizeOf(context).width >= 360)
                        Text(
                          l10n.aiDrawerSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _openFullView,
                  icon: const Icon(LucideIcons.externalLink, size: 13),
                  label: Text(l10n.aiOpenWorkspace),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.commonClose,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x, size: 19),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.border),

          if (contextLabel != null && contextLabel.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: colors.surfaceInset,
              child: Text(
                'Context: $contextLabel',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),

          if (chatState.chatError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: colors.dangerBg,
              child: Row(
                children: [
                  Icon(
                    LucideIcons.circleAlert,
                    size: 15,
                    color: colors.danger,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatState.chatError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.danger,
                          ),
                    ),
                  ),
                  IconButton(
                    constraints:
                        const BoxConstraints.tightFor(width: 28, height: 28),
                    padding: EdgeInsets.zero,
                    icon: const Icon(LucideIcons.x, size: 14),
                    onPressed: () => ref
                        .read(globalCopilotSheetControllerProvider.notifier)
                        .clearError(),
                  ),
                ],
              ),
            ),

          // Message Canvas
          Expanded(
            child: (chatState.messages.isEmpty && !chatState.sending)
                ? ListView(
                    controller: _effectiveScrollCtrl,
                    padding: const EdgeInsets.all(16),
                    children: [
                      AfabInsetPanel(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            Icon(
                              LucideIcons.sparkles,
                              size: 28,
                              color: colors.primary,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.aiDrawerEmptyTitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.aiDrawerEmptyDesc,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                AfabButton(
                                  label: l10n.aiMorningBriefButton,
                                  icon: LucideIcons.sunrise,
                                  compact: true,
                                  onPressed: isReadOnly
                                      ? null
                                      : () =>
                                          _handleSend(l10n.aiMorningBriefPrompt),
                                ),
                                AfabButton(
                                  label: l10n.aiPromptInvoicesTitle,
                                  variant: AfabButtonVariant.secondary,
                                  compact: true,
                                  onPressed: isReadOnly
                                      ? null
                                      : () =>
                                          _handleSend(l10n.aiPromptInvoicesText),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    controller: _effectiveScrollCtrl,
                    physics: widget.isPhone
                        ? const AlwaysScrollableScrollPhysics()
                        : null,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < chatState.messages.length; i++)
                          CopilotMessageBubble(
                            message: chatState.messages[i],
                            isReadOnly: isReadOnly,
                            onDraftUpdated: (msgId, updated) => ref
                                .read(globalCopilotSheetControllerProvider.notifier)
                                .updateDraftInMessage(msgId, updated),
                            onEvidenceNavigate: (route) {
                              Navigator.of(context).pop();
                              context.go(route);
                            },
                          ),
                        if (chatState.sending)
                          CopilotThinkingCard(
                            streamPhase: chatState.streamPhase,
                            streamingText: chatState.streamingText,
                            thinkingText: chatState.thinkingText,
                            activeTools: chatState.activeTools,
                            completedTools: chatState.completedTools,
                          ),
                        if (!chatState.sending &&
                            chatState.suggestedFollowUps.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final f in chatState.suggestedFollowUps)
                                ActionChip(
                                  label: Text(f),
                                  onPressed:
                                      isReadOnly ? null : () => _handleSend(f),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
          ),

          // Shared Composer
          CopilotComposer(
            controller: _inputCtrl,
            focusNode: _focusNode,
            stagedAttachments: chatState.stagedAttachments,
            reasoningMode: chatState.reasoningMode,
            sending: chatState.sending,
            uploadingAttachment: chatState.uploadingAttachment,
            isReadOnly: isReadOnly,
            compact: true,
            onReasoningModeChanged: (m) => ref
                .read(globalCopilotSheetControllerProvider.notifier)
                .setReasoningMode(m),
            onSend: _handleSend,
            onStop: () => ref
                .read(globalCopilotSheetControllerProvider.notifier)
                .stopStreaming(),
            onStageAttachment: ({
              required bytes,
              required filename,
              contentType,
            }) =>
                ref
                    .read(globalCopilotSheetControllerProvider.notifier)
                    .stageAttachment(
                      bytes: bytes,
                      filename: filename,
                      contentType: contentType,
                    ),
            onRemoveAttachment: (id) => ref
                .read(globalCopilotSheetControllerProvider.notifier)
                .removeStagedAttachment(id),
          ),
        ],
      ),
    );
  }
}

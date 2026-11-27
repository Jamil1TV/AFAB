import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/navigation/copilot_prompt_request.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/ai/data/ai_dtos.dart';
import 'package:afab_mobile/features/ai/domain/ai_providers.dart';
import 'package:afab_mobile/features/ai/domain/message_direction_resolver.dart';
import 'package:afab_mobile/features/ai/presentation/business_memory_screen.dart';
import 'package:afab_mobile/features/ai/presentation/widgets/ai_conversation_drawer.dart';
import 'package:afab_mobile/features/ai/presentation/widgets/ai_model_status_badge.dart';
import 'package:afab_mobile/features/ai/presentation/widgets/copilot_aurora_backdrop.dart';
import 'package:afab_mobile/features/ai/presentation/widgets/copilot_composer.dart';
import 'package:afab_mobile/features/ai/presentation/widgets/copilot_message_bubble.dart';
import 'package:afab_mobile/features/ai/presentation/widgets/copilot_thinking_card.dart';
import 'package:afab_mobile/features/ai/presentation/widgets/copilot_welcome.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/business/presentation/business_switcher_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_bottom_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `AI-01`: AFAB Copilot Studio (`P5-01`).
class AiCopilotScreen extends ConsumerStatefulWidget {
  const AiCopilotScreen({
    super.key,
    this.initialPromptRequest,
    this.initialConversationId,
  });

  final CopilotPromptRequest? initialPromptRequest;
  final String? initialConversationId;

  @override
  ConsumerState<AiCopilotScreen> createState() => _AiCopilotScreenState();
}

class _AiCopilotScreenState extends ConsumerState<AiCopilotScreen>
    with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _inputCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollCtrl = ScrollController();

  bool _sidebarOpen = true;
  bool _memoryPaneOpen = false;
  bool _syncingIndex = false;
  bool _showJumpToBottom = false;
  bool _wasFocused = false;
  double _lastKeyboardInset = 0;
  CopilotPromptRequest? _lastHandledPrompt;
  String? _lastLoadedConvId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollCtrl.addListener(_onScroll);
    _focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _consumeRouteExtras();
    });
  }

  @override
  void didUpdateWidget(covariant AiCopilotScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPromptRequest != oldWidget.initialPromptRequest ||
        widget.initialConversationId != oldWidget.initialConversationId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _consumeRouteExtras();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.removeListener(_onFocusChange);
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    final nowFocused = _focusNode.hasFocus;
    if (nowFocused && !_wasFocused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToBottom();
      });
    }
    _wasFocused = nowFocused;
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final bottomInset =
        WidgetsBinding.instance.platformDispatcher.views.firstOrNull?.viewInsets
                .bottom ??
            0.0;
    if (bottomInset > _lastKeyboardInset && _scrollCtrl.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToBottom(immediate: true);
      });
    }
    _lastKeyboardInset = bottomInset;
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final distFromBottom =
        _scrollCtrl.position.maxScrollExtent - _scrollCtrl.offset;
    final show = distFromBottom > 140;
    if (show != _showJumpToBottom && mounted) {
      setState(() => _showJumpToBottom = show);
    }
  }

  void _scrollToBottom({bool immediate = false}) {
    if (!_scrollCtrl.hasClients) return;
    final target = _scrollCtrl.position.maxScrollExtent;
    if (target <= 0) return;
    if (immediate) {
      _scrollCtrl.jumpTo(target);
      return;
    }
    _scrollCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _consumeRouteExtras() {
    final convId = widget.initialConversationId ??
        widget.initialPromptRequest?.screenContext['conversationId']?.toString();
    if (convId != null &&
        convId.isNotEmpty &&
        convId != _lastLoadedConvId &&
        (widget.initialPromptRequest?.prompt.trim().isEmpty ?? true)) {
      _lastLoadedConvId = convId;
      ref.read(aiStudioControllerProvider.notifier).loadConversation(convId);
      return;
    }

    final req = widget.initialPromptRequest;
    if (req == null || identical(req, _lastHandledPrompt)) return;
    _lastHandledPrompt = req;
    final prompt = req.prompt.trim();
    if (prompt.isEmpty) return;

    final ctxMap = <String, String>{
      for (final e in req.screenContext.entries)
        if (e.value != null) e.key: e.value.toString(),
    };

    if (req.autoSend) {
      if (ref.read(aiStudioControllerProvider).sending) {
        AfabToast.showInfo(context, context.l10n.aiAlreadyRespondingToast);
        return;
      }
      final uiLocale = Localizations.localeOf(context).languageCode;
      ref.read(aiStudioControllerProvider.notifier).sendMessage(
            rawPrompt: prompt,
            uiLocale: uiLocale,
            screenContextOverride: ctxMap,
          );
    } else {
      ref.read(aiStudioControllerProvider.notifier).setPendingScreenContext(ctxMap);
      _inputCtrl.text = prompt;
      _inputCtrl.selection =
          TextSelection.collapsed(offset: _inputCtrl.text.length);
      _focusNode.requestFocus();
    }
  }

  Future<void> _syncIndex() async {
    if (_syncingIndex) return;
    setState(() => _syncingIndex = true);
    try {
      final res = await ref.read(aiStatusProvider.notifier).syncIndex();
      if (!mounted) return;
      AfabToast.showSuccess(
        context,
        context.l10n.aiSyncSuccess(res.indexedCount, res.embeddingsGenerated),
      );
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    } catch (_) {
      if (mounted) AfabToast.showError(context, context.l10n.aiSyncError);
    } finally {
      if (mounted) setState(() => _syncingIndex = false);
    }
  }

  void _handleSend([String? promptOverride]) {
    final chatState = ref.read(aiStudioControllerProvider);
    final controller = ref.read(aiStudioControllerProvider.notifier);
    final raw = promptOverride ?? _inputCtrl.text;
    if (raw.trim().isEmpty && chatState.stagedAttachments.isEmpty) return;
    if (promptOverride == null) {
      _inputCtrl.clear();
    }
    final uiLocale = Localizations.localeOf(context).languageCode;
    controller.sendMessage(rawPrompt: raw, uiLocale: uiLocale);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _openMemory({required bool canDockPane}) {
    if (canDockPane) {
      setState(() => _memoryPaneOpen = !_memoryPaneOpen);
    } else {
      context.push('/copilot/memory');
    }
  }

  void _openModeAndWorkspaceSheet({
    required BuildContext context,
    required AiReasoningMode currentMode,
    required bool sending,
    String? businessName,
  }) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: colors.isDark ? 0.60 : 0.34),
      builder: (dialogCtx) => Align(
        alignment: const Alignment(0, -0.35),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Material(
              color: colors.isDark ? const Color(0xFF191C22) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              elevation: colors.isDark ? 12 : 6,
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      enabled: !sending,
                      leading: Icon(
                        LucideIcons.zap,
                        size: 19,
                        color: currentMode == AiReasoningMode.fast
                            ? colors.primary
                            : colors.textMuted,
                      ),
                      title: Text(
                        l10n.aiFastMode,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        l10n.aiLiveTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.textMuted, fontSize: 12),
                      ),
                      trailing: currentMode == AiReasoningMode.fast
                          ? Icon(
                              LucideIcons.check,
                              size: 18,
                              color: colors.primary,
                            )
                          : null,
                      onTap: sending
                          ? null
                          : () {
                              ref
                                  .read(aiStudioControllerProvider.notifier)
                                  .setReasoningMode(AiReasoningMode.fast);
                              Navigator.of(dialogCtx).pop();
                            },
                    ),
                    ListTile(
                      enabled: !sending,
                      leading: Icon(
                        LucideIcons.brain,
                        size: 19,
                        color: currentMode == AiReasoningMode.deep
                            ? colors.primary
                            : colors.textMuted,
                      ),
                      title: Text(
                        l10n.aiDeepMode,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: currentMode == AiReasoningMode.deep
                          ? Icon(
                              LucideIcons.check,
                              size: 18,
                              color: colors.primary,
                            )
                          : null,
                      onTap: sending
                          ? null
                          : () {
                              ref
                                  .read(aiStudioControllerProvider.notifier)
                                  .setReasoningMode(AiReasoningMode.deep);
                              Navigator.of(dialogCtx).pop();
                            },
                    ),
                    if (businessName != null && businessName.isNotEmpty) ...[
                      Divider(height: 12, color: colors.border),
                      ListTile(
                        leading: Icon(
                          LucideIcons.building2,
                          size: 18,
                          color: colors.textMuted,
                        ),
                        title: Text(
                          businessName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Icon(
                          LucideIcons.chevronsUpDown,
                          size: 15,
                          color: colors.textMuted,
                        ),
                        onTap: () {
                          Navigator.of(dialogCtx).pop();
                          showBusinessSwitcherSheet(context);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openMobileOptionsSheet({
    required BuildContext context,
    required AiReasoningMode currentMode,
    required bool sending,
    required bool isReadOnly,
    required int indexedCount,
    required int memoriesCount,
    required String langLabel,
    String? businessName,
  }) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    showAfabBottomSheet<void>(
      context: context,
      title: l10n.aiTitle,
      builder: (sheetCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.aiLiveTitle,
                  style: Theme.of(sheetCtx).textTheme.labelLarge,
                ),
                const AiModelStatusBadge(),
              ],
            ),
          ),
          Divider(height: 16, color: colors.border),
          ListTile(
            contentPadding: EdgeInsets.zero,
            enabled: !sending,
            leading: Icon(
              currentMode == AiReasoningMode.deep
                  ? LucideIcons.brain
                  : LucideIcons.zap,
              size: 19,
              color: colors.primary,
            ),
            title: Text(
              currentMode == AiReasoningMode.deep
                  ? l10n.aiDeepMode
                  : l10n.aiFastMode,
            ),
            trailing: TextButton(
              onPressed: sending
                  ? null
                  : () {
                      final next = currentMode == AiReasoningMode.deep
                          ? AiReasoningMode.fast
                          : AiReasoningMode.deep;
                      ref
                          .read(aiStudioControllerProvider.notifier)
                          .setReasoningMode(next);
                      Navigator.of(sheetCtx).pop();
                    },
              child: Text(
                currentMode == AiReasoningMode.deep
                    ? l10n.aiFastMode
                    : l10n.aiDeepMode,
              ),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(LucideIcons.brain, size: 19, color: colors.primary),
            title: Text('${l10n.aiMemoryButton} ($memoriesCount)'),
            onTap: () {
              Navigator.of(sheetCtx).pop();
              _openMemory(canDockPane: false);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            enabled: !isReadOnly && !_syncingIndex,
            leading: _syncingIndex
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  )
                : Icon(
                    LucideIcons.refreshCw,
                    size: 19,
                    color: colors.textMuted,
                  ),
            title: Text('${l10n.aiSyncIndexButton} ($indexedCount)'),
            onTap: (isReadOnly || _syncingIndex)
                ? null
                : () {
                    Navigator.of(sheetCtx).pop();
                    _syncIndex();
                  },
          ),
          if (businessName != null && businessName.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                LucideIcons.building2,
                size: 19,
                color: colors.textMuted,
              ),
              title: Text(businessName),
              trailing: langLabel.isNotEmpty
                  ? AfabStatusBadge(
                      label: langLabel,
                      variant: AfabBadgeVariant.primary,
                    )
                  : Icon(
                      LucideIcons.chevronsUpDown,
                      size: 15,
                      color: colors.textMuted,
                    ),
              onTap: () {
                Navigator.of(sheetCtx).pop();
                showBusinessSwitcherSheet(context);
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final biz = ref.watch(activeBusinessProvider);
    final isReadOnly = biz?.isReadOnly ?? false;

    final chatState = ref.watch(aiStudioControllerProvider);
    final statusAsync = ref.watch(aiStatusProvider);
    final memoriesCount = statusAsync.value?.approvedMemories ?? 0;
    final indexedCount = statusAsync.value?.indexedChunks ?? 0;
    final langLabel =
        localizedAiLanguageLabel(l10n, chatState.activeLanguage);

    ref.listen<String?>(
      aiStudioControllerProvider.select((s) => s.restoredDraftInput),
      (_, restored) {
        if (restored != null && restored.isNotEmpty) {
          _inputCtrl.text = restored;
          _inputCtrl.selection =
              TextSelection.collapsed(offset: _inputCtrl.text.length);
          ref.read(aiStudioControllerProvider.notifier).clearRestoredInput();
        }
      },
    );

    ref.listen<(int, int)>(
      aiStudioControllerProvider.select(
        (s) => (s.messages.length, s.streamingText.length),
      ),
      (prev, next) {
        if ((prev?.$1 != next.$1 || prev?.$2 != next.$2) &&
            !_showJumpToBottom) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _scrollToBottom();
          });
        }
      },
    );

    final hasParentScaffold = Scaffold.maybeOf(context) != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isExpandedSidebar = AfabBreakpoints.isExpandedTablet(width);
        final canDockMemory = width >= 1024;
        final mainWidth = width -
            ((isExpandedSidebar && _sidebarOpen) ? 280.0 : 0.0) -
            ((canDockMemory && _memoryPaneOpen) ? 390.0 : 0.0);
        final wideHeader = mainWidth >= 860;

        final drawerPanel = AiConversationDrawerPanel(
          activeConversationId: chatState.activeConversationId,
          isReadOnly: isReadOnly,
          onNavigateRoute: hasParentScaffold && !isExpandedSidebar
              ? (route) {
                  _scaffoldKey.currentState?.closeDrawer();
                  context.go(route);
                }
              : null,
          onSelectConversation: (id) {
            ref.read(aiStudioControllerProvider.notifier).loadConversation(id);
            if (!isExpandedSidebar) {
              _scaffoldKey.currentState?.closeDrawer();
            }
          },
          onNewChat: () {
            ref
                .read(aiStudioControllerProvider.notifier)
                .startNewConversation();
            if (!isExpandedSidebar) {
              _scaffoldKey.currentState?.closeDrawer();
            }
          },
        );

        final followUpsCount =
            (!chatState.sending && chatState.suggestedFollowUps.isNotEmpty)
                ? 1
                : 0;
        final thinkingCount = chatState.sending ? 1 : 0;
        final listItemCount =
            chatState.messages.length + thinkingCount + followUpsCount;

        final modeLabel = chatState.reasoningMode == AiReasoningMode.deep
            ? l10n.aiDeepMode
            : l10n.aiFastMode;

        final Widget headerBar;
        if (wideHeader) {
          headerBar = Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.72),
              border: Border(
                bottom: BorderSide(
                  color: colors.border.withValues(alpha: 0.7),
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: l10n.aiToggleSidebar,
                  constraints: const BoxConstraints.tightFor(
                    width: 38,
                    height: 38,
                  ),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    isExpandedSidebar
                        ? (_sidebarOpen
                            ? LucideIcons.panelLeftClose
                            : LucideIcons.panelLeftOpen)
                        : LucideIcons.menu,
                    size: 19,
                  ),
                  onPressed: () {
                    if (isExpandedSidebar) {
                      setState(() => _sidebarOpen = !_sidebarOpen);
                    } else {
                      _scaffoldKey.currentState?.openDrawer();
                    }
                  },
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          chatState.activeConversationTitle ?? l10n.aiTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      if (langLabel.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        AfabStatusBadge(
                          label: langLabel,
                          variant: AfabBadgeVariant.primary,
                        ),
                      ],
                    ],
                  ),
                ),
                const AiModelStatusBadge(),
                const SizedBox(width: 4),
                if (!isExpandedSidebar ||
                    !_sidebarOpen ||
                    chatState.messages.isNotEmpty)
                  IconButton(
                    tooltip: l10n.aiNewChat,
                    constraints: const BoxConstraints.tightFor(
                      width: 38,
                      height: 38,
                    ),
                    padding: EdgeInsets.zero,
                    icon: const Icon(LucideIcons.plus, size: 19),
                    onPressed: () => ref
                        .read(aiStudioControllerProvider.notifier)
                        .startNewConversation(),
                  ),
                TextButton.icon(
                  onPressed:
                      (isReadOnly || _syncingIndex) ? null : _syncIndex,
                  icon: _syncingIndex
                      ? SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.primary,
                          ),
                        )
                      : const Icon(LucideIcons.refreshCw, size: 14),
                  label: Text('${l10n.aiSyncIndexButton} ($indexedCount)'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _openMemory(canDockPane: canDockMemory),
                  icon: const Icon(LucideIcons.brain, size: 15),
                  label: Text('${l10n.aiMemoryButton} ($memoriesCount)'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          );
        } else {
          headerBar = Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Row(
              children: [
                _FloatingGlassPill(
                  colors: colors,
                  child: IconButton(
                    tooltip: l10n.aiToggleSidebar,
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      isExpandedSidebar
                          ? (_sidebarOpen
                              ? LucideIcons.panelLeftClose
                              : LucideIcons.panelLeftOpen)
                          : LucideIcons.equal,
                      size: 19,
                      color: colors.textPrimary,
                    ),
                    onPressed: () {
                      if (isExpandedSidebar) {
                        setState(() => _sidebarOpen = !_sidebarOpen);
                      } else {
                        _scaffoldKey.currentState?.openDrawer();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _openModeAndWorkspaceSheet(
                      context: context,
                      currentMode: chatState.reasoningMode,
                      sending: chatState.sending,
                      businessName: biz?.name,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  l10n.appTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  modeLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w500,
                                        color: colors.textMuted,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                LucideIcons.chevronDown,
                                size: 15,
                                color: colors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              const _CopilotLiveStatusDot(),
                            ],
                          ),
                          if ((chatState.activeConversationTitle ??
                                  biz?.name) !=
                              null)
                            Text(
                              chatState.activeConversationTitle ?? biz!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    fontSize: 11.5,
                                    color: colors.textMuted,
                                  ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _FloatingGlassPill(
                  colors: colors,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: l10n.aiNewChat,
                        constraints: const BoxConstraints.tightFor(
                          width: 38,
                          height: 40,
                        ),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          LucideIcons.squarePen,
                          size: 17,
                          color: colors.textPrimary,
                        ),
                        onPressed: () => ref
                            .read(aiStudioControllerProvider.notifier)
                            .startNewConversation(),
                      ),
                      IconButton(
                        tooltip: l10n.aiLiveTitle,
                        constraints: const BoxConstraints.tightFor(
                          width: 38,
                          height: 40,
                        ),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          LucideIcons.ellipsis,
                          size: 18,
                          color: colors.textPrimary,
                        ),
                        onPressed: () => _openMobileOptionsSheet(
                          context: context,
                          currentMode: chatState.reasoningMode,
                          sending: chatState.sending,
                          isReadOnly: isReadOnly,
                          indexedCount: indexedCount,
                          memoriesCount: memoriesCount,
                          langLabel: langLabel,
                          businessName: biz?.name,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final studioMain = Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(decoration: BoxDecoration(color: colors.background)),
            const Positioned.fill(
              child: _CopilotAuroraLayer(),
            ),
            SafeArea(
              top: AfabBreakpoints.isPhone(width) || !hasParentScaffold,
              bottom: false,
              child: Column(
                children: [
                  headerBar,

            // Conditional Banners (isolated from root health polling)
            const _CopilotOfflineBanner(),

            if (chatState.quotaExhaustedMsg != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: colors.dangerBg,
                child: Row(
                  children: [
                    Icon(LucideIcons.zap, size: 16, color: colors.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${l10n.aiQuotaExhaustedTitle} · ${chatState.quotaExhaustedMsg}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AfabButton(
                      label: l10n.aiUpgradeCta,
                      compact: true,
                      onPressed: () => context.push('/plans'),
                    ),
                  ],
                ),
              ),

            if (chatState.chatError != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                color: colors.dangerBg,
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.circleAlert,
                      size: 16,
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
                      tooltip: l10n.aiDismissError,
                      constraints:
                          const BoxConstraints.tightFor(width: 30, height: 30),
                      padding: EdgeInsets.zero,
                      icon: const Icon(LucideIcons.x, size: 15),
                      onPressed: () => ref
                          .read(aiStudioControllerProvider.notifier)
                          .clearError(),
                    ),
                  ],
                ),
              ),

            // Conversation Canvas
            Expanded(
              child: Stack(
                children: [
                  if (chatState.loadingConversation)
                    Center(
                      child: AfabLoader(size: 54, label: l10n.aiLoading),
                    )
                  else if (chatState.messages.isEmpty && !chatState.sending)
                    CopilotWelcome(
                      disabled: isReadOnly,
                      onSendPrompt: (prompt) => _handleSend(prompt),
                      onPrefillPrompt: (prefix) {
                        _inputCtrl.text = prefix;
                        _inputCtrl.selection = TextSelection.collapsed(
                          offset: _inputCtrl.text.length,
                        );
                        _focusNode.requestFocus();
                      },
                      onOpenAttachmentPicker: () =>
                          CopilotComposer.showAttachmentSourceSheet(
                        context,
                        currentCount: chatState.stagedAttachments.length,
                        onStage: ({
                          required bytes,
                          required filename,
                          contentType,
                        }) =>
                            ref
                                .read(aiStudioControllerProvider.notifier)
                                .stageAttachment(
                                  bytes: bytes,
                                  filename: filename,
                                  contentType: contentType,
                                ),
                      ),
                    )
                  else
                    ListView.builder(
                      controller: _scrollCtrl,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                      itemCount: listItemCount,
                      itemBuilder: (context, index) {
                        late final Widget itemChild;
                        if (index < chatState.messages.length) {
                          final msg = chatState.messages[index];
                          itemChild = CopilotMessageBubble(
                            key: ValueKey(msg.id),
                            message: msg,
                            isReadOnly: isReadOnly,
                            isLatestAssistant:
                                index == chatState.messages.length - 1 &&
                                    msg.isAssistant,
                            canRegenerate: !chatState.sending && !isReadOnly,
                            onRegenerate: () => ref
                                .read(aiStudioControllerProvider.notifier)
                                .regenerateLastResponse(
                                  uiLocale: Localizations.localeOf(context)
                                      .languageCode,
                                ),
                            onDraftUpdated: (msgId, updated) => ref
                                .read(aiStudioControllerProvider.notifier)
                                .updateDraftInMessage(msgId, updated),
                          );
                        } else if (chatState.sending &&
                            index == chatState.messages.length) {
                          itemChild = CopilotThinkingCard(
                            streamPhase: chatState.streamPhase,
                            streamingText: chatState.streamingText,
                            thinkingText: chatState.thinkingText,
                            activeTools: chatState.activeTools,
                            completedTools: chatState.completedTools,
                          );
                        } else {
                          itemChild = Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  l10n.aiFollowUpsLabel,
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    for (final f
                                        in chatState.suggestedFollowUps)
                                      ActionChip(
                                        label: Text(f),
                                        onPressed: isReadOnly
                                            ? null
                                            : () => _handleSend(f),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }

                        return RepaintBoundary(
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 768),
                              child: SizedBox(
                                width: double.infinity,
                                child: itemChild,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  if (_showJumpToBottom &&
                      chatState.messages.isNotEmpty &&
                      !chatState.loadingConversation)
                    PositionedDirectional(
                      end: 16,
                      bottom: 12,
                      child: FloatingActionButton.small(
                        heroTag: 'ai_jump_latest',
                        tooltip: l10n.aiScrollToBottom,
                        onPressed: () => _scrollToBottom(),
                        child: const Icon(LucideIcons.arrowDown, size: 18),
                      ),
                    ),
                ],
              ),
            ),

            if (chatState.sending)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _FloatingGlassPill(
                  colors: colors,
                  child: InkWell(
                    onTap: () => ref
                        .read(aiStudioControllerProvider.notifier)
                        .stopStreaming(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.square,
                            size: 12,
                            color: colors.textMuted,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            l10n.aiStop,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Single-Row Floating Pill Composer
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 768),
                child: CopilotComposer(
                  controller: _inputCtrl,
                  focusNode: _focusNode,
                  stagedAttachments: chatState.stagedAttachments,
                  reasoningMode: chatState.reasoningMode,
                  sending: chatState.sending,
                  uploadingAttachment: chatState.uploadingAttachment,
                  isReadOnly: isReadOnly,
                  onReasoningModeChanged: (m) => ref
                      .read(aiStudioControllerProvider.notifier)
                      .setReasoningMode(m),
                  onSend: _handleSend,
                  onStop: () => ref
                      .read(aiStudioControllerProvider.notifier)
                      .stopStreaming(),
                  onStageAttachment: ({
                    required bytes,
                    required filename,
                    contentType,
                  }) =>
                      ref
                          .read(aiStudioControllerProvider.notifier)
                          .stageAttachment(
                            bytes: bytes,
                            filename: filename,
                            contentType: contentType,
                          ),
                  onRemoveAttachment: (id) => ref
                      .read(aiStudioControllerProvider.notifier)
                      .removeStagedAttachment(id),
                ),
              ),
            ),
                ],
              ),
            ),
          ],
        );

        return Scaffold(
          key: _scaffoldKey,
          resizeToAvoidBottomInset: !hasParentScaffold,
          drawer: isExpandedSidebar
              ? null
              : Drawer(
                  width: (width * 0.82).clamp(240.0, 304.0),
                  child: SafeArea(child: drawerPanel),
                ),
          body: Row(
            children: [
              if (isExpandedSidebar && _sidebarOpen)
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: BorderDirectional(
                      end: BorderSide(color: colors.border),
                    ),
                  ),
                  child: drawerPanel,
                ),
              Expanded(child: studioMain),
              if (canDockMemory && _memoryPaneOpen)
                Container(
                  width: 390,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: BorderDirectional(
                      start: BorderSide(color: colors.border),
                    ),
                  ),
                  child: BusinessMemoryBody(
                    isSidePane: true,
                    onClosePane: () =>
                        setState(() => _memoryPaneOpen = false),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CopilotAuroraLayer extends ConsumerWidget {
  const _CopilotAuroraLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      aiStudioControllerProvider.select(
        (s) => (sending: s.sending, hasMessages: s.messages.isNotEmpty),
      ),
    );
    return CopilotAuroraBackdrop(
      sending: state.sending,
      activeMode: state.hasMessages || state.sending,
    );
  }
}

class _FloatingGlassPill extends StatelessWidget {
  const _FloatingGlassPill({
    required this.colors,
    required this.child,
  });

  final AfabColors colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.isDark
          ? Colors.black.withValues(alpha: 0.62)
          : Colors.white.withValues(alpha: 0.88),
      shape: StadiumBorder(
        side: BorderSide(
          color: colors.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : colors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _CopilotLiveStatusDot extends ConsumerWidget {
  const _CopilotLiveStatusDot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final state = ref.watch(aiHealthProvider);
    final h = state.health;

    final Color dotColor;
    if (!state.backendConnected) {
      dotColor = colors.danger;
    } else if (h == null) {
      dotColor = colors.textMuted;
    } else if (!h.ollamaReachable || !h.chatModelReady) {
      dotColor = colors.warning;
    } else if (h.busy) {
      dotColor = colors.primary;
    } else {
      dotColor = colors.success;
    }

    return Tooltip(
      message: l10n.aiLiveTitle,
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () => showAiModelHealthSheet(context),
        child: Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
          ),
        ),
      ),
    );
  }
}

class _CopilotOfflineBanner extends ConsumerWidget {
  const _CopilotOfflineBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final h = ref.watch(aiHealthProvider).health;
    final showOfflineBanner =
        h != null && (!h.ollamaReachable || !h.chatModelReady);
    if (!showOfflineBanner) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: colors.warningBg,
      child: Wrap(
        spacing: 10,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(
            LucideIcons.triangleAlert,
            size: 16,
            color: colors.warning,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Text(
              '${l10n.aiOfflineTitle}: ${l10n.aiOfflineDescription}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.warning,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                'ollama pull ${h.chatModel} && ollama pull ${h.embedModel}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

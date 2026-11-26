import 'dart:async';
import 'dart:typed_data';

import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/features/ai/data/ai_dtos.dart';
import 'package:afab_mobile/features/ai/data/ai_repository.dart';
import 'package:afab_mobile/features/ai/data/sse_parser.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/budgets/domain/budgets_providers.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/calendar/domain/calendar_providers.dart';
import 'package:afab_mobile/features/customers/data/customer_dtos.dart';
import 'package:afab_mobile/features/customers/data/customers_repository.dart';
import 'package:afab_mobile/features/customers/domain/customers_providers.dart';
import 'package:afab_mobile/features/dashboard/domain/dashboard_providers.dart';
import 'package:afab_mobile/features/expenses/domain/expense_providers.dart';
import 'package:afab_mobile/features/invoices/domain/invoices_providers.dart';
import 'package:afab_mobile/features/reports/domain/reports_providers.dart';
import 'package:afab_mobile/features/revenue/domain/revenue_providers.dart';
import 'package:afab_mobile/features/transactions/domain/transaction_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Health & Status Providers
// ---------------------------------------------------------------------------

@immutable
class AiHealthState {
  const AiHealthState({
    this.health,
    this.backendConnected = true,
    this.checking = false,
    this.lastChecked,
  });

  final AiHealthDto? health;
  final bool backendConnected;
  final bool checking;
  final DateTime? lastChecked;

  AiHealthState copyWith({
    AiHealthDto? health,
    bool? backendConnected,
    bool? checking,
    DateTime? lastChecked,
  }) {
    return AiHealthState(
      health: health ?? this.health,
      backendConnected: backendConnected ?? this.backendConnected,
      checking: checking ?? this.checking,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }
}

class AiHealthNotifier extends Notifier<AiHealthState> {
  Timer? _pollTimer;
  bool _inFlight = false;
  bool _disposed = false;

  @override
  AiHealthState build() {
    _disposed = false;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => checkNow(fresh: false),
    );
    Future.microtask(() => checkNow(fresh: true));
    ref.onDispose(() {
      _disposed = true;
      _pollTimer?.cancel();
      _pollTimer = null;
    });
    return const AiHealthState();
  }

  Future<void> checkNow({bool fresh = true}) async {
    if (_disposed || _inFlight) return;
    _inFlight = true;
    if (fresh) {
      state = state.copyWith(checking: true);
    }
    try {
      final res = await ref.read(aiRepositoryProvider).getHealth(fresh: fresh);
      if (_disposed) return;
      state = state.copyWith(
        health: res,
        backendConnected: true,
        checking: false,
        lastChecked: DateTime.now(),
      );
    } catch (_) {
      if (_disposed) return;
      state = state.copyWith(
        backendConnected: false,
        checking: false,
        lastChecked: DateTime.now(),
      );
    } finally {
      _inFlight = false;
    }
  }
}

final aiHealthProvider =
    NotifierProvider<AiHealthNotifier, AiHealthState>(AiHealthNotifier.new);

class AiStatusNotifier extends AsyncNotifier<AiStatusDto> {
  @override
  Future<AiStatusDto> build() async {
    final session = ref.watch(authNotifierProvider);
    if (!session.isAuthenticated ||
        session.needsEmailVerification ||
        session.needsOnboarding) {
      throw StateError('Unauthenticated');
    }
    ref.watch(activeBusinessIdProvider);
    return ref.read(aiRepositoryProvider).getStatus(fresh: false);
  }

  Future<void> refresh({bool fresh = false}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(aiRepositoryProvider).getStatus(fresh: fresh),
    );
  }

  Future<AiIndexSyncResponseDto> syncIndex() async {
    final res = await ref.read(aiRepositoryProvider).syncIndex();
    await refresh(fresh: false);
    return res;
  }
}

final aiStatusProvider =
    AsyncNotifierProvider<AiStatusNotifier, AiStatusDto>(AiStatusNotifier.new);

// ---------------------------------------------------------------------------
// Conversations Provider
// ---------------------------------------------------------------------------

class AiConversationSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String q) => state = q;
}

final aiConversationSearchQueryProvider =
    NotifierProvider<AiConversationSearchNotifier, String>(
  AiConversationSearchNotifier.new,
);

class AiConversationsNotifier
    extends AsyncNotifier<List<AiConversationSummaryDto>> {
  @override
  Future<List<AiConversationSummaryDto>> build() async {
    final session = ref.watch(authNotifierProvider);
    if (!session.isAuthenticated ||
        session.needsEmailVerification ||
        session.needsOnboarding) {
      return const [];
    }
    ref.watch(activeBusinessIdProvider);
    return ref.read(aiRepositoryProvider).listConversations();
  }

  Future<void> deleteConversation(String id) async {
    await ref.read(aiRepositoryProvider).deleteConversation(id);
    final current = state.value ?? const <AiConversationSummaryDto>[];
    state = AsyncValue.data(current.where((c) => c.id != id).toList());
  }
}

final aiConversationsProvider = AsyncNotifierProvider<AiConversationsNotifier,
    List<AiConversationSummaryDto>>(
  AiConversationsNotifier.new,
);

// ---------------------------------------------------------------------------
// Business Memory Providers
// ---------------------------------------------------------------------------

class AiMemoryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';

  void setStatus(String status) => state = status;
}

final aiMemoryFilterProvider =
    NotifierProvider<AiMemoryFilterNotifier, String>(
  AiMemoryFilterNotifier.new,
);

class AiMemoryNotifier extends AsyncNotifier<List<BusinessMemoryDto>> {
  AiMemoryNotifier(this.statusFilter);
  final String statusFilter;

  @override
  Future<List<BusinessMemoryDto>> build() async {
    final session = ref.watch(authNotifierProvider);
    if (!session.isAuthenticated ||
        session.needsEmailVerification ||
        session.needsOnboarding) {
      return const [];
    }
    ref.watch(activeBusinessIdProvider);
    return ref.read(aiRepositoryProvider).listMemory(status: statusFilter);
  }

  Future<void> createMemory({
    required BusinessMemoryType memoryType,
    required String title,
    required String content,
  }) async {
    await ref.read(aiRepositoryProvider).createMemory(
          memoryType: memoryType,
          title: title,
          content: content,
        );
    _invalidateAllBuckets();
  }

  Future<void> updateMemory({
    required String id,
    BusinessMemoryType? memoryType,
    String? title,
    String? content,
    String? status,
  }) async {
    await ref.read(aiRepositoryProvider).updateMemory(
          id: id,
          memoryType: memoryType,
          title: title,
          content: content,
          status: status,
        );
    _invalidateAllBuckets();
  }

  Future<void> approveMemory(String id) async {
    await ref
        .read(aiRepositoryProvider)
        .updateMemory(id: id, status: 'APPROVED');
    _invalidateAllBuckets();
  }

  Future<void> deleteMemory(String id) async {
    await ref.read(aiRepositoryProvider).deleteMemory(id);
    _invalidateAllBuckets();
  }

  void _invalidateAllBuckets() {
    ref.invalidate(aiMemoryProvider);
    ref.invalidate(aiStatusProvider);
  }
}

final aiMemoryProvider = AsyncNotifierProvider.family<AiMemoryNotifier,
    List<BusinessMemoryDto>, String>(
  AiMemoryNotifier.new,
);

/// Dropdown helper for CREATE_INVOICE action draft cards.
final aiCustomersDropdownProvider =
    FutureProvider<List<CustomerDto>>((ref) async {
  ref.watch(activeBusinessIdProvider);
  try {
    final page = await ref
        .read(customersRepositoryProvider)
        .listCustomers(page: 0, size: 100);
    return page.content;
  } catch (_) {
    return const [];
  }
});

// ---------------------------------------------------------------------------
// Global Copilot Launcher Provider (`AI-02`)
// ---------------------------------------------------------------------------

@immutable
class CopilotLaunchRequest {
  const CopilotLaunchRequest({
    required this.nonce,
    this.prompt,
    this.autoSend = false,
    this.screenContext = const {},
    this.reasoningMode,
  });

  final int nonce;
  final String? prompt;
  final bool autoSend;
  final Map<String, String> screenContext;
  final AiReasoningMode? reasoningMode;
}

@immutable
class CopilotLauncherState {
  const CopilotLauncherState({
    this.isOpen = false,
    this.pendingRequest,
  });

  final bool isOpen;
  final CopilotLaunchRequest? pendingRequest;
}

class CopilotLauncherNotifier extends Notifier<CopilotLauncherState> {
  int _nonceCounter = 0;

  @override
  CopilotLauncherState build() {
    ref.watch(authNotifierProvider);
    ref.watch(activeBusinessIdProvider);
    return const CopilotLauncherState();
  }

  void openCopilot({
    String? prompt,
    bool autoSend = false,
    Map<String, String> screenContext = const {},
    AiReasoningMode? reasoningMode,
  }) {
    _nonceCounter++;
    state = CopilotLauncherState(
      isOpen: true,
      pendingRequest: CopilotLaunchRequest(
        nonce: _nonceCounter,
        prompt: prompt,
        autoSend: autoSend,
        screenContext: screenContext,
        reasoningMode: reasoningMode,
      ),
    );
  }

  void closeCopilot() {
    state = CopilotLauncherState(
      isOpen: false,
      pendingRequest: state.pendingRequest,
    );
  }

  void clearPendingRequest() {
    if (state.pendingRequest == null) return;
    state = CopilotLauncherState(isOpen: state.isOpen, pendingRequest: null);
  }
}

final copilotLauncherProvider =
    NotifierProvider<CopilotLauncherNotifier, CopilotLauncherState>(
  CopilotLauncherNotifier.new,
);

// ---------------------------------------------------------------------------
// Active Chat Controller (Shared logic for `AI-01` Studio & `AI-02` Sheet)
// ---------------------------------------------------------------------------

@immutable
class AiChatState {
  const AiChatState({
    this.activeConversationId,
    this.activeConversationTitle,
    this.activeLanguage,
    this.messages = const [],
    this.loadingConversation = false,
    this.sending = false,
    this.uploadingAttachment = false,
    this.reasoningMode = AiReasoningMode.fast,
    this.stagedAttachments = const [],
    this.streamPhase = '',
    this.streamingText = '',
    this.thinkingText = '',
    this.activeTools = const [],
    this.completedTools = const [],
    this.suggestedFollowUps = const [],
    this.quotaExhaustedMsg,
    this.chatError,
    this.restoredDraftInput,
    this.pendingScreenContext = const {},
  });

  final String? activeConversationId;
  final String? activeConversationTitle;
  final String? activeLanguage;
  final List<AiMessageDto> messages;
  final bool loadingConversation;
  final bool sending;
  final bool uploadingAttachment;
  final AiReasoningMode reasoningMode;
  final List<AiAttachmentDto> stagedAttachments;
  final String streamPhase;
  final String streamingText;
  final String thinkingText;
  final List<String> activeTools;
  final List<({String tool, int evidenceCount})> completedTools;
  final List<String> suggestedFollowUps;
  final String? quotaExhaustedMsg;
  final String? chatError;
  final String? restoredDraftInput;
  final Map<String, String> pendingScreenContext;

  AiChatState copyWith({
    String? activeConversationId,
    bool clearConversationId = false,
    String? activeConversationTitle,
    bool clearConversationTitle = false,
    String? activeLanguage,
    bool clearActiveLanguage = false,
    List<AiMessageDto>? messages,
    bool? loadingConversation,
    bool? sending,
    bool? uploadingAttachment,
    AiReasoningMode? reasoningMode,
    List<AiAttachmentDto>? stagedAttachments,
    String? streamPhase,
    String? streamingText,
    String? thinkingText,
    List<String>? activeTools,
    List<({String tool, int evidenceCount})>? completedTools,
    List<String>? suggestedFollowUps,
    String? quotaExhaustedMsg,
    bool clearQuotaExhausted = false,
    String? chatError,
    bool clearChatError = false,
    String? restoredDraftInput,
    bool clearRestoredDraftInput = false,
    Map<String, String>? pendingScreenContext,
  }) {
    return AiChatState(
      activeConversationId: clearConversationId
          ? null
          : (activeConversationId ?? this.activeConversationId),
      activeConversationTitle: clearConversationTitle
          ? null
          : (activeConversationTitle ?? this.activeConversationTitle),
      activeLanguage: clearActiveLanguage
          ? null
          : (activeLanguage ?? this.activeLanguage),
      messages: messages ?? this.messages,
      loadingConversation: loadingConversation ?? this.loadingConversation,
      sending: sending ?? this.sending,
      uploadingAttachment: uploadingAttachment ?? this.uploadingAttachment,
      reasoningMode: reasoningMode ?? this.reasoningMode,
      stagedAttachments: stagedAttachments ?? this.stagedAttachments,
      streamPhase: streamPhase ?? this.streamPhase,
      streamingText: streamingText ?? this.streamingText,
      thinkingText: thinkingText ?? this.thinkingText,
      activeTools: activeTools ?? this.activeTools,
      completedTools: completedTools ?? this.completedTools,
      suggestedFollowUps: suggestedFollowUps ?? this.suggestedFollowUps,
      quotaExhaustedMsg: clearQuotaExhausted
          ? null
          : (quotaExhaustedMsg ?? this.quotaExhaustedMsg),
      chatError: clearChatError ? null : (chatError ?? this.chatError),
      restoredDraftInput: clearRestoredDraftInput
          ? null
          : (restoredDraftInput ?? this.restoredDraftInput),
      pendingScreenContext: pendingScreenContext ?? this.pendingScreenContext,
    );
  }
}

class AiChatController extends Notifier<AiChatState> {
  CancelToken? _cancelToken;
  Timer? _flushTimer;
  String _pendingDelta = '';
  String _pendingThought = '';
  bool _disposed = false;

  @override
  AiChatState build() {
    _disposed = false;
    ref.watch(authNotifierProvider);
    ref.watch(activeBusinessIdProvider);
    ref.onDispose(() {
      _disposed = true;
      _flushTimer?.cancel();
      _flushTimer = null;
      _cancelToken?.cancel();
      _cancelToken = null;
    });
    return const AiChatState();
  }

  void setReasoningMode(AiReasoningMode mode) {
    state = state.copyWith(reasoningMode: mode);
  }

  void setPendingScreenContext(Map<String, String> ctx) {
    state = state.copyWith(pendingScreenContext: ctx);
  }

  void clearError() {
    state = state.copyWith(clearChatError: true);
  }

  void clearRestoredInput() {
    state = state.copyWith(clearRestoredDraftInput: true);
  }

  void startNewConversation() {
    stopStreaming();
    state = AiChatState(reasoningMode: state.reasoningMode);
  }

  Future<void> loadConversation(String id) async {
    if (id.isEmpty) return;
    stopStreaming();
    state = state.copyWith(
      loadingConversation: true,
      clearChatError: true,
      clearQuotaExhausted: true,
      suggestedFollowUps: const [],
    );
    try {
      final detail = await ref.read(aiRepositoryProvider).getConversation(id);
      if (_disposed) return;
      state = state.copyWith(
        activeConversationId: detail.id,
        activeConversationTitle: detail.title,
        activeLanguage: detail.activeLanguage,
        messages: detail.messages,
        loadingConversation: false,
      );
    } on AppFailure catch (e) {
      if (_disposed) return;
      state = state.copyWith(loadingConversation: false, chatError: e.message);
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(
        loadingConversation: false,
        chatError: e.toString(),
      );
    }
  }

  Future<bool> stageAttachment({
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) async {
    state = state.copyWith(uploadingAttachment: true, clearChatError: true);
    try {
      final staged = await ref.read(aiRepositoryProvider).stageAttachment(
            bytes: bytes,
            filename: filename,
            contentType: contentType,
          );
      if (_disposed) return false;
      state = state.copyWith(
        uploadingAttachment: false,
        stagedAttachments: [...state.stagedAttachments, staged],
      );
      return true;
    } on AppFailure catch (e) {
      if (_disposed) return false;
      state = state.copyWith(
        uploadingAttachment: false,
        chatError: e.message,
      );
      return false;
    } catch (e) {
      if (_disposed) return false;
      state = state.copyWith(
        uploadingAttachment: false,
        chatError: e.toString(),
      );
      return false;
    }
  }

  void removeStagedAttachment(String id) {
    state = state.copyWith(
      stagedAttachments:
          state.stagedAttachments.where((a) => a.id != id).toList(),
    );
  }

  void stopStreaming() {
    _flushTimer?.cancel();
    _flushTimer = null;
    _pendingDelta = '';
    _pendingThought = '';
    _cancelToken?.cancel('User cancelled');
    _cancelToken = null;
    if (state.sending) {
      state = state.copyWith(
        sending: false,
        streamPhase: '',
        streamingText: '',
        thinkingText: '',
        activeTools: const [],
        completedTools: const [],
      );
    }
  }

  Future<void> sendMessage({
    required String rawPrompt,
    required String uiLocale,
    AiReasoningMode? modeOverride,
    Map<String, String>? screenContextOverride,
  }) async {
    if (state.sending) return;
    final trimmed = rawPrompt.trim();
    final attachments = List<AiAttachmentDto>.from(state.stagedAttachments);
    if (trimmed.isEmpty && attachments.isEmpty) return;

    final effectiveMode = modeOverride ?? state.reasoningMode;
    final contextToSend = screenContextOverride ?? state.pendingScreenContext;

    final optimisticId = 'user-${DateTime.now().microsecondsSinceEpoch}';
    final displayContent = trimmed.isNotEmpty
        ? trimmed
        : (attachments.isNotEmpty ? attachments.first.originalFilename : '');

    final optimisticMsg = AiMessageDto(
      id: optimisticId,
      role: 'user',
      content: displayContent,
      attachments: attachments,
      createdAt: DateTime.now(),
    );

    final token = CancelToken();
    _cancelToken = token;
    _pendingDelta = '';
    _pendingThought = '';

    state = state.copyWith(
      messages: [...state.messages, optimisticMsg],
      stagedAttachments: const [],
      sending: true,
      reasoningMode: effectiveMode,
      streamPhase: '',
      streamingText: '',
      thinkingText: '',
      activeTools: const [],
      completedTools: const [],
      suggestedFollowUps: const [],
      pendingScreenContext: const {},
      clearChatError: true,
      clearQuotaExhausted: true,
      clearRestoredDraftInput: true,
    );

    try {
      final stream = ref.read(aiRepositoryProvider).streamChat(
            message: trimmed,
            conversationId: state.activeConversationId,
            locale: uiLocale,
            reasoningMode: effectiveMode,
            attachmentIds: attachments.map((e) => e.id).toList(),
            screenContext: contextToSend.isEmpty ? null : contextToSend,
            cancelToken: token,
          );

      await for (final ev in stream) {
        if (_disposed || token.isCancelled) break;
        switch (ev) {
          case SsePingEvent():
            break;
          case SseStatusEvent():
            state = state.copyWith(
              streamPhase: ev.phase,
              activeConversationId: ev.conversationId ?? state.activeConversationId,
              activeLanguage: ev.activeLanguage ?? state.activeLanguage,
            );
          case SseThoughtEvent():
            _pendingThought += ev.text;
            _scheduleFlush();
          case SseDeltaEvent():
            _pendingDelta += ev.text;
            _scheduleFlush();
          case SseReplaceEvent():
            _pendingDelta = '';
            _flushTimer?.cancel();
            state = state.copyWith(streamingText: ev.text);
          case SseToolStartEvent():
            if (!state.activeTools.contains(ev.tool)) {
              state = state.copyWith(
                activeTools: [...state.activeTools, ev.tool],
              );
            }
          case SseToolDoneEvent():
            state = state.copyWith(
              activeTools:
                  state.activeTools.where((t) => t != ev.tool).toList(),
              completedTools: [
                ...state.completedTools,
                (tool: ev.tool, evidenceCount: ev.evidenceCount),
              ],
            );
          case SseDoneEvent():
            _flushBufferedChunksNow();
            final res = ev.response;
            final assistantMsg = res.toAssistantMessage();
            final updatedMessages = [
              ...state.messages,
              assistantMsg,
            ];
            state = state.copyWith(
              activeConversationId: res.conversationId,
              activeConversationTitle: res.conversationTitle,
              activeLanguage: res.responseLanguage ?? state.activeLanguage,
              messages: updatedMessages,
              sending: false,
              streamPhase: '',
              streamingText: '',
              thinkingText: '',
              activeTools: const [],
              completedTools: const [],
              suggestedFollowUps: res.suggestedFollowUps,
            );
            ref.invalidate(aiStatusProvider);
            ref.invalidate(aiConversationsProvider);
          case SseErrorEvent():
            break;
        }
      }
    } on AiStreamCancelledException {
      // Cancelled intentionally by user or dispose; already cleaned up.
    } on PlanLimitReachedFailure catch (e) {
      if (_disposed) return;
      _rollbackFailedSend(
        optimisticId: optimisticId,
        rawPrompt: rawPrompt,
        attachments: attachments,
        quotaMessage: e.message,
        revertDeep: effectiveMode == AiReasoningMode.deep,
      );
    } on AppFailure catch (e) {
      if (_disposed) return;
      _rollbackFailedSend(
        optimisticId: optimisticId,
        rawPrompt: rawPrompt,
        attachments: attachments,
        errorMessage: e.message,
      );
    } catch (e) {
      if (_disposed) return;
      _rollbackFailedSend(
        optimisticId: optimisticId,
        rawPrompt: rawPrompt,
        attachments: attachments,
        errorMessage: e.toString(),
      );
    } finally {
      _flushTimer?.cancel();
      _flushTimer = null;
      if (identical(_cancelToken, token)) {
        _cancelToken = null;
      }
    }
  }

  void _scheduleFlush() {
    if (_flushTimer?.isActive ?? false) return;
    _flushTimer = Timer(const Duration(milliseconds: 50), () {
      _flushBufferedChunksNow();
    });
  }

  void _flushBufferedChunksNow() {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_disposed) return;
    if (_pendingDelta.isEmpty && _pendingThought.isEmpty) return;
    final nextDelta = _pendingDelta;
    final nextThought = _pendingThought;
    _pendingDelta = '';
    _pendingThought = '';
    state = state.copyWith(
      streamingText: '${state.streamingText}$nextDelta',
      thinkingText: '${state.thinkingText}$nextThought',
    );
  }

  void _rollbackFailedSend({
    required String optimisticId,
    required String rawPrompt,
    required List<AiAttachmentDto> attachments,
    String? errorMessage,
    String? quotaMessage,
    bool revertDeep = false,
  }) {
    _flushTimer?.cancel();
    _pendingDelta = '';
    _pendingThought = '';
    state = state.copyWith(
      messages: state.messages.where((m) => m.id != optimisticId).toList(),
      stagedAttachments: attachments,
      sending: false,
      streamPhase: '',
      streamingText: '',
      thinkingText: '',
      activeTools: const [],
      completedTools: const [],
      restoredDraftInput: rawPrompt,
      reasoningMode: revertDeep ? AiReasoningMode.fast : state.reasoningMode,
      quotaExhaustedMsg: quotaMessage,
      chatError: errorMessage,
    );
  }

  Future<void> regenerateLastResponse({required String uiLocale}) async {
    if (state.sending || state.messages.isEmpty) return;
    String? lastUserPrompt;
    for (var i = state.messages.length - 1; i >= 0; i--) {
      if (state.messages[i].isUser) {
        lastUserPrompt = state.messages[i].content;
        break;
      }
    }
    if (lastUserPrompt == null || lastUserPrompt.trim().isEmpty) return;
    await sendMessage(rawPrompt: lastUserPrompt, uiLocale: uiLocale);
  }

  void updateDraftInMessage(String messageId, AiActionDraftDto updatedDraft) {
    final nextMessages = state.messages.map((msg) {
      if (msg.id != messageId) return msg;
      final nextDrafts = msg.actionDrafts
          .map((d) => d.draftId == updatedDraft.draftId ? updatedDraft : d)
          .toList();
      return msg.copyWith(actionDrafts: nextDrafts);
    }).toList();
    state = state.copyWith(messages: nextMessages);

    if (updatedDraft.status == 'APPROVED') {
      invalidateAfterDraftApproval(updatedDraft.actionType);
    }
  }

  void invalidateAfterDraftApproval(String actionType) {
    switch (actionType.toUpperCase()) {
      case 'CREATE_TRANSACTION':
        ref.invalidate(dashboardSummaryProvider);
        ref.invalidate(transactionListProvider);
        ref.invalidate(expenseSummaryProvider);
        ref.invalidate(expenseListProvider);
        ref.invalidate(revenueSummaryProvider);
        ref.invalidate(revenueListProvider);
        ref.invalidate(budgetListProvider);
        ref.invalidate(budgetOverviewSummaryProvider);
        ref.invalidate(calendarMonthTransactionsProvider);
        ref.invalidate(pnlReportProvider);
        ref.invalidate(cashFlowReportProvider);
        ref.invalidate(comparisonReportProvider);
        ref.invalidate(aiPulseProvider);
      case 'CREATE_INVOICE':
        ref.invalidate(dashboardSummaryProvider);
        ref.invalidate(invoicesListProvider);
        ref.invalidate(invoiceSummaryProvider);
        ref.invalidate(customersListProvider);
        ref.invalidate(customerSummaryProvider);
        ref.invalidate(calendarDueInvoicesProvider);
        ref.invalidate(aiPulseProvider);
      case 'CREATE_BUDGET':
        ref.invalidate(dashboardSummaryProvider);
        ref.invalidate(budgetListProvider);
        ref.invalidate(budgetOverviewSummaryProvider);
        ref.invalidate(aiPulseProvider);
      case 'SAVE_MEMORY':
        ref.invalidate(aiMemoryProvider);
        ref.invalidate(aiStatusProvider);
    }
  }
}

final aiStudioControllerProvider =
    NotifierProvider<AiChatController, AiChatState>(AiChatController.new);

final globalCopilotSheetControllerProvider =
    NotifierProvider<AiChatController, AiChatState>(AiChatController.new);

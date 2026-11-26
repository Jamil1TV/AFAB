import 'package:afab_mobile/core/money/money_formatter.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

enum AiReasoningMode {
  fast('fast'),
  deep('deep');

  const AiReasoningMode(this.apiValue);
  final String apiValue;

  static AiReasoningMode fromApi(String? raw) {
    return raw?.toLowerCase() == 'deep' ? deep : fast;
  }
}

enum BusinessMemoryType {
  businessProfile('BUSINESS_PROFILE'),
  transactionContext('TRANSACTION_CONTEXT'),
  supplierPattern('SUPPLIER_PATTERN'),
  categorizationPreference('CATEGORIZATION_PREFERENCE'),
  decisionHistory('DECISION_HISTORY'),
  operationalConstraint('OPERATIONAL_CONSTRAINT');

  const BusinessMemoryType(this.apiValue);
  final String apiValue;

  static BusinessMemoryType fromApi(String? raw) {
    final upper = (raw ?? '').toUpperCase();
    for (final v in values) {
      if (v.apiValue == upper) return v;
    }
    return transactionContext;
  }
}

@immutable
class AiHealthDto {
  const AiHealthDto({
    required this.enabled,
    required this.ollamaReachable,
    required this.chatModel,
    required this.chatModelReady,
    required this.chatModelLoaded,
    required this.embedModel,
    required this.embedModelReady,
    required this.busy,
    required this.latencyMs,
    this.checkedAt,
  });

  final bool enabled;
  final bool ollamaReachable;
  final String chatModel;
  final bool chatModelReady;
  final bool chatModelLoaded;
  final String embedModel;
  final bool embedModelReady;
  final bool busy;
  final int latencyMs;
  final DateTime? checkedAt;

  bool get isFullyReady => enabled && ollamaReachable && chatModelReady;

  factory AiHealthDto.fromJson(Map<String, dynamic> json) {
    return AiHealthDto(
      enabled: json['enabled'] as bool? ?? true,
      ollamaReachable: json['ollamaReachable'] as bool? ?? false,
      chatModel: (json['chatModel'] ?? 'gemma4:e4b').toString(),
      chatModelReady: json['chatModelReady'] as bool? ?? false,
      chatModelLoaded: json['chatModelLoaded'] as bool? ?? false,
      embedModel: (json['embedModel'] ?? 'embeddinggemma-2:270m').toString(),
      embedModelReady: json['embedModelReady'] as bool? ?? false,
      busy: json['busy'] as bool? ?? false,
      latencyMs: (json['latencyMs'] as num?)?.toInt() ?? 0,
      checkedAt: DateTime.tryParse((json['checkedAt'] ?? '').toString()),
    );
  }
}

@immutable
class AiTokenUsageDto {
  const AiTokenUsageDto({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    required this.monthlyTokensUsed,
    required this.monthlyTokensLimit,
    required this.monthlyTokensRemaining,
    required this.monthlyQueriesUsed,
    required this.monthlyQueriesLimit,
    required this.monthlyQueriesRemaining,
    required this.planSlug,
    required this.planName,
  });

  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final int monthlyTokensUsed;
  final int monthlyTokensLimit;
  final int monthlyTokensRemaining;
  final int monthlyQueriesUsed;
  final int monthlyQueriesLimit;
  final int monthlyQueriesRemaining;
  final String planSlug;
  final String planName;

  bool get isTokensUnlimited => monthlyTokensLimit < 0;
  bool get isQueriesUnlimited => monthlyQueriesLimit < 0;

  double get tokenPercent {
    if (monthlyTokensLimit <= 0) return 0;
    return ((monthlyTokensUsed / monthlyTokensLimit) * 100).clamp(0, 100);
  }

  factory AiTokenUsageDto.fromJson(Map<String, dynamic> json) {
    return AiTokenUsageDto(
      promptTokens: (json['promptTokens'] as num?)?.toInt() ?? 0,
      completionTokens: (json['completionTokens'] as num?)?.toInt() ?? 0,
      totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
      monthlyTokensUsed: (json['monthlyTokensUsed'] as num?)?.toInt() ?? 0,
      monthlyTokensLimit: (json['monthlyTokensLimit'] as num?)?.toInt() ?? 0,
      monthlyTokensRemaining:
          (json['monthlyTokensRemaining'] as num?)?.toInt() ?? 0,
      monthlyQueriesUsed: (json['monthlyQueriesUsed'] as num?)?.toInt() ?? 0,
      monthlyQueriesLimit: (json['monthlyQueriesLimit'] as num?)?.toInt() ?? 0,
      monthlyQueriesRemaining:
          (json['monthlyQueriesRemaining'] as num?)?.toInt() ?? 0,
      planSlug: (json['planSlug'] ?? 'free').toString().toLowerCase(),
      planName: (json['planName'] ?? 'Free').toString(),
    );
  }
}

@immutable
class AiStatusDto {
  const AiStatusDto({
    required this.health,
    required this.indexedChunks,
    required this.approvedMemories,
    required this.quota,
  });

  final AiHealthDto health;
  final int indexedChunks;
  final int approvedMemories;
  final AiTokenUsageDto quota;

  factory AiStatusDto.fromJson(Map<String, dynamic> json) {
    final rawQuota = json['quota'];
    return AiStatusDto(
      health: AiHealthDto.fromJson(json),
      indexedChunks: (json['indexedChunks'] as num?)?.toInt() ?? 0,
      approvedMemories: (json['approvedMemories'] as num?)?.toInt() ?? 0,
      quota: AiTokenUsageDto.fromJson(
        rawQuota is Map ? Map<String, dynamic>.from(rawQuota) : const {},
      ),
    );
  }
}

@immutable
class AiIndexSyncResponseDto {
  const AiIndexSyncResponseDto({
    required this.indexedCount,
    required this.skippedUnchanged,
    required this.embeddingsGenerated,
    required this.embeddingAvailable,
    required this.message,
  });

  final int indexedCount;
  final int skippedUnchanged;
  final int embeddingsGenerated;
  final bool embeddingAvailable;
  final String message;

  factory AiIndexSyncResponseDto.fromJson(Map<String, dynamic> json) {
    return AiIndexSyncResponseDto(
      indexedCount: (json['indexedCount'] as num?)?.toInt() ?? 0,
      skippedUnchanged: (json['skippedUnchanged'] as num?)?.toInt() ?? 0,
      embeddingsGenerated: (json['embeddingsGenerated'] as num?)?.toInt() ?? 0,
      embeddingAvailable: json['embeddingAvailable'] as bool? ?? false,
      message: (json['message'] ?? '').toString(),
    );
  }
}

@immutable
class AiEvidenceItemDto {
  const AiEvidenceItemDto({
    required this.type,
    required this.id,
    required this.title,
    this.subtitle,
    this.amount,
    this.currency,
    this.date,
    this.href,
  });

  final String type;
  final String id;
  final String title;
  final String? subtitle;
  final Decimal? amount;
  final String? currency;
  final String? date;
  final String? href;

  factory AiEvidenceItemDto.fromJson(Map<String, dynamic> json) {
    return AiEvidenceItemDto(
      type: (json['type'] ?? 'SUMMARY').toString(),
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      subtitle: json['subtitle']?.toString(),
      amount: json['amount'] != null
          ? MoneyFormatter.parseDecimal(json['amount'])
          : null,
      currency: json['currency']?.toString(),
      date: json['date']?.toString(),
      href: json['href']?.toString(),
    );
  }
}

@immutable
class AiChartSeriesSpecDto {
  const AiChartSeriesSpecDto({
    required this.key,
    required this.label,
    required this.colorToken,
  });

  final String key;
  final String label;
  final String colorToken;

  factory AiChartSeriesSpecDto.fromJson(Map<String, dynamic> json) {
    return AiChartSeriesSpecDto(
      key: (json['key'] ?? 'value').toString(),
      label: (json['label'] ?? '').toString(),
      colorToken: (json['colorToken'] ?? 'primary').toString(),
    );
  }
}

@immutable
class AiChartSpecDto {
  const AiChartSpecDto({
    required this.id,
    required this.chartType,
    required this.title,
    this.subtitle,
    this.currency,
    required this.xKey,
    required this.series,
    required this.data,
  });

  final String id;
  final String chartType;
  final String title;
  final String? subtitle;
  final String? currency;
  final String xKey;
  final List<AiChartSeriesSpecDto> series;
  final List<Map<String, dynamic>> data;

  factory AiChartSpecDto.fromJson(Map<String, dynamic> json) {
    final rawSeries = json['series'] as List<dynamic>? ?? const [];
    final rawData = json['data'] as List<dynamic>? ?? const [];
    return AiChartSpecDto(
      id: (json['id'] ?? '').toString(),
      chartType: (json['chartType'] ?? 'bar').toString().toLowerCase(),
      title: (json['title'] ?? '').toString(),
      subtitle: json['subtitle']?.toString(),
      currency: json['currency']?.toString(),
      xKey: (json['xKey'] ?? 'name').toString(),
      series: rawSeries
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) =>
                AiChartSeriesSpecDto.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      data: rawData
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
    );
  }
}

@immutable
class AiActionDraftDto {
  const AiActionDraftDto({
    required this.draftId,
    required this.actionType,
    required this.status,
    required this.title,
    required this.summary,
    this.payload = const {},
    this.stagedAttachmentId,
    this.createdEntityId,
    this.createdEntityHref,
  });

  final String draftId;
  final String actionType;
  final String status;
  final String title;
  final String summary;
  final Map<String, dynamic> payload;
  final String? stagedAttachmentId;
  final String? createdEntityId;
  final String? createdEntityHref;

  AiActionDraftDto copyWith({
    String? status,
    String? createdEntityId,
    String? createdEntityHref,
  }) {
    return AiActionDraftDto(
      draftId: draftId,
      actionType: actionType,
      status: status ?? this.status,
      title: title,
      summary: summary,
      payload: payload,
      stagedAttachmentId: stagedAttachmentId,
      createdEntityId: createdEntityId ?? this.createdEntityId,
      createdEntityHref: createdEntityHref ?? this.createdEntityHref,
    );
  }

  factory AiActionDraftDto.fromJson(Map<String, dynamic> json) {
    final rawPayload = json['payload'];
    return AiActionDraftDto(
      draftId: (json['draftId'] ?? '').toString(),
      actionType: (json['actionType'] ?? '').toString().toUpperCase(),
      status: (json['status'] ?? 'PENDING').toString().toUpperCase(),
      title: (json['title'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      payload: rawPayload is Map
          ? Map<String, dynamic>.from(rawPayload)
          : const {},
      stagedAttachmentId: json['stagedAttachmentId']?.toString(),
      createdEntityId: json['createdEntityId']?.toString(),
      createdEntityHref: json['createdEntityHref']?.toString(),
    );
  }
}

@immutable
class AiAttachmentDto {
  const AiAttachmentDto({
    required this.id,
    required this.kind,
    required this.originalFilename,
    required this.contentType,
    required this.fileSizeBytes,
    this.hasExtractedText = false,
    this.extractedPreview,
    this.status = 'STAGED',
    this.createdAt,
    this.localBytes,
  });

  final String id;
  final String kind;
  final String originalFilename;
  final String contentType;
  final int fileSizeBytes;
  final bool hasExtractedText;
  final String? extractedPreview;
  final String status;
  final DateTime? createdAt;

  /// Client-side preview bytes for freshly staged images before persistence.
  final Uint8List? localBytes;

  bool get isImage =>
      kind.toUpperCase() == 'IMAGE' ||
      contentType.toLowerCase().startsWith('image/');

  AiAttachmentDto withLocalBytes(Uint8List bytes) => AiAttachmentDto(
        id: id,
        kind: kind,
        originalFilename: originalFilename,
        contentType: contentType,
        fileSizeBytes: fileSizeBytes,
        hasExtractedText: hasExtractedText,
        extractedPreview: extractedPreview,
        status: status,
        createdAt: createdAt,
        localBytes: bytes,
      );

  factory AiAttachmentDto.fromJson(Map<String, dynamic> json) {
    return AiAttachmentDto(
      id: (json['id'] ?? '').toString(),
      kind: (json['kind'] ?? 'DOCUMENT').toString(),
      originalFilename: (json['originalFilename'] ?? 'file').toString(),
      contentType:
          (json['contentType'] ?? 'application/octet-stream').toString(),
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      hasExtractedText: json['hasExtractedText'] as bool? ?? false,
      extractedPreview: json['extractedPreview']?.toString(),
      status: (json['status'] ?? 'STAGED').toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}

@immutable
class AiMessageDto {
  const AiMessageDto({
    required this.id,
    required this.role,
    required this.content,
    this.thinkingContent,
    this.evidence = const [],
    this.toolsUsed = const [],
    this.charts = const [],
    this.actionDrafts = const [],
    this.attachments = const [],
    this.dataCoverage,
    this.modelId,
    this.reasoningMode = 'fast',
    this.responseLanguage,
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.totalTokens = 0,
    this.latencyMs,
    this.createdAt,
  });

  final String id;
  final String role;
  final String content;
  final String? thinkingContent;
  final List<AiEvidenceItemDto> evidence;
  final List<String> toolsUsed;
  final List<AiChartSpecDto> charts;
  final List<AiActionDraftDto> actionDrafts;
  final List<AiAttachmentDto> attachments;
  final String? dataCoverage;
  final String? modelId;
  final String reasoningMode;
  final String? responseLanguage;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final int? latencyMs;
  final DateTime? createdAt;

  bool get isUser => role.toLowerCase() == 'user';
  bool get isAssistant => !isUser;

  AiMessageDto copyWith({
    List<AiActionDraftDto>? actionDrafts,
  }) {
    return AiMessageDto(
      id: id,
      role: role,
      content: content,
      thinkingContent: thinkingContent,
      evidence: evidence,
      toolsUsed: toolsUsed,
      charts: charts,
      actionDrafts: actionDrafts ?? this.actionDrafts,
      attachments: attachments,
      dataCoverage: dataCoverage,
      modelId: modelId,
      reasoningMode: reasoningMode,
      responseLanguage: responseLanguage,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalTokens: totalTokens,
      latencyMs: latencyMs,
      createdAt: createdAt,
    );
  }

  factory AiMessageDto.fromJson(Map<String, dynamic> json) {
    final rawEv = json['evidence'] as List<dynamic>? ?? const [];
    final rawTools = json['toolsUsed'] as List<dynamic>? ?? const [];
    final rawCharts = json['charts'] as List<dynamic>? ?? const [];
    final rawDrafts = json['actionDrafts'] as List<dynamic>? ?? const [];
    final rawAttachments = json['attachments'] as List<dynamic>? ?? const [];

    return AiMessageDto(
      id: (json['id'] ?? '').toString(),
      role: (json['role'] ?? 'assistant').toString(),
      content: (json['content'] ?? '').toString(),
      thinkingContent: json['thinkingContent']?.toString(),
      evidence: rawEv
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) => AiEvidenceItemDto.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      toolsUsed: rawTools.map((e) => e.toString()).toList(),
      charts: rawCharts
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => AiChartSpecDto.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      actionDrafts: rawDrafts
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) => AiActionDraftDto.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      attachments: rawAttachments
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) => AiAttachmentDto.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      dataCoverage: json['dataCoverage']?.toString(),
      modelId: json['modelId']?.toString(),
      reasoningMode: (json['reasoningMode'] ?? 'fast').toString(),
      responseLanguage: json['responseLanguage']?.toString(),
      promptTokens: (json['promptTokens'] as num?)?.toInt() ?? 0,
      completionTokens: (json['completionTokens'] as num?)?.toInt() ?? 0,
      totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
      latencyMs: (json['latencyMs'] as num?)?.toInt(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}

@immutable
class AiChatResponseDto {
  const AiChatResponseDto({
    required this.conversationId,
    required this.conversationTitle,
    required this.messageId,
    required this.content,
    this.thinkingContent,
    this.evidence = const [],
    this.toolsUsed = const [],
    this.charts = const [],
    this.actionDrafts = const [],
    this.attachments = const [],
    required this.dataCoverage,
    required this.modelId,
    this.reasoningMode = 'fast',
    this.responseLanguage,
    this.latencyMs = 0,
    required this.tokenUsage,
    this.suggestedFollowUps = const [],
    this.createdAt,
  });

  final String conversationId;
  final String conversationTitle;
  final String messageId;
  final String content;
  final String? thinkingContent;
  final List<AiEvidenceItemDto> evidence;
  final List<String> toolsUsed;
  final List<AiChartSpecDto> charts;
  final List<AiActionDraftDto> actionDrafts;
  final List<AiAttachmentDto> attachments;
  final String dataCoverage;
  final String modelId;
  final String reasoningMode;
  final String? responseLanguage;
  final int latencyMs;
  final AiTokenUsageDto tokenUsage;
  final List<String> suggestedFollowUps;
  final DateTime? createdAt;

  AiMessageDto toAssistantMessage() => AiMessageDto(
        id: messageId,
        role: 'assistant',
        content: content,
        thinkingContent: thinkingContent,
        evidence: evidence,
        toolsUsed: toolsUsed,
        charts: charts,
        actionDrafts: actionDrafts,
        attachments: attachments,
        dataCoverage: dataCoverage,
        modelId: modelId,
        reasoningMode: reasoningMode,
        responseLanguage: responseLanguage,
        promptTokens: tokenUsage.promptTokens,
        completionTokens: tokenUsage.completionTokens,
        totalTokens: tokenUsage.totalTokens,
        latencyMs: latencyMs,
        createdAt: createdAt ?? DateTime.now(),
      );

  factory AiChatResponseDto.fromJson(Map<String, dynamic> json) {
    final rawEv = json['evidence'] as List<dynamic>? ?? const [];
    final rawTools = json['toolsUsed'] as List<dynamic>? ?? const [];
    final rawCharts = json['charts'] as List<dynamic>? ?? const [];
    final rawDrafts = json['actionDrafts'] as List<dynamic>? ?? const [];
    final rawAttachments = json['attachments'] as List<dynamic>? ?? const [];
    final rawFollow = json['suggestedFollowUps'] as List<dynamic>? ?? const [];
    final rawUsage = json['tokenUsage'];

    return AiChatResponseDto(
      conversationId: (json['conversationId'] ?? '').toString(),
      conversationTitle: (json['conversationTitle'] ?? '').toString(),
      messageId: (json['messageId'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      thinkingContent: json['thinkingContent']?.toString(),
      evidence: rawEv
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) => AiEvidenceItemDto.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      toolsUsed: rawTools.map((e) => e.toString()).toList(),
      charts: rawCharts
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => AiChartSpecDto.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      actionDrafts: rawDrafts
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) => AiActionDraftDto.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      attachments: rawAttachments
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) => AiAttachmentDto.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      dataCoverage: (json['dataCoverage'] ?? 'PARTIAL_LEDGER').toString(),
      modelId: (json['modelId'] ?? 'gemma4:e4b').toString(),
      reasoningMode: (json['reasoningMode'] ?? 'fast').toString(),
      responseLanguage: json['responseLanguage']?.toString(),
      latencyMs: (json['latencyMs'] as num?)?.toInt() ?? 0,
      tokenUsage: AiTokenUsageDto.fromJson(
        rawUsage is Map ? Map<String, dynamic>.from(rawUsage) : const {},
      ),
      suggestedFollowUps: rawFollow.map((e) => e.toString()).toList(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }
}

@immutable
class AiConversationSummaryDto {
  const AiConversationSummaryDto({
    required this.id,
    required this.title,
    required this.locale,
    this.activeLanguage,
    this.createdAt,
    this.updatedAt,
    this.messageCount = 0,
  });

  final String id;
  final String title;
  final String locale;
  final String? activeLanguage;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int messageCount;

  factory AiConversationSummaryDto.fromJson(Map<String, dynamic> json) {
    return AiConversationSummaryDto(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      locale: (json['locale'] ?? 'en').toString(),
      activeLanguage: json['activeLanguage']?.toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
      messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class AiConversationDetailDto {
  const AiConversationDetailDto({
    required this.id,
    required this.title,
    required this.locale,
    this.activeLanguage,
    this.createdAt,
    this.updatedAt,
    this.messages = const [],
  });

  final String id;
  final String title;
  final String locale;
  final String? activeLanguage;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<AiMessageDto> messages;

  factory AiConversationDetailDto.fromJson(Map<String, dynamic> json) {
    final rawMsgs = json['messages'] as List<dynamic>? ?? const [];
    return AiConversationDetailDto(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      locale: (json['locale'] ?? 'en').toString(),
      activeLanguage: json['activeLanguage']?.toString(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
      messages: rawMsgs
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => AiMessageDto.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

@immutable
class BusinessMemoryDto {
  const BusinessMemoryDto({
    required this.id,
    required this.memoryType,
    required this.title,
    required this.content,
    this.sourceType = 'USER_NOTE',
    this.sourceId,
    required this.status,
    this.visibility = 'BUSINESS',
    this.modelId,
    required this.hasVector,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final BusinessMemoryType memoryType;
  final String title;
  final String content;
  final String sourceType;
  final String? sourceId;
  final String status;
  final String visibility;
  final String? modelId;
  final bool hasVector;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isProposed => status.toUpperCase() == 'PROPOSED';
  bool get isApproved => status.toUpperCase() == 'APPROVED';
  bool get isExpired => status.toUpperCase() == 'EXPIRED';

  factory BusinessMemoryDto.fromJson(Map<String, dynamic> json) {
    return BusinessMemoryDto(
      id: (json['id'] ?? '').toString(),
      memoryType: BusinessMemoryType.fromApi(json['memoryType']?.toString()),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      sourceType: (json['sourceType'] ?? 'USER_NOTE').toString(),
      sourceId: json['sourceId']?.toString(),
      status: (json['status'] ?? 'APPROVED').toString().toUpperCase(),
      visibility: (json['visibility'] ?? 'BUSINESS').toString(),
      modelId: json['modelId']?.toString(),
      hasVector: json['hasVector'] as bool? ?? false,
      expiresAt: DateTime.tryParse((json['expiresAt'] ?? '').toString()),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
    );
  }
}

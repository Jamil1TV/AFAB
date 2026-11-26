import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/error/error_mapper.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/core/network/global_events.dart';
import 'package:afab_mobile/features/ai/data/ai_dtos.dart';
import 'package:afab_mobile/features/ai/data/sse_parser.dart';
import 'package:afab_mobile/features/ai/domain/message_direction_resolver.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

class AiStreamCancelledException implements Exception {
  const AiStreamCancelledException();
}

class AiRepository {
  AiRepository({
    required this.dio,
    required this.sseDio,
    required this.eventBus,
  });

  final Dio dio;
  final Dio sseDio;
  final GlobalEventBus eventBus;

  Future<AiStatusDto> getStatus({bool fresh = false}) async {
    try {
      final res = await dio.get<Map<String, dynamic>>(
        '/ai/status',
        queryParameters: fresh ? const {'fresh': 'true'} : null,
      );
      return AiStatusDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<AiHealthDto> getHealth({bool fresh = true}) async {
    try {
      final res = await dio.get<Map<String, dynamic>>(
        '/ai/health',
        queryParameters: {'fresh': fresh ? 'true' : 'false'},
        options: Options(extra: const {'requireAuth': false}),
      );
      return AiHealthDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<AiIndexSyncResponseDto> syncIndex() async {
    try {
      final res = await dio.post<Map<String, dynamic>>('/ai/index/sync');
      return AiIndexSyncResponseDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<List<AiConversationSummaryDto>> listConversations() async {
    try {
      final res = await dio.get<List<dynamic>>('/ai/conversations');
      return (res.data ?? const [])
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) =>
                AiConversationSummaryDto.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<AiConversationDetailDto> getConversation(String id) async {
    try {
      final res = await dio.get<Map<String, dynamic>>('/ai/conversations/$id');
      return AiConversationDetailDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> deleteConversation(String id) async {
    try {
      await dio.delete<void>('/ai/conversations/$id');
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<AiAttachmentDto> stageAttachment({
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) async {
    final mime = contentType ?? AiAttachmentValidator.guessContentType(filename);
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: MediaType.parse(mime),
        ),
      });
      final res = await dio.post<Map<String, dynamic>>(
        '/ai/attachments/stage',
        data: form,
      );
      return AiAttachmentDto.fromJson(res.data ?? const {})
          .withLocalBytes(bytes);
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<Uint8List> fetchAttachmentPreview(String id) async {
    try {
      final res = await dio.get<List<int>>(
        '/ai/attachments/$id/preview',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(res.data ?? const <int>[]);
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<AiChatResponseDto> sendChat({
    required String message,
    String? conversationId,
    required String locale,
    AiReasoningMode reasoningMode = AiReasoningMode.fast,
    List<String> attachmentIds = const [],
    Map<String, String>? screenContext,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/ai/chat',
        cancelToken: cancelToken,
        data: {
          'message': message,
          if (conversationId != null && conversationId.isNotEmpty)
            'conversationId': conversationId,
          'locale': locale,
          'reasoningMode': reasoningMode.apiValue,
          if (attachmentIds.isNotEmpty) 'attachmentIds': attachmentIds,
          if (screenContext != null && screenContext.isNotEmpty)
            'screenContext': screenContext,
        },
      );
      return AiChatResponseDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw const AiStreamCancelledException();
      }
      throw ErrorMapper.fromDio(e);
    }
  }

  /// Streams Server-Sent Events from `POST /api/v1/ai/chat/stream`.
  /// Emits typed [SseEvent] frames in real time and throws [AppFailure] or
  /// [AiStreamCancelledException].
  Stream<SseEvent> streamChat({
    required String message,
    String? conversationId,
    required String locale,
    AiReasoningMode reasoningMode = AiReasoningMode.fast,
    List<String> attachmentIds = const [],
    Map<String, String>? screenContext,
    CancelToken? cancelToken,
  }) async* {
    Response<ResponseBody> response;
    try {
      response = await sseDio.post<ResponseBody>(
        '/ai/chat/stream',
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: const {
            'Accept': 'text/event-stream',
            'Cache-Control': 'no-cache',
          },
        ),
        data: {
          'message': message,
          if (conversationId != null && conversationId.isNotEmpty)
            'conversationId': conversationId,
          'locale': locale,
          'reasoningMode': reasoningMode.apiValue,
          if (attachmentIds.isNotEmpty) 'attachmentIds': attachmentIds,
          if (screenContext != null && screenContext.isNotEmpty)
            'screenContext': screenContext,
        },
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e) || (cancelToken?.isCancelled ?? false)) {
        throw const AiStreamCancelledException();
      }
      throw await _mapStreamDioException(e);
    }

    final body = response.data;
    if (body == null) {
      throw const ServerFailure(
        message: 'Empty response stream from server.',
        code: 'EMPTY_STREAM',
        statusCode: 502,
      );
    }

    final parser = SseFrameParser();
    var receivedDone = false;

    try {
      await for (final chunk in body.stream) {
        if (cancelToken?.isCancelled ?? false) {
          throw const AiStreamCancelledException();
        }
        final events = parser.addBytes(chunk);
        for (final ev in events) {
          if (ev is SseDoneEvent) {
            receivedDone = true;
          } else if (ev is SseErrorEvent) {
            throw _mapSseErrorEvent(ev);
          }
          yield ev;
        }
      }

      if (cancelToken?.isCancelled ?? false) {
        throw const AiStreamCancelledException();
      }

      final tail = parser.close();
      for (final ev in tail) {
        if (ev is SseDoneEvent) {
          receivedDone = true;
        } else if (ev is SseErrorEvent) {
          throw _mapSseErrorEvent(ev);
        }
        yield ev;
      }

      if (!receivedDone) {
        throw const ServerFailure(
          message:
              'Copilot stream ended unexpectedly before completing. Please try again.',
          code: 'INCOMPLETE_STREAM',
          statusCode: 502,
        );
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e) || (cancelToken?.isCancelled ?? false)) {
        throw const AiStreamCancelledException();
      }
      throw await _mapStreamDioException(e);
    }
  }

  Future<AppFailure> _mapStreamDioException(DioException e) async {
    final resp = e.response;
    if (resp != null && resp.data is ResponseBody) {
      try {
        final rawBody = resp.data as ResponseBody;
        final bytes = await rawBody.stream.expand((c) => c).toList();
        final text = utf8.decode(bytes, allowMalformed: true);
        final decoded = jsonDecode(text);
        if (decoded is Map) {
          final failure = ErrorMapper.fromResponse(
            statusCode: resp.statusCode ?? 500,
            data: Map<String, dynamic>.from(decoded),
            headers: resp.headers.map,
          );
          _emitGlobalPolicyFailureIfNeeded(failure);
          return failure;
        }
      } catch (_) {
        // Fall through to standard ErrorMapper.
      }
    }
    return ErrorMapper.fromDio(e);
  }

  AppFailure _mapSseErrorEvent(SseErrorEvent ev) {
    final upper = ev.code.toUpperCase();
    if (upper == 'PLAN_LIMIT_REACHED') {
      final failure = PlanLimitReachedFailure(
        message: ev.message,
        feature: (ev.details['feature'] ?? 'ai.chat.queries_per_month').toString(),
        limit: (ev.details['limit'] as num?)?.toInt() ?? 0,
        used: (ev.details['used'] as num?)?.toInt() ?? 0,
        upgradeTo: (ev.details['upgradeTo'] ?? 'plus').toString(),
      );
      _emitGlobalPolicyFailureIfNeeded(failure);
      return failure;
    }
    if (upper == 'BUSINESS_READ_ONLY') {
      final failure = BusinessReadOnlyFailure(
        message: ev.message,
        businessId: ev.details['businessId']?.toString(),
        businessName: ev.details['businessName']?.toString(),
      );
      _emitGlobalPolicyFailureIfNeeded(failure);
      return failure;
    }
    if (upper == 'AI_SERVICE_UNAVAILABLE') {
      return AiUnavailableFailure(message: ev.message);
    }
    return ServerFailure(
      message: ev.message,
      code: ev.code,
      statusCode: 503,
    );
  }

  void _emitGlobalPolicyFailureIfNeeded(AppFailure failure) {
    if (failure is PlanLimitReachedFailure) {
      eventBus.emit(
        PlanLimitReachedEvent(
          feature: failure.feature,
          limit: failure.limit,
          used: failure.used,
          upgradeTo: failure.upgradeTo,
          message: failure.message,
        ),
      );
    } else if (failure is BusinessReadOnlyFailure) {
      eventBus.emit(
        BusinessReadOnlyEvent(
          businessId: failure.businessId,
          businessName: failure.businessName,
          message: failure.message,
        ),
      );
    }
  }

  Future<AiActionDraftDto> approveTransactionDraft(
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/ai/actions/approve-transaction',
        data: payload,
      );
      return AiActionDraftDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<AiActionDraftDto> approveInvoiceDraft(
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/ai/actions/approve-invoice',
        data: payload,
      );
      return AiActionDraftDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<AiActionDraftDto> approveBudgetDraft(
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/ai/actions/approve-budget',
        data: payload,
      );
      return AiActionDraftDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<AiActionDraftDto> approveMemoryDraft(
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/ai/actions/approve-memory',
        data: payload,
      );
      return AiActionDraftDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<AiActionDraftDto> dismissDraft({
    required String messageId,
    required String draftId,
  }) async {
    try {
      final encodedDraft = Uri.encodeComponent(draftId);
      final res = await dio.patch<Map<String, dynamic>>(
        '/ai/messages/$messageId/drafts/$encodedDraft/dismiss',
      );
      return AiActionDraftDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<List<BusinessMemoryDto>> listMemory({String status = 'ALL'}) async {
    try {
      final res = await dio.get<List<dynamic>>(
        '/ai/memory',
        queryParameters: {'status': status},
      );
      return (res.data ?? const [])
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) => BusinessMemoryDto.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<BusinessMemoryDto> createMemory({
    required BusinessMemoryType memoryType,
    required String title,
    required String content,
    String status = 'APPROVED',
  }) async {
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/ai/memory',
        data: {
          'memoryType': memoryType.apiValue,
          'title': title,
          'content': content,
          'status': status,
        },
      );
      return BusinessMemoryDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<BusinessMemoryDto> updateMemory({
    required String id,
    BusinessMemoryType? memoryType,
    String? title,
    String? content,
    String? status,
  }) async {
    try {
      final res = await dio.patch<Map<String, dynamic>>(
        '/ai/memory/$id',
        data: {
          if (memoryType != null) 'memoryType': memoryType.apiValue,
          'title': ?title,
          'content': ?content,
          'status': ?status,
        },
      );
      return BusinessMemoryDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> deleteMemory(String id) async {
    try {
      await dio.delete<void>('/ai/memory/$id');
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }
}

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository(
    dio: ref.watch(dioProvider),
    sseDio: ref.watch(sseDioProvider),
    eventBus: ref.watch(globalEventBusProvider),
  );
});

import 'dart:convert';
import 'dart:typed_data';

import 'package:afab_mobile/features/ai/data/ai_dtos.dart';

sealed class SseEvent {
  const SseEvent();
}

final class SseStatusEvent extends SseEvent {
  const SseStatusEvent({
    required this.phase,
    this.conversationId,
    this.activeLanguage,
    this.reasoningMode,
  });

  final String phase;
  final String? conversationId;
  final String? activeLanguage;
  final String? reasoningMode;
}

final class SsePingEvent extends SseEvent {
  const SsePingEvent({required this.timestamp});
  final int timestamp;
}

final class SseThoughtEvent extends SseEvent {
  const SseThoughtEvent({required this.text});
  final String text;
}

final class SseToolStartEvent extends SseEvent {
  const SseToolStartEvent({required this.tool});
  final String tool;
}

final class SseToolDoneEvent extends SseEvent {
  const SseToolDoneEvent({
    required this.tool,
    required this.evidenceCount,
  });

  final String tool;
  final int evidenceCount;
}

final class SseDeltaEvent extends SseEvent {
  const SseDeltaEvent({required this.text});
  final String text;
}

final class SseReplaceEvent extends SseEvent {
  const SseReplaceEvent({required this.text});
  final String text;
}

final class SseDoneEvent extends SseEvent {
  const SseDoneEvent({required this.response});
  final AiChatResponseDto response;
}

final class SseErrorEvent extends SseEvent {
  const SseErrorEvent({
    required this.code,
    required this.message,
    this.details = const {},
  });

  final String code;
  final String message;
  final Map<String, dynamic> details;
}

/// Pure-Dart incremental Server-Sent Events parser resilient to arbitrary
/// chunk splits (including multi-byte UTF-8 boundaries and `\r\n\r\n` / `\n\n`).
class SseFrameParser {
  final BytesBuilder _byteBuffer = BytesBuilder(copy: false);
  String _textBuffer = '';

  List<SseEvent> addBytes(List<int> bytes) {
    if (bytes.isEmpty) return const [];
    _byteBuffer.add(bytes);
    // Decode complete UTF-8 sequences cleanly; wait if trailing sequence split.
    final allBytes = _byteBuffer.takeBytes();
    final decoded = _decodeSafely(allBytes);
    if (decoded.remainder.isNotEmpty) {
      _byteBuffer.add(decoded.remainder);
    }
    return addText(decoded.text);
  }

  List<SseEvent> addText(String chunk) {
    if (chunk.isEmpty) return const [];
    _textBuffer += chunk;
    final events = <SseEvent>[];
    final sepRegex = RegExp(r'\r?\n\r?\n');

    while (true) {
      final match = sepRegex.firstMatch(_textBuffer);
      if (match == null) break;
      final rawFrame = _textBuffer.substring(0, match.start);
      _textBuffer = _textBuffer.substring(match.end);
      if (rawFrame.trim().isNotEmpty) {
        final ev = _parseFrame(rawFrame);
        if (ev != null) events.add(ev);
      }
    }
    return events;
  }

  /// Flushes any remaining buffered bytes/text on stream EOF.
  List<SseEvent> close() {
    final events = <SseEvent>[];
    if (_byteBuffer.isNotEmpty) {
      final leftover = utf8.decode(_byteBuffer.takeBytes(), allowMalformed: true);
      events.addAll(addText(leftover));
    }
    final remaining = _textBuffer.trim();
    _textBuffer = '';
    if (remaining.isNotEmpty) {
      final ev = _parseFrame(remaining);
      if (ev != null) events.add(ev);
    }
    return events;
  }

  ({String text, List<int> remainder}) _decodeSafely(List<int> bytes) {
    // Check up to 3 trailing bytes in case a multi-byte UTF-8 rune was split.
    var end = bytes.length;
    if (end > 0) {
      var back = 0;
      while (back < 3 && end - 1 - back >= 0) {
        final b = bytes[end - 1 - back];
        if ((b & 0x80) == 0) {
          // ASCII byte — nothing split at end.
          break;
        }
        if ((b & 0xC0) == 0xC0) {
          // UTF-8 leading byte; check expected rune length vs remaining bytes.
          final expectedLen = (b & 0xE0) == 0xC0
              ? 2
              : (b & 0xF0) == 0xE0
                  ? 3
                  : (b & 0xF8) == 0xF0
                      ? 4
                      : 1;
          final available = back + 1;
          if (available < expectedLen) {
            end = end - available;
          }
          break;
        }
        back++;
      }
    }
    final validSlice = end == bytes.length ? bytes : bytes.sublist(0, end);
    final rem = end == bytes.length ? const <int>[] : bytes.sublist(end);
    return (
      text: utf8.decode(validSlice, allowMalformed: true),
      remainder: rem,
    );
  }

  SseEvent? _parseFrame(String rawFrame) {
    final lines = rawFrame.split(RegExp(r'\r?\n'));
    var eventName = 'message';
    final dataLines = <String>[];

    for (final line in lines) {
      if (line.startsWith(':')) continue; // SSE comment / keepalive
      if (line.startsWith('event:')) {
        eventName = line.substring(6).trim();
      } else if (line.startsWith('data:')) {
        var value = line.substring(5);
        if (value.startsWith(' ')) value = value.substring(1);
        dataLines.add(value);
      }
    }

    if (dataLines.isEmpty) return null;
    final rawJson = dataLines.join('\n').trim();
    if (rawJson.isEmpty) return null;

    final dynamic decoded = jsonDecode(rawJson);
    if (decoded is! Map) return null;
    final map = Map<String, dynamic>.from(decoded);

    switch (eventName) {
      case 'ping':
        return SsePingEvent(timestamp: (map['ts'] as num?)?.toInt() ?? 0);
      case 'status':
        final phase = map['phase']?.toString();
        if (phase == null || phase.isEmpty) return null;
        return SseStatusEvent(
          phase: phase,
          conversationId: map['conversationId']?.toString(),
          activeLanguage: map['activeLanguage']?.toString(),
          reasoningMode: map['reasoningMode']?.toString(),
        );
      case 'thought':
        final text = map['text']?.toString();
        return text == null ? null : SseThoughtEvent(text: text);
      case 'delta':
        final text = map['text']?.toString();
        return text == null ? null : SseDeltaEvent(text: text);
      case 'replace':
        final text = map['text']?.toString();
        return text == null ? null : SseReplaceEvent(text: text);
      case 'tool_start':
        final tool = map['tool']?.toString();
        return tool == null ? null : SseToolStartEvent(tool: tool);
      case 'tool_done':
        final tool = map['tool']?.toString();
        if (tool == null) return null;
        return SseToolDoneEvent(
          tool: tool,
          evidenceCount: (map['evidenceCount'] as num?)?.toInt() ?? 0,
        );
      case 'done':
        return SseDoneEvent(response: AiChatResponseDto.fromJson(map));
      case 'error':
        return SseErrorEvent(
          code: (map['code'] ?? 'AI_ERROR').toString(),
          message: (map['message'] ?? 'AI stream error').toString(),
          details: map,
        );
      default:
        return null;
    }
  }
}

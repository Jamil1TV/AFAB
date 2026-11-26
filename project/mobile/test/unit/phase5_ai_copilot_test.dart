import 'dart:convert';
import 'dart:typed_data';

import 'package:afab_mobile/features/ai/data/ai_dtos.dart';
import 'package:afab_mobile/features/ai/data/sse_parser.dart';
import 'package:afab_mobile/features/ai/domain/ai_providers.dart';
import 'package:afab_mobile/features/ai/domain/message_direction_resolver.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:afab_mobile/core/network/dio_client.dart';

void main() {
  group('Phase 5 Unit Tests — SSE, BiDi, Attachments & AI DTOs', () {
    test('SseFrameParser handles chunk splits, CRLF, multi-line data, and all 9 event types', () {
      final parser = SseFrameParser();
      const rawStream = ''
          'event: status\r\n'
          'data: {"phase":"warming_model","conversationId":"c-1","activeLanguage":"AR_DERJA_SCRIPT"}\r\n\r\n'
          'event: ping\n'
          'data: {"ts":1730000000}\n\n'
          'event: thought\n'
          'data: {"text":"Checking revenue..."}\n\n'
          'event: tool_start\n'
          'data: {"tool":"get_business_summary"}\n\n'
          'event: tool_done\n'
          'data: {"tool":"get_business_summary","evidenceCount":4}\n\n'
          'event: delta\n'
          'data: {"text":"مرحبا "}\n\n'
          'event: replace\n'
          'data: {"text":"السلام عليكم"}\n\n'
          'event: error\n'
          'data: {"code":"PLAN_LIMIT_REACHED","message":"Quota reached","limit":10,"used":10}\n\n'
          'event: done\n'
          'data: {\n'
          'data: "conversationId":"c-1",\n'
          'data: "conversationTitle":"Monthly Summary",\n'
          'data: "messageId":"m-1",\n'
          'data: "content":"Done",\n'
          'data: "evidence":[],\n'
          'data: "toolsUsed":["get_business_summary"],\n'
          'data: "dataCoverage":"RAG_GROUNDED",\n'
          'data: "modelId":"gemma4:e4b",\n'
          'data: "tokenUsage":{"monthlyTokensLimit":-1,"monthlyTokensUsed":50,"planSlug":"pro","planName":"Pro"},\n'
          'data: "suggestedFollowUps":["Compare last month"]\n'
          'data: }';

      final bytes = utf8.encode(rawStream);
      final events = <SseEvent>[];
      // Split across arbitrary small 7-byte chunks (including multi-byte Arabic runes)
      for (var i = 0; i < bytes.length; i += 7) {
        final end = (i + 7 > bytes.length) ? bytes.length : i + 7;
        events.addAll(parser.addBytes(bytes.sublist(i, end)));
      }
      events.addAll(parser.close());

      expect(events.length, 9);
      expect(events[0], isA<SseStatusEvent>());
      expect((events[0] as SseStatusEvent).phase, 'warming_model');
      expect((events[0] as SseStatusEvent).activeLanguage, 'AR_DERJA_SCRIPT');
      expect(events[1], isA<SsePingEvent>());
      expect(events[2], isA<SseThoughtEvent>());
      expect(events[3], isA<SseToolStartEvent>());
      expect((events[4] as SseToolDoneEvent).evidenceCount, 4);
      expect((events[5] as SseDeltaEvent).text, 'مرحبا ');
      expect((events[6] as SseReplaceEvent).text, 'السلام عليكم');
      expect((events[7] as SseErrorEvent).code, 'PLAN_LIMIT_REACHED');
      final done = events[8] as SseDoneEvent;
      expect(done.response.conversationId, 'c-1');
      expect(done.response.tokenUsage.isTokensUnlimited, isTrue);
      expect(done.response.suggestedFollowUps, ['Compare last month']);
    });

    test('MessageDirectionResolver isolates polyglot bubbles from UI locale', () {
      expect(
        MessageDirectionResolver.resolveForMessage(
          'Hello',
          responseLanguage: 'AR_MSA',
        ),
        TextDirection.rtl,
      );
      expect(
        MessageDirectionResolver.resolveForMessage(
          'Chniya masarif hal chhar?',
          responseLanguage: 'AR_DERJA_ARABIZI',
        ),
        TextDirection.ltr,
      );
      expect(
        MessageDirectionResolver.resolveForMessage('قداش صرفت هذا الشهر؟'),
        TextDirection.rtl,
      );
      expect(
        MessageDirectionResolver.resolveForMessage('Your net profit is \$500'),
        TextDirection.ltr,
      );
      expect(
        MessageDirectionResolver.resolveForComposer('', 'ar'),
        TextDirection.rtl,
      );
      expect(
        MessageDirectionResolver.resolveForComposer('Check KPIs', 'ar'),
        TextDirection.ltr,
      );
    });

    test('AiAttachmentValidator enforces 3-file cap, 10MB cap, extensions, and NUL bytes', () {
      expect(
        AiAttachmentValidator.validate(
          bytes: Uint8List.fromList([1, 2, 3]),
          filename: 'receipt.jpg',
          currentlyStagedCount: 3,
        ),
        isNotNull,
      );
      expect(
        AiAttachmentValidator.validate(
          bytes: Uint8List(10 * 1024 * 1024 + 1),
          filename: 'scan.pdf',
        ),
        isNotNull,
      );
      expect(
        AiAttachmentValidator.validate(
          bytes: Uint8List.fromList([1, 2, 3]),
          filename: 'archive.zip',
        ),
        isNotNull,
      );
      expect(
        AiAttachmentValidator.validate(
          bytes: Uint8List.fromList([0x41, 0x00, 0x42]),
          filename: 'bad.csv',
        ),
        isNotNull,
      );
      expect(
        AiAttachmentValidator.validate(
          bytes: Uint8List.fromList(utf8.encode('date,amount\n2026-11-01,100')),
          filename: 'ledger.csv',
        ),
        isNull,
      );
    });

    test('AI DTOs and extended AiPulseDto parse Decimal and quota fields accurately', () {
      final status = AiStatusDto.fromJson({
        'enabled': true,
        'ollamaReachable': true,
        'chatModel': 'gemma4:e4b',
        'chatModelReady': true,
        'chatModelLoaded': true,
        'embedModel': 'embeddinggemma-2:270m',
        'embedModelReady': true,
        'busy': false,
        'latencyMs': 42,
        'indexedChunks': 128,
        'approvedMemories': 7,
        'quota': {
          'monthlyTokensUsed': 4500,
          'monthlyTokensLimit': 10000,
          'monthlyTokensRemaining': 5500,
          'monthlyQueriesUsed': 3,
          'monthlyQueriesLimit': -1,
          'planSlug': 'plus',
          'planName': 'Plus',
        },
      });
      expect(status.indexedChunks, 128);
      expect(status.approvedMemories, 7);
      expect(status.quota.tokenPercent, 45.0);
      expect(status.quota.isQueriesUnlimited, isTrue);

      final pulse = AiPulseDto.fromJson({
        'currency': 'TND',
        'highCount': 1,
        'mediumCount': 2,
        'monthNetProfit': '1250.500',
        'overdueCount': 3,
        'alerts': [
          {
            'id': 'a-1',
            'type': 'OVERDUE_INVOICES',
            'severity': 'HIGH',
            'title': '3 Overdue',
            'description': 'Follow up now',
            'metricValue': '980.000',
            'currency': 'TND',
            'copilotPrompt': 'Analyze overdue invoices',
            'href': '/dashboard/invoices',
          },
        ],
      });
      expect(pulse.safeMonthNetProfit, Decimal.parse('1250.500'));
      expect(pulse.alerts.first.metricValue, Decimal.parse('980.000'));
      expect(
        mapWebHrefToMobileRoute('/dashboard/ai?tab=memory'),
        '/copilot/memory',
      );
      expect(mapWebHrefToMobileRoute('/ar/dashboard/invoices'), '/invoices');
    });

    test('CopilotLauncherNotifier manages nonce & close state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      container.read(copilotLauncherProvider.notifier).openCopilot(
            prompt: 'Explain profit',
            autoSend: true,
            screenContext: const {'page': 'dashboard'},
          );
      final s1 = container.read(copilotLauncherProvider);
      expect(s1.isOpen, isTrue);
      expect(s1.pendingRequest?.nonce, 1);
      expect(s1.pendingRequest?.autoSend, isTrue);

      container.read(copilotLauncherProvider.notifier).clearPendingRequest();
      expect(container.read(copilotLauncherProvider).pendingRequest, isNull);
      container.read(copilotLauncherProvider.notifier).closeCopilot();
      expect(container.read(copilotLauncherProvider).isOpen, isFalse);
    });
  });
}

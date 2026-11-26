import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum DictationLocaleOption {
  en('en_US', 'EN'),
  fr('fr_FR', 'FR'),
  tn('ar_TN', 'TN');

  const DictationLocaleOption(this.localeId, this.shortLabel);
  final String localeId;
  final String shortLabel;

  DictationLocaleOption next() {
    final idx = DictationLocaleOption.values.indexOf(this);
    return DictationLocaleOption
        .values[(idx + 1) % DictationLocaleOption.values.length];
  }

  static DictationLocaleOption fromUiLocale(String uiLocale) {
    final lower = uiLocale.toLowerCase();
    if (lower.startsWith('ar')) return tn;
    if (lower.startsWith('fr')) return fr;
    return en;
  }
}

abstract class SpeechDictationService {
  Future<bool> startListening({
    required DictationLocaleOption locale,
    required void Function(String text, bool isFinal) onResult,
    required void Function(String status) onStatus,
    required void Function(String message, bool permissionDenied) onError,
  });

  Future<void> stop();
  Future<void> cancel();
}

class DeviceSpeechDictationService implements SpeechDictationService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  Set<String> _availableLocaleIds = {};

  @override
  Future<bool> startListening({
    required DictationLocaleOption locale,
    required void Function(String text, bool isFinal) onResult,
    required void Function(String status) onStatus,
    required void Function(String message, bool permissionDenied) onError,
  }) async {
    try {
      if (!_initialized) {
        _initialized = await _speech.initialize(
          onStatus: onStatus,
          onError: (err) {
            final msg = err.errorMsg.toLowerCase();
            final denied = msg.contains('permission') || msg.contains('denied');
            onError(err.errorMsg, denied);
          },
        );
        if (!_initialized) {
          onError('Speech recognition unavailable on this device.', false);
          return false;
        }
        final locales = await _speech.locales();
        _availableLocaleIds = locales.map((l) => l.localeId.toLowerCase()).toSet();
      }

      final resolvedLocale = _resolveLocaleId(locale);
      await _speech.listen(
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
          localeId: resolvedLocale,
        ),
        onResult: (res) => onResult(res.recognizedWords, res.finalResult),
      );
      return true;
    } catch (e) {
      final lower = e.toString().toLowerCase();
      onError(e.toString(), lower.contains('permission'));
      return false;
    }
  }

  String _resolveLocaleId(DictationLocaleOption option) {
    if (_availableLocaleIds.isEmpty) return option.localeId;
    final desired = option.localeId.toLowerCase();
    if (_availableLocaleIds.contains(desired) ||
        _availableLocaleIds.contains(desired.replaceAll('_', '-'))) {
      return option.localeId;
    }
    if (option == DictationLocaleOption.tn) {
      for (final fallback in const ['ar_SA', 'ar-SA', 'ar_EG', 'ar']) {
        if (_availableLocaleIds.contains(fallback.toLowerCase())) {
          return fallback;
        }
      }
    }
    final prefix = desired.split('_').first;
    for (final id in _availableLocaleIds) {
      if (id.startsWith(prefix)) return id;
    }
    return option.localeId;
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() => _speech.cancel();
}

final speechDictationServiceProvider = Provider<SpeechDictationService>((ref) {
  final service = DeviceSpeechDictationService();
  ref.onDispose(service.cancel);
  return service;
});

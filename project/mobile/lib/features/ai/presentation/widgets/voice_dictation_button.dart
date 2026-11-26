import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/ai/domain/speech_dictation_service.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class VoiceDictationButton extends ConsumerStatefulWidget {
  const VoiceDictationButton({
    super.key,
    required this.uiLocale,
    required this.disabled,
    required this.onFinalTranscript,
    required this.onInterimChanged,
  });

  final String uiLocale;
  final bool disabled;
  final ValueChanged<String> onFinalTranscript;
  final ValueChanged<String> onInterimChanged;

  @override
  ConsumerState<VoiceDictationButton> createState() =>
      _VoiceDictationButtonState();
}

class _VoiceDictationButtonState extends ConsumerState<VoiceDictationButton> {
  late DictationLocaleOption _locale;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _locale = DictationLocaleOption.fromUiLocale(widget.uiLocale);
  }

  Future<void> _toggle() async {
    if (widget.disabled) return;
    final service = ref.read(speechDictationServiceProvider);
    if (_listening) {
      await service.stop();
      if (mounted) {
        setState(() => _listening = false);
        widget.onInterimChanged('');
      }
      return;
    }

    final started = await service.startListening(
      locale: _locale,
      onResult: (words, isFinal) {
        if (!mounted) return;
        if (isFinal) {
          if (words.trim().isNotEmpty) {
            widget.onFinalTranscript(words.trim());
          }
          setState(() => _listening = false);
          widget.onInterimChanged('');
        } else {
          widget.onInterimChanged(words.trim());
        }
      },
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() => _listening = false);
          widget.onInterimChanged('');
        }
      },
      onError: (_, permissionDenied) {
        if (!mounted) return;
        setState(() => _listening = false);
        widget.onInterimChanged('');
        AfabToast.showError(
          context,
          permissionDenied
              ? context.l10n.aiVoicePermissionDenied
              : context.l10n.aiVoiceError,
        );
      },
    );

    if (mounted && started) {
      setState(() => _listening = true);
    }
  }

  void _cycleLocale() {
    if (_listening || widget.disabled) return;
    setState(() => _locale = _locale.next());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: '${l10n.aiVoiceSwitchLang}: ${_locale.shortLabel}',
            child: InkWell(
              onTap: (_listening || widget.disabled) ? null : _cycleLocale,
              borderRadius: BorderRadius.circular(11),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    _locale.shortLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.textMuted,
                        ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: _listening ? l10n.aiVoiceStop : l10n.aiVoiceStart,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            padding: EdgeInsets.zero,
            onPressed: widget.disabled ? null : _toggle,
            style: IconButton.styleFrom(
              backgroundColor: _listening ? colors.danger : Colors.transparent,
              foregroundColor:
                  _listening ? Colors.white : colors.textMuted,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: Icon(
              _listening ? LucideIcons.micOff : LucideIcons.mic,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

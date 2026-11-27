import 'dart:io';

import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/network/connectivity_provider.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/ai/data/ai_dtos.dart';
import 'package:afab_mobile/features/ai/domain/message_direction_resolver.dart';
import 'package:afab_mobile/features/ai/presentation/widgets/attachment_preview_chip.dart';
import 'package:afab_mobile/features/ai/presentation/widgets/voice_dictation_button.dart';
import 'package:afab_mobile/shared/widgets/afab_bottom_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

typedef StageAttachmentCallback = Future<bool> Function({
  required Uint8List bytes,
  required String filename,
  String? contentType,
});

class CopilotComposer extends ConsumerStatefulWidget {
  const CopilotComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.stagedAttachments,
    required this.reasoningMode,
    required this.sending,
    required this.uploadingAttachment,
    required this.isReadOnly,
    this.compact = false,
    required this.onReasoningModeChanged,
    required this.onSend,
    required this.onStop,
    required this.onStageAttachment,
    required this.onRemoveAttachment,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<AiAttachmentDto> stagedAttachments;
  final AiReasoningMode reasoningMode;
  final bool sending;
  final bool uploadingAttachment;
  final bool isReadOnly;
  final bool compact;
  final ValueChanged<AiReasoningMode> onReasoningModeChanged;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final StageAttachmentCallback onStageAttachment;
  final ValueChanged<String> onRemoveAttachment;

  static Future<void> showAttachmentSourceSheet(
    BuildContext context, {
    required int currentCount,
    required StageAttachmentCallback onStage,
  }) async {
    final l10n = context.l10n;
    if (currentCount >= AiAttachmentValidator.maxFilesPerTurn) {
      AfabToast.showError(context, l10n.aiAttachMaxThree);
      return;
    }

    await showAfabBottomSheet<void>(
      context: context,
      title: l10n.aiAttachTitle,
      subtitle: l10n.aiAttachSupportedHint,
      builder: (sheetCtx) => _AttachmentPickerSheetBody(
        parentContext: context,
        currentCount: currentCount,
        onStage: onStage,
      ),
    );
  }

  @override
  ConsumerState<CopilotComposer> createState() => _CopilotComposerState();
}

class _CopilotComposerState extends ConsumerState<CopilotComposer> {
  String _interimVoice = '';
  TextDirection _composerDir = TextDirection.ltr;
  bool _hasText = false;
  bool _isFocused = false;
  String _cachedLocale = 'en';

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    _isFocused = widget.focusNode.hasFocus;
    widget.controller.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cachedLocale = Localizations.localeOf(context).languageCode;
    _composerDir = MessageDirectionResolver.resolveForComposer(
      widget.controller.text,
      _cachedLocale,
    );
  }

  @override
  void didUpdateWidget(covariant CopilotComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
      _onTextChanged();
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      widget.focusNode.addListener(_onFocusChanged);
      _isFocused = widget.focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final nextHasText = widget.controller.text.trim().isNotEmpty;
    final nextDir = MessageDirectionResolver.resolveForComposer(
      widget.controller.text,
      _cachedLocale,
    );
    if (nextHasText != _hasText || nextDir != _composerDir) {
      if (mounted) {
        setState(() {
          _hasText = nextHasText;
          _composerDir = nextDir;
        });
      }
    }
  }

  void _onFocusChanged() {
    final nextFocused = widget.focusNode.hasFocus;
    if (nextFocused != _isFocused && mounted) {
      setState(() => _isFocused = nextFocused);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final isOnline = ref.watch(isOnlineProvider);
    final uiLocale = _cachedLocale;
    final disabled = widget.isReadOnly || !isOnline;
    final canSend =
        !disabled && (_hasText || widget.stagedAttachments.isNotEmpty);

    return _KeyboardAwareBottomInset(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          widget.compact ? 12 : 14,
          6,
          widget.compact ? 12 : 14,
          widget.compact ? 12 : 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.stagedAttachments.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final att in widget.stagedAttachments)
                    AttachmentPreviewChip(
                      attachment: att,
                      compact: widget.compact,
                      onRemove: widget.sending
                          ? null
                          : () => widget.onRemoveAttachment(att.id),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (_interimVoice.isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.dangerBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.mic, size: 13, color: colors.danger),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${l10n.aiListeningLabel}: $_interimVoice',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Container(
              constraints: const BoxConstraints(minHeight: 56),
              decoration: BoxDecoration(
                color: colors.isDark
                    ? const Color(0xFF141821)
                    : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _isFocused
                      ? colors.primary.withValues(alpha: 0.50)
                      : (colors.isDark
                          ? Colors.white.withValues(alpha: 0.09)
                          : colors.border),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: colors.isDark ? 0.34 : 0.06,
                    ),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: l10n.aiAttachLabel,
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      shape: const CircleBorder(),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: (disabled ||
                            widget.sending ||
                            widget.uploadingAttachment)
                        ? null
                        : () => CopilotComposer.showAttachmentSourceSheet(
                              context,
                              currentCount: widget.stagedAttachments.length,
                              onStage: widget.onStageAttachment,
                            ),
                    icon: widget.uploadingAttachment
                        ? SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.primary,
                            ),
                          )
                        : Icon(
                            LucideIcons.plus,
                            size: 22,
                            color: colors.textMuted,
                          ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      enabled: !disabled,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 4000,
                      textDirection: _composerDir,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      scrollPadding: const EdgeInsets.only(bottom: 24),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                            height: 1.38,
                          ),
                      decoration: InputDecoration(
                        hintText: disabled
                            ? (widget.isReadOnly
                                ? l10n.planReadOnlyTitle
                                : l10n.commonOfflineBanner)
                            : l10n.aiPlaceholder,
                        hintMaxLines: 1,
                        hintStyle: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: colors.textMuted,
                              fontSize: 15.5,
                              overflow: TextOverflow.ellipsis,
                            ),
                        counterText: '',
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (widget.sending)
                    IconButton(
                      tooltip: l10n.aiStop,
                      onPressed: widget.onStop,
                      constraints: const BoxConstraints.tightFor(
                        width: 40,
                        height: 40,
                      ),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: colors.isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : colors.dangerBg,
                        foregroundColor:
                            colors.isDark ? Colors.white : colors.danger,
                        shape: const CircleBorder(),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(LucideIcons.square, size: 15),
                    )
                  else if (canSend)
                    IconButton.filled(
                      tooltip: l10n.aiSend,
                      onPressed: widget.onSend,
                      style: IconButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(40, 40),
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(LucideIcons.arrowUp, size: 19),
                    )
                  else
                    VoiceDictationButton(
                      uiLocale: uiLocale,
                      disabled: disabled || widget.sending,
                      borderless: true,
                      onInterimChanged: (interim) {
                        if (mounted) {
                          setState(() => _interimVoice = interim);
                        }
                      },
                      onFinalTranscript: (transcript) {
                        final prev = widget.controller.text.trimRight();
                        widget.controller.text =
                            prev.isEmpty ? transcript : '$prev $transcript';
                        widget.controller.selection =
                            TextSelection.collapsed(
                          offset: widget.controller.text.length,
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyboardAwareBottomInset extends StatelessWidget {
  const _KeyboardAwareBottomInset({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(
        bottom:
            keyboardOpen ? 4.0 : (safeBottom > 0 ? safeBottom + 6.0 : 0.0),
      ),
      child: child,
    );
  }
}

class _AttachmentPickerSheetBody extends StatefulWidget {
  const _AttachmentPickerSheetBody({
    required this.parentContext,
    required this.currentCount,
    required this.onStage,
  });

  final BuildContext parentContext;
  final int currentCount;
  final StageAttachmentCallback onStage;

  @override
  State<_AttachmentPickerSheetBody> createState() =>
      _AttachmentPickerSheetBodyState();
}

class _AttachmentPickerSheetBodyState
    extends State<_AttachmentPickerSheetBody> {
  final _imagePicker = ImagePicker();
  bool _busy = false;

  Future<void> _handleImage(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      await _validateAndUpload(bytes: bytes, filename: picked.name);
    } catch (e) {
      if (mounted) AfabToast.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleDocument() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'pdf',
          'xlsx',
          'csv',
          'txt',
          'json',
          'md',
          'jpg',
          'jpeg',
          'png',
          'webp',
        ],
      );
      if (files.isEmpty) return;
      final first = files.first;
      final path = first.path;
      if (path == null || path.isEmpty) return;
      final bytes = await File(path).readAsBytes();
      await _validateAndUpload(bytes: bytes, filename: first.name);
    } catch (e) {
      if (mounted) AfabToast.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _validateAndUpload({
    required Uint8List bytes,
    required String filename,
  }) async {
    final validationError = AiAttachmentValidator.validate(
      bytes: bytes,
      filename: filename,
      currentlyStagedCount: widget.currentCount,
    );
    if (validationError != null) {
      if (mounted) AfabToast.showError(context, validationError);
      return;
    }

    final ok = await widget.onStage(
      bytes: bytes,
      filename: filename,
      contentType: AiAttachmentValidator.guessContentType(filename),
    );
    if (mounted && ok) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(LucideIcons.camera),
          title: Text(l10n.aiAttachCamera),
          onTap: _busy ? null : () => _handleImage(ImageSource.camera),
        ),
        ListTile(
          leading: const Icon(LucideIcons.image),
          title: Text(l10n.aiAttachGallery),
          onTap: _busy ? null : () => _handleImage(ImageSource.gallery),
        ),
        ListTile(
          leading: const Icon(LucideIcons.fileText),
          title: Text(l10n.aiAttachDocument),
          onTap: _busy ? null : _handleDocument,
        ),
      ],
    );
  }
}

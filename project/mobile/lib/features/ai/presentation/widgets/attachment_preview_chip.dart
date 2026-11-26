import 'dart:typed_data';

import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/ai/data/ai_dtos.dart';
import 'package:afab_mobile/features/ai/data/ai_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AttachmentPreviewChip extends ConsumerStatefulWidget {
  const AttachmentPreviewChip({
    super.key,
    required this.attachment,
    this.compact = false,
    this.onRemove,
  });

  final AiAttachmentDto attachment;
  final bool compact;
  final VoidCallback? onRemove;

  @override
  ConsumerState<AttachmentPreviewChip> createState() =>
      _AttachmentPreviewChipState();
}

class _AttachmentPreviewChipState extends ConsumerState<AttachmentPreviewChip> {
  Uint8List? _remoteBytes;

  @override
  void initState() {
    super.initState();
    _maybeLoadPreview();
  }

  @override
  void didUpdateWidget(covariant AttachmentPreviewChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachment.id != widget.attachment.id) {
      _remoteBytes = null;
      _maybeLoadPreview();
    }
  }

  Future<void> _maybeLoadPreview() async {
    if (!widget.attachment.isImage ||
        widget.attachment.localBytes != null ||
        widget.attachment.id.isEmpty) {
      return;
    }
    try {
      final bytes = await ref
          .read(aiRepositoryProvider)
          .fetchAttachmentPreview(widget.attachment.id);
      if (mounted && bytes.isNotEmpty) {
        setState(() => _remoteBytes = bytes);
      }
    } catch (_) {
      // Silently fall back to icon if preview cannot load.
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)}KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    final bytes = widget.attachment.localBytes ?? _remoteBytes;
    final thumbSize = widget.compact ? 26.0 : 34.0;

    return Container(
      constraints: BoxConstraints(maxWidth: widget.compact ? 200 : 240),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: thumbSize,
              height: thumbSize,
              color: colors.surfaceInset,
              alignment: Alignment.center,
              child: bytes != null
                  ? Image.memory(
                      bytes,
                      width: thumbSize,
                      height: thumbSize,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        LucideIcons.image,
                        size: 16,
                        color: colors.primary,
                      ),
                    )
                  : Icon(
                      widget.attachment.isImage
                          ? LucideIcons.image
                          : LucideIcons.fileText,
                      size: 16,
                      color: colors.primary,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.attachment.originalFilename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    _formatSize(widget.attachment.fileSizeBytes),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: colors.textMuted,
                        ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.onRemove != null) ...[
            const SizedBox(width: 4),
            IconButton(
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
              padding: EdgeInsets.zero,
              iconSize: 14,
              onPressed: widget.onRemove,
              icon: Icon(LucideIcons.x, color: colors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

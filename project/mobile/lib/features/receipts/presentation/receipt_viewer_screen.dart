import 'dart:io';

import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/receipts/data/receipt_dto.dart';
import 'package:afab_mobile/features/receipts/data/receipt_repository.dart';
import 'package:afab_mobile/features/receipts/domain/receipt_providers.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Screen `FIN-08` Viewer: Streams authenticated receipt bytes directly from
/// `GET /api/v1/receipts/{id}/content` (`Cache-Control: private, no-store`),
/// supports pinch-to-zoom on images, OS sharing for PDF/images, presigned link
/// copy, and delete with confirmation.
class ReceiptViewerScreen extends ConsumerStatefulWidget {
  const ReceiptViewerScreen({
    super.key,
    required this.transactionId,
    required this.receiptId,
    this.initialReceipt,
  });

  final String transactionId;
  final String receiptId;
  final ReceiptDto? initialReceipt;

  @override
  ConsumerState<ReceiptViewerScreen> createState() =>
      _ReceiptViewerScreenState();
}

class _ReceiptViewerScreenState extends ConsumerState<ReceiptViewerScreen> {
  bool _busyAction = false;

  Future<ReceiptDto?> _resolveMeta() async {
    if (widget.initialReceipt != null) return widget.initialReceipt;
    final list = ref
        .read(transactionReceiptsProvider(widget.transactionId))
        .value;
    if (list != null) {
      for (final r in list) {
        if (r.id == widget.receiptId) return r;
      }
    }
    return null;
  }

  Future<void> _shareFile(Uint8List bytes, ReceiptDto? meta) async {
    final l10n = context.l10n;
    setState(() => _busyAction = true);
    try {
      final rootDir = await getTemporaryDirectory();
      final cacheDir = Directory('${rootDir.path}/afab_receipts');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      final rawName = meta?.originalFilename ?? 'receipt_${widget.receiptId}';
      final safeName = rawName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final file = File('${cacheDir.path}/$safeName');
      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: meta?.contentType ?? 'application/octet-stream',
            ),
          ],
          subject: rawName,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AfabToast.showError(context, '${l10n.errorGenericTitle}: $e');
    } finally {
      if (mounted) setState(() => _busyAction = false);
    }
  }

  Future<void> _copyPresignedLink() async {
    final l10n = context.l10n;
    setState(() => _busyAction = true);
    try {
      final dto = await ref
          .read(receiptRepositoryProvider)
          .getDownloadUrl(widget.receiptId);
      await Clipboard.setData(ClipboardData(text: dto.url));
      if (!mounted) return;
      AfabToast.showSuccess(
        context,
        l10n.receiptsPresignedNotice(dto.expiresInSeconds),
      );
    } on AppFailure catch (e) {
      if (!mounted) return;
      AfabToast.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _busyAction = false);
    }
  }

  Future<void> _deleteReceipt(ReceiptDto? meta) async {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final filename = meta?.originalFilename ?? widget.receiptId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text(l10n.receiptsDeleteConfirmTitle),
        content: Text(l10n.receiptsDeleteConfirmDesc(filename)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.danger),
            onPressed: () => Navigator.of(dlgCtx).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyAction = true);
    try {
      await ref
          .read(transactionReceiptsProvider(widget.transactionId).notifier)
          .deleteReceipt(widget.receiptId);
      if (!mounted) return;
      AfabToast.showSuccess(context, l10n.receiptsDeletedToast);
      Navigator.of(context).pop();
    } on AppFailure catch (e) {
      if (!mounted) return;
      AfabToast.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _busyAction = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final isEditable = !(ref.watch(activeBusinessProvider)?.isReadOnly ?? false);
    final bytesAsync = ref.watch(receiptContentProvider(widget.receiptId));
    final receiptsList = ref
        .watch(transactionReceiptsProvider(widget.transactionId))
        .value;

    ReceiptDto? meta = widget.initialReceipt;
    if (meta == null && receiptsList != null) {
      for (final item in receiptsList) {
        if (item.id == widget.receiptId) {
          meta = item;
          break;
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF060813),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C101C),
        foregroundColor: Colors.white,
        title: Text(
          meta?.originalFilename ?? l10n.receiptsSectionTitle(1),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (bytesAsync.hasValue)
            IconButton(
              tooltip: l10n.receiptsShareAction,
              onPressed: _busyAction
                  ? null
                  : () => _shareFile(bytesAsync.value!, meta),
              icon: const Icon(LucideIcons.share2),
            ),
          IconButton(
            tooltip: l10n.receiptsCopyLinkAction,
            onPressed: _busyAction ? null : _copyPresignedLink,
            icon: const Icon(LucideIcons.copy),
          ),
          if (isEditable)
            IconButton(
              tooltip: l10n.commonDelete,
              onPressed: _busyAction ? null : () async {
                final resolved = await _resolveMeta();
                if (mounted) await _deleteReceipt(resolved);
              },
              icon: const Icon(LucideIcons.trash2, color: Color(0xFFF87171)),
            ),
        ],
      ),
      body: bytesAsync.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AfabLoader(),
              const SizedBox(height: 16),
              Text(
                l10n.receiptsViewerLoading,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AfabErrorState(
              title: l10n.errorGenericTitle,
              message: err.toString(),
              retryLabel: l10n.commonRetry,
              onRetry: () =>
                  ref.invalidate(receiptContentProvider(widget.receiptId)),
            ),
          ),
        ),
        data: (bytes) {
          final isPdf = meta?.isPdf ??
              (bytes.length >= 4 &&
                  bytes[0] == 0x25 &&
                  bytes[1] == 0x50 &&
                  bytes[2] == 0x44 &&
                  bytes[3] == 0x46);

          return Column(
            children: [
              Expanded(
                child: isPdf
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 420),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0C101C),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    LucideIcons.fileText,
                                    color: Color(0xFFF87171),
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.receiptsPdfReady,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: Colors.white),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.receiptsPdfHint,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.white70),
                                ),
                                const SizedBox(height: 20),
                                AfabButton(
                                  label: l10n.receiptsShareAction,
                                  icon: LucideIcons.share2,
                                  expand: true,
                                  isLoading: _busyAction,
                                  onPressed: () => _shareFile(bytes, meta),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 5.0,
                        child: Center(
                          child: Image.memory(
                            bytes,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => AfabEmptyState(
                              icon: LucideIcons.image,
                              title: l10n.errorGenericTitle,
                              description: l10n.receiptsInvalidType,
                            ),
                          ),
                        ),
                      ),
              ),
              if (meta != null)
                SafeArea(
                  top: false,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C101C),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AfabStatusBadge(
                          label: meta.shortTypeLabel,
                          variant: meta.isPdf
                              ? AfabBadgeVariant.danger
                              : AfabBadgeVariant.info,
                        ),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            meta.formattedSize,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.white70),
                          ),
                        ),
                        if (meta.createdAt != null)
                          Text(
                            AfabDateFormatter.formatRelativeTimestamp(
                              meta.createdAt,
                              locale,
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.white54),
                          ),
                        if (meta.sha256Checksum.isNotEmpty)
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              'SHA-256: ${meta.sha256Checksum.substring(0, meta.sha256Checksum.length > 16 ? 16 : meta.sha256Checksum.length)}…',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: Colors.white54),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

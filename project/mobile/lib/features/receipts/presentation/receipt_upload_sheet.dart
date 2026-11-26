import 'dart:io';

import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/receipts/data/receipt_validator.dart';
import 'package:afab_mobile/features/receipts/domain/receipt_providers.dart';
import 'package:afab_mobile/shared/widgets/afab_bottom_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<void> showReceiptUploadSheet(
  BuildContext context, {
  required String transactionId,
}) {
  final l10n = context.l10n;
  return showAfabBottomSheet<void>(
    context: context,
    title: l10n.receiptsSourceTitle,
    subtitle: l10n.receiptsSourceSubtitle,
    builder: (sheetCtx) => _ReceiptUploadBody(
      parentContext: context,
      transactionId: transactionId,
    ),
  );
}

class _ReceiptUploadBody extends ConsumerStatefulWidget {
  const _ReceiptUploadBody({
    required this.parentContext,
    required this.transactionId,
  });

  final BuildContext parentContext;
  final String transactionId;

  @override
  ConsumerState<_ReceiptUploadBody> createState() => _ReceiptUploadBodyState();
}

class _ReceiptUploadBodyState extends ConsumerState<_ReceiptUploadBody> {
  final _imagePicker = ImagePicker();
  bool _picking = false;

  Future<void> _pickImage(ImageSource source) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
      );
      if (picked == null || !mounted) return;
      await _validateAndUpload(path: picked.path, name: picked.name);
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    } catch (e) {
      if (mounted) {
        AfabToast.showError(context, '${context.l10n.errorGenericTitle}: $e');
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _pickFile() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      );
      if (files.isEmpty || !mounted) return;
      final first = files.first;
      final path = first.path;
      if (path == null || path.isEmpty) return;
      await _validateAndUpload(path: path, name: first.name);
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    } catch (e) {
      if (mounted) {
        AfabToast.showError(context, '${context.l10n.errorGenericTitle}: $e');
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _validateAndUpload({
    required String path,
    required String name,
  }) async {
    final l10n = context.l10n;
    final bytes = await File(path).readAsBytes();
    final check = ReceiptValidator.validateBytes(bytes);

    if (!check.isValid) {
      if (!mounted) return;
      final msg = switch (check.error!) {
        ReceiptValidationError.empty => l10n.receiptsEmptyFile,
        ReceiptValidationError.tooLarge => l10n.receiptsTooLarge,
        ReceiptValidationError.unsupportedType => l10n.receiptsInvalidType,
      };
      AfabToast.showError(context, msg);
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    try {
      await ref
          .read(receiptUploadControllerProvider(widget.transactionId).notifier)
          .upload(
            filePath: path,
            filename: name,
            detectedMime: check.mimeType!,
          );
      if (widget.parentContext.mounted) {
        AfabToast.showSuccess(widget.parentContext, l10n.receiptsUploadedToast);
      }
    } on AppFailure catch (e) {
      if (e.code == 'CANCELLED') return;
      if (widget.parentContext.mounted) {
        AfabToast.showError(widget.parentContext, e.message);
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      if (widget.parentContext.mounted) {
        AfabToast.showError(
          widget.parentContext,
          e.message ?? l10n.errorGenericDesc,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SourceTile(
          icon: LucideIcons.camera,
          title: l10n.receiptsTakePhoto,
          enabled: !_picking,
          onTap: () => _pickImage(ImageSource.camera),
        ),
        const SizedBox(height: 10),
        _SourceTile(
          icon: LucideIcons.image,
          title: l10n.receiptsChooseGallery,
          enabled: !_picking,
          onTap: () => _pickImage(ImageSource.gallery),
        ),
        const SizedBox(height: 10),
        _SourceTile(
          icon: LucideIcons.fileText,
          title: l10n.receiptsBrowseFile,
          enabled: !_picking,
          onTap: _pickFile,
        ),
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    return AfabCard(
      onTap: enabled ? onTap : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: colors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

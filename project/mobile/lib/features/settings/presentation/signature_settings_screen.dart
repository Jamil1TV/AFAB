import 'dart:io';
import 'dart:ui' as ui;

import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/business/domain/business_providers.dart';
import 'package:afab_mobile/features/settings/data/settings_dtos.dart';
import 'package:afab_mobile/features/settings/domain/signature_image_processor.dart';
import 'package:afab_mobile/features/settings/domain/signature_vault_provider.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:afab_mobile/shared/widgets/afab_segmented_bar.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

/// Screen `SET-06`: Device-Local Wet Signatures & Signatory Vault.
class SignatureSettingsScreen extends ConsumerWidget {
  const SignatureSettingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    const body = SignatureSettingsBody();
    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.signatureTitle)),
      body: body,
    );
  }
}

class SignatureSettingsBody extends ConsumerStatefulWidget {
  const SignatureSettingsBody({super.key});

  @override
  ConsumerState<SignatureSettingsBody> createState() =>
      _SignatureSettingsBodyState();
}

class _SignatureSettingsBodyState extends ConsumerState<SignatureSettingsBody> {
  final _labelCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();

  String _inputTab = 'draw'; // draw | upload
  Color _inkColor = const Color(0xFF0F172A);
  List<List<Offset>> _strokes = [];
  bool _drawingActive = false;

  Uint8List? _pendingInkBytes;
  bool _makeTransparent = true;
  bool _makeActiveOnSave = true;
  String? _editingId;
  bool _saving = false;
  bool _seeded = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  void _seedDefaultsIfNeeded() {
    if (_seeded) return;
    _seeded = true;
    final user = ref.read(authNotifierProvider).user;
    final biz = ref.read(activeBusinessProvider);
    _nameCtrl.text = user?.fullName ?? (biz?.name ?? '');
    _titleCtrl.text = 'Authorized Signatory';
    _labelCtrl.text = 'Primary Signature';
  }

  Future<Uint8List?> _renderPadToPngBytes(Size size) async {
    if (_strokes.isEmpty) return null;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = _inkColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in _strokes) {
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, 1.5, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
      } else if (stroke.length > 1) {
        final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
        for (var i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }

    final picture = recorder.endRecording();
    final image = picture.toImageSync(
      size.width.round().clamp(120, 1200),
      size.height.round().clamp(80, 600),
    );
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } finally {
      image.dispose();
      picture.dispose();
    }
  }

  Future<void> _useDrawing() async {
    if (_strokes.isEmpty) return;
    final bytes = await _renderPadToPngBytes(const Size(600, 200));
    if (bytes != null && mounted) {
      setState(() => _pendingInkBytes = bytes);
    }
  }

  Future<void> _handleRawUploadedBytes(Uint8List raw) async {
    if (raw.length > 5 * 1024 * 1024) {
      if (mounted) AfabToast.showError(context, context.l10n.signatureTooLarge);
      return;
    }
    final processed = await compute(
      processSignatureBytes,
      (rawBytes: raw, makeTransparent: _makeTransparent),
    );
    if (!mounted) return;
    setState(() {
      _pendingInkBytes = processed ?? raw;
    });
  }

  Future<void> _pickCameraOrFile({required bool camera}) async {
    try {
      if (camera) {
        final picked = await ImagePicker().pickImage(source: ImageSource.camera);
        if (picked == null) return;
        await _handleRawUploadedBytes(await picked.readAsBytes());
      } else {
        final files = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['png', 'jpg', 'jpeg'],
        );
        if (files.isEmpty || files.first.path == null) return;
        final bytes = await File(files.first.path!).readAsBytes();
        await _handleRawUploadedBytes(bytes);
      }
    } catch (e) {
      if (mounted) AfabToast.showError(context, e.toString());
    }
  }

  Future<void> _saveToVault(String businessId) async {
    var bytes = _pendingInkBytes;
    if (bytes == null && _strokes.isNotEmpty) {
      bytes = await _renderPadToPngBytes(const Size(600, 200));
    }
    if (bytes == null || _saving) return;

    setState(() => _saving = true);
    try {
      await ref.read(signatureVaultProvider(businessId).notifier).saveSignature(
            editingId: _editingId,
            pngBytes: bytes,
            label: _labelCtrl.text,
            signatoryName: _nameCtrl.text,
            signatoryTitle: _titleCtrl.text,
            makeActive: _makeActiveOnSave,
          );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _editingId = null;
        _strokes = [];
        _pendingInkBytes = null;
      });
      AfabToast.showSuccess(context, context.l10n.signatureSavedToast);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AfabToast.showError(context, e.toString());
      }
    }
  }

  void _startEdit(SignatureItem item) async {
    Uint8List? existing;
    try {
      final f = File(item.filePath);
      if (f.existsSync()) existing = await f.readAsBytes();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _editingId = item.id;
      _labelCtrl.text = item.label;
      _nameCtrl.text = item.signatoryName;
      _titleCtrl.text = item.signatoryTitle;
      _makeActiveOnSave = item.isDefault;
      _pendingInkBytes = existing;
    });
  }

  Future<void> _confirmDelete(String businessId, SignatureItem item) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signatureDeleteConfirm(item.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(signatureVaultProvider(businessId).notifier)
          .deleteSignature(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final biz = ref.watch(activeBusinessProvider);
    final businessId = biz?.id ?? 'default';
    final registry = ref.watch(signatureVaultProvider(businessId));

    _seedDefaultsIfNeeded();

    final editorCard = AfabCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_editingId != null) ...[
            AfabInsetPanel(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.signatureEditingBanner(_labelCtrl.text),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _editingId = null;
                      _pendingInkBytes = null;
                      _strokes = [];
                    }),
                    child: Text(l10n.commonCancel),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          AfabSegmentedBar<String>(
            items: [
              AfabSegmentItem(value: 'draw', label: l10n.signatureTabDraw),
              AfabSegmentItem(value: 'upload', label: l10n.signatureTabUpload),
            ],
            selectedValue: _inputTab,
            onSelected: (v) => setState(() => _inputTab = v),
          ),
          const SizedBox(height: 14),
          if (_inputTab == 'draw') ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ChoiceChip(
                  label: Text(l10n.signatureInkBlack),
                  selected: _inkColor == const Color(0xFF0F172A),
                  onSelected: (_) =>
                      setState(() => _inkColor = const Color(0xFF0F172A)),
                ),
                ChoiceChip(
                  label: Text(l10n.signatureInkBlue),
                  selected: _inkColor == const Color(0xFF1D4ED8),
                  onSelected: (_) =>
                      setState(() => _inkColor = const Color(0xFF1D4ED8)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Keep canvas light paper (#F8FAFC) in both light & dark modes so dark ink is visible.
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: GestureDetector(
                  key: const ValueKey('signature_draw_pad'),
                  onPanStart: (details) => setState(() {
                    _drawingActive = true;
                    _strokes = [..._strokes, [details.localPosition]];
                  }),
                  onPanUpdate: (details) => setState(() {
                    if (_strokes.isEmpty) return;
                    final current = List<Offset>.from(_strokes.last)
                      ..add(details.localPosition);
                    _strokes = [
                      ..._strokes.sublist(0, _strokes.length - 1),
                      current,
                    ];
                  }),
                  onPanEnd: (_) => setState(() => _drawingActive = false),
                  child: CustomPaint(
                    painter: _SignaturePadPainter(
                      strokes: _strokes,
                      inkColor: _inkColor,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AfabButton(
                  label: l10n.signatureResetPad,
                  variant: AfabButtonVariant.secondary,
                  compact: true,
                  onPressed: () => setState(() {
                    _strokes = [];
                    _pendingInkBytes = null;
                  }),
                ),
                AfabButton(
                  label: l10n.signatureUseDrawing,
                  icon: LucideIcons.check,
                  variant: AfabButtonVariant.soft,
                  compact: true,
                  onPressed: _strokes.isEmpty ? null : _useDrawing,
                ),
              ],
            ),
          ] else ...[
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                AfabButton(
                  label: l10n.signatureTakePhoto,
                  icon: LucideIcons.camera,
                  variant: AfabButtonVariant.secondary,
                  compact: true,
                  onPressed: () => _pickCameraOrFile(camera: true),
                ),
                AfabButton(
                  label: l10n.signatureChooseFile,
                  icon: LucideIcons.image,
                  variant: AfabButtonVariant.primary,
                  compact: true,
                  onPressed: () => _pickCameraOrFile(camera: false),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _makeTransparent,
              onChanged: (v) => setState(() => _makeTransparent = v ?? true),
              title: Text(
                l10n.signatureTransparentBg,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
          if (_pendingInkBytes != null) ...[
            const SizedBox(height: 10),
            Container(
              height: 88,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: Image.memory(_pendingInkBytes!, fit: BoxFit.contain),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _labelCtrl,
            decoration: InputDecoration(labelText: l10n.signatureLabelField),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l10n.signatureSignatoryName),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleCtrl,
            onChanged: (_) => setState(() {}),
            decoration:
                InputDecoration(labelText: l10n.signatureSignatoryTitle),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _makeActiveOnSave,
            onChanged: (v) => setState(() => _makeActiveOnSave = v ?? true),
            title: Text(
              l10n.signatureSetDefaultCheck,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: registry.autoApply,
            onChanged: (v) => ref
                .read(signatureVaultProvider(businessId).notifier)
                .setAutoApply(v),
            title: Text(
              l10n.signatureAutoApplySwitch,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 10),
          AfabButton(
            label: _editingId != null
                ? l10n.signatureUpdateVaultBtn
                : l10n.signatureSaveVaultBtn,
            variant: AfabButtonVariant.primary,
            expand: true,
            isLoading: _saving,
            onPressed: (_pendingInkBytes != null || _strokes.isNotEmpty) && !_saving
                ? () => _saveToVault(businessId)
                : null,
          ),
        ],
      ),
    );

    final activeItem = registry.activeSignature;
    Uint8List? activeFileBytes = _pendingInkBytes;
    if (activeFileBytes == null && activeItem != null) {
      try {
        final f = File(activeItem.filePath);
        if (f.existsSync()) activeFileBytes = f.readAsBytesSync();
      } catch (_) {}
    }

    final previewCard = AfabCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.signaturePreviewTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              AfabStatusBadge(
                label: l10n.signatureCertifiedStamp,
                variant: AfabBadgeVariant.success,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  biz?.name ?? 'AFAB Workspace',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 70,
                  child: activeFileBytes != null
                      ? Image.memory(activeFileBytes, fit: BoxFit.contain)
                      : Center(
                          child: Text(
                            l10n.signatureEmptyTitle,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ),
                ),
                const Divider(color: Color(0xFFCBD5E1)),
                Text(
                  _nameCtrl.text.trim().isNotEmpty
                      ? _nameCtrl.text.trim()
                      : (activeItem?.signatoryName ?? ''),
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  _titleCtrl.text.trim().isNotEmpty
                      ? _titleCtrl.text.trim()
                      : (activeItem?.signatoryTitle ?? ''),
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;
        return SingleChildScrollView(
          physics: _drawingActive
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Honest Device-Local Notice
                  AfabInsetPanel(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.hardDrive,
                          size: 17,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.signatureDeviceLocalNotice,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AfabStatusBadge(
                          label: l10n.signatureSavedCount(
                            registry.signatures.length,
                          ),
                          variant: AfabBadgeVariant.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Saved Vault
                  AfabCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.signatureVaultTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        if (registry.signatures.isEmpty)
                          AfabEmptyState(
                            icon: LucideIcons.penTool,
                            title: l10n.signatureEmptyTitle,
                            description: l10n.signatureEmptyDesc,
                          )
                        else
                          for (final item in registry.signatures) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _SignatureVaultTile(
                                item: item,
                                isActive: registry.activeSignature?.id == item.id,
                                onSetActive: () => ref
                                    .read(signatureVaultProvider(businessId)
                                        .notifier)
                                    .setActive(item.id),
                                onEdit: () => _startEdit(item),
                                onShare: () async {
                                  if (item.filePath.isNotEmpty) {
                                    await SharePlus.instance.share(
                                      ShareParams(
                                        files: [
                                          XFile(
                                            item.filePath,
                                            mimeType: 'image/png',
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                                onDelete: () =>
                                    _confirmDelete(businessId, item),
                              ),
                            ),
                          ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: editorCard),
                        const SizedBox(width: 16),
                        Expanded(flex: 5, child: previewCard),
                      ],
                    )
                  else ...[
                    editorCard,
                    const SizedBox(height: 16),
                    previewCard,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SignaturePadPainter extends CustomPainter {
  _SignaturePadPainter({required this.strokes, required this.inkColor});

  final List<List<Offset>> strokes;
  final Color inkColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = inkColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final s in strokes) {
      if (s.isEmpty) continue;
      if (s.length == 1) {
        canvas.drawCircle(
          s.first,
          1.5,
          Paint()..color = inkColor,
        );
      } else {
        final path = Path()..moveTo(s.first.dx, s.first.dy);
        for (var i = 1; i < s.length; i++) {
          path.lineTo(s[i].dx, s[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePadPainter oldDelegate) =>
      oldDelegate.strokes != strokes || oldDelegate.inkColor != inkColor;
}

class _SignatureVaultTile extends StatelessWidget {
  const _SignatureVaultTile({
    required this.item,
    required this.isActive,
    required this.onSetActive,
    required this.onEdit,
    required this.onShare,
    required this.onDelete,
  });

  final SignatureItem item;
  final bool isActive;
  final VoidCallback onSetActive;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    Uint8List? bytes;
    try {
      final f = File(item.filePath);
      if (f.existsSync()) bytes = f.readAsBytesSync();
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceInset,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? colors.success : colors.border,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    '${item.signatoryName} · ${item.signatoryTitle}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (isActive)
                AfabStatusBadge(
                  label: l10n.signatureActiveBadge,
                  variant: AfabBadgeVariant.success,
                )
              else
                OutlinedButton(
                  onPressed: onSetActive,
                  child: Text(l10n.signatureSetActive),
                ),
            ],
          ),
          if (bytes != null) ...[
            const SizedBox(height: 10),
            Container(
              height: 84,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(LucideIcons.pencil, size: 14),
                label: Text(l10n.commonEdit),
              ),
              TextButton.icon(
                onPressed: onShare,
                icon: const Icon(LucideIcons.share2, size: 14),
                label: const Text('PNG'),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: Icon(LucideIcons.trash2, size: 14, color: colors.danger),
                label: Text(
                  l10n.commonDelete,
                  style: TextStyle(color: colors.danger),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

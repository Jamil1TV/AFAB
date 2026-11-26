import 'dart:convert';

import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/responsive.dart';
import 'package:afab_mobile/features/auth/data/auth_dtos.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/settings/data/settings_repository.dart';
import 'package:afab_mobile/shared/widgets/afab_bottom_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Compresses raw image bytes into a `<= 256x256` JPEG `data:image/jpeg;base64,...`
/// string safely below the backend `@Size(max = 500000)` limit.
String? compressAvatarToDataUri(Uint8List rawBytes) {
  final decoded = img.decodeImage(rawBytes);
  if (decoded == null) return null;
  final resized = decoded.width > 256 || decoded.height > 256
      ? img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? 256 : null,
          height: decoded.height > decoded.width ? 256 : null,
        )
      : decoded;

  for (final quality in [85, 70, 50, 35]) {
    final jpg = img.encodeJpg(resized, quality: quality);
    final uri = 'data:image/jpeg;base64,${base64Encode(jpg)}';
    if (uri.length <= 490000) return uri;
  }
  return null;
}

Future<UserProfile?> showEditProfileSheet(
  BuildContext context, {
  required UserProfile profile,
}) {
  final isTablet = !AfabBreakpoints.isPhone(MediaQuery.sizeOf(context).width);
  if (isTablet) {
    return showDialog<UserProfile>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520, maxHeight: 740),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _EditProfileBody(profile: profile),
          ),
        ),
      ),
    );
  }

  return showAfabBottomSheet<UserProfile>(
    context: context,
    title: context.l10n.editProfileTitle,
    builder: (ctx) => _EditProfileBody(profile: profile),
  );
}

class _EditProfileBody extends ConsumerStatefulWidget {
  const _EditProfileBody({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_EditProfileBody> createState() => _EditProfileBodyState();
}

class _EditProfileBodyState extends ConsumerState<_EditProfileBody> {
  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  late final TextEditingController _phoneCtrl;
  String? _avatarUrl;
  String? _firstError;
  String? _lastError;
  String? _phoneError;
  bool _saving = false;

  static const _presetStyles = [
    'avataaars',
    'notionists',
    'lorelei',
    'thumbs',
    'initials',
  ];

  @override
  void initState() {
    super.initState();
    _firstCtrl = TextEditingController(text: widget.profile.firstName);
    _lastCtrl = TextEditingController(text: widget.profile.lastName);
    _phoneCtrl = TextEditingController(text: widget.profile.phoneNumber ?? '');
    _avatarUrl = widget.profile.avatarUrl;
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _presetUrl(String style) {
    final seed = Uri.encodeComponent(
      widget.profile.email.isNotEmpty
          ? widget.profile.email
          : widget.profile.fullName,
    );
    return 'https://api.dicebear.com/7.x/$style/png?seed=$seed';
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final dataUri = await compute(compressAvatarToDataUri, bytes);
      if (!mounted) return;
      if (dataUri == null) {
        AfabToast.showError(context, context.l10n.editProfileInvalidPhoto);
        return;
      }
      setState(() => _avatarUrl = dataUri);
    } catch (_) {
      if (mounted) {
        AfabToast.showError(context, context.l10n.editProfileInvalidPhoto);
      }
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final first = _firstCtrl.text.trim();
    final last = _lastCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    setState(() {
      _firstError = first.isEmpty ? l10n.authFieldRequired : null;
      _lastError = last.isEmpty ? l10n.authFieldRequired : null;
      _phoneError = null;
    });
    if (_firstError != null || _lastError != null) return;

    setState(() => _saving = true);
    try {
      final updated = await ref.read(settingsRepositoryProvider).updateProfile({
        'firstName': first,
        'lastName': last,
        'phoneNumber': phone,
        'avatarUrl': _avatarUrl ?? '',
      });
      await ref.read(authNotifierProvider.notifier).updateCachedUser(updated);
      if (mounted) {
        AfabToast.showSuccess(context, l10n.editProfileSaved);
        Navigator.of(context).pop(updated);
      }
    } on AppFailure catch (e) {
      if (!mounted) return;
      final code = e.code.toUpperCase();
      if (code == 'PHONE_TAKEN') {
        setState(() => _phoneError = e.message);
      } else if (code == 'INVALID_FIRST_NAME') {
        setState(() => _firstError = e.message);
      } else if (code == 'INVALID_LAST_NAME') {
        setState(() => _lastError = e.message);
      } else {
        AfabToast.showError(context, e.message);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildAvatarPreview(AfabColors colors, double size) {
    final url = _avatarUrl;
    if (url != null && url.startsWith('data:image/')) {
      final comma = url.indexOf(',');
      if (comma > 0) {
        try {
          final bytes = base64Decode(url.substring(comma + 1));
          return ClipOval(
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          );
        } catch (_) {}
      }
    }
    if (url != null && url.startsWith('http')) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => _initialsCircle(colors, size),
        ),
      );
    }
    return _initialsCircle(colors, size);
  }

  Widget _initialsCircle(AfabColors colors, double size) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colors.primary.withValues(alpha: 0.14),
      child: Text(
        widget.profile.initials,
        style: TextStyle(
          color: colors.primary,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _buildAvatarPreview(colors, 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AfabButton(
                        label: l10n.editProfileUploadPhoto,
                        icon: LucideIcons.upload,
                        variant: AfabButtonVariant.secondary,
                        compact: true,
                        onPressed: _saving ? null : _pickPhoto,
                      ),
                      if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                        AfabButton(
                          label: l10n.editProfileRemovePhoto,
                          variant: AfabButtonVariant.ghost,
                          compact: true,
                          onPressed: _saving
                              ? null
                              : () => setState(() => _avatarUrl = ''),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.editProfilePresetAvatars,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                for (final style in _presetStyles)
                  InkWell(
                    onTap: _saving
                        ? null
                        : () => setState(() => _avatarUrl = _presetUrl(style)),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _avatarUrl == _presetUrl(style)
                              ? colors.primary
                              : colors.border,
                          width: _avatarUrl == _presetUrl(style) ? 2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CachedNetworkImage(
                        imageUrl: _presetUrl(style),
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Icon(
                          LucideIcons.user,
                          size: 18,
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _firstCtrl,
              decoration: InputDecoration(
                labelText: l10n.editProfileFirstName,
                errorText: _firstError,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastCtrl,
              decoration: InputDecoration(
                labelText: l10n.editProfileLastName,
                errorText: _lastError,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.editProfilePhone,
                  errorText: _phoneError,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceInset,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.editProfileEmailReadOnly,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 2),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            widget.profile.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.profile.emailVerified) ...[
                    const SizedBox(width: 8),
                    AfabStatusBadge(
                      label: l10n.editProfileVerified,
                      variant: AfabBadgeVariant.success,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                AfabButton(
                  label: l10n.commonCancel,
                  variant: AfabButtonVariant.secondary,
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                ),
                AfabButton(
                  label: l10n.editProfileSave,
                  variant: AfabButtonVariant.primary,
                  isLoading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

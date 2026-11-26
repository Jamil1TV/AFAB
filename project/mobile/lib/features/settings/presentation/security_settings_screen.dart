import 'dart:io';

import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/utils/date_formatter.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/settings/data/settings_dtos.dart';
import 'package:afab_mobile/features/settings/data/settings_repository.dart';
import 'package:afab_mobile/features/settings/domain/biometric_lock_service.dart';
import 'package:afab_mobile/features/settings/domain/settings_providers.dart';
import 'package:afab_mobile/shared/widgets/afab_bottom_sheet.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:afab_mobile/shared/widgets/password_strength_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr/qr.dart';
import 'package:share_plus/share_plus.dart';

/// Screen `SET-04`: Password (with forced re-login), 2FA Setup/Manage,
/// Native Biometric App Lock, and Active Sessions (omits fake Login Alerts & Contact Support).
class SecuritySettingsScreen extends ConsumerWidget {
  const SecuritySettingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    const body = SecuritySettingsBody();
    if (embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.securityTitle)),
      body: body,
    );
  }
}

class SecuritySettingsBody extends ConsumerStatefulWidget {
  const SecuritySettingsBody({super.key});

  @override
  ConsumerState<SecuritySettingsBody> createState() =>
      _SecuritySettingsBodyState();
}

class _SecuritySettingsBodyState extends ConsumerState<SecuritySettingsBody> {
  bool _biometricSupported = false;
  bool _biometricEnabled = false;
  bool _loadingBio = true;
  bool _revokingAll = false;
  String? _revokingId;

  @override
  void initState() {
    super.initState();
    _loadBiometrics();
  }

  Future<void> _loadBiometrics() async {
    final svc = ref.read(biometricLockServiceProvider);
    final supported = await svc.isSupportedAndEnrolled();
    final enabled = await svc.isEnabled();
    if (!mounted) return;
    setState(() {
      _biometricSupported = supported;
      _biometricEnabled = enabled;
      _loadingBio = false;
    });
  }

  Future<void> _toggleBiometric(bool next) async {
    final svc = ref.read(biometricLockServiceProvider);
    if (next) {
      final ok = await svc.authenticate(context.l10n.securityBiometricPrompt);
      if (!ok || !mounted) return;
    }
    await svc.setEnabled(next);
    if (!mounted) return;
    setState(() => _biometricEnabled = next);
    ref.invalidate(biometricLockEnabledProvider);
  }

  Future<void> _openChangePassword() async {
    final changed = await showAfabBottomSheet<bool>(
      context: context,
      title: context.l10n.securityChangePasswordBtn,
      builder: (_) => const _ChangePasswordSheet(),
    );
    if (changed == true && mounted) {
      await ref.read(biometricLockServiceProvider).clearFlag();
      await ref.read(authNotifierProvider.notifier).forceLocalLogout();
      if (mounted) {
        AfabToast.showSuccess(context, context.l10n.securityChangePwdSuccess);
        context.go('/login');
      }
    }
  }

  Future<void> _openTwoFactorSetup() async {
    final updated = await showAfabBottomSheet<bool>(
      context: context,
      title: context.l10n.securitySetup2faTitle,
      builder: (_) => const _TwoFactorSetupSheet(),
    );
    if (updated == true && mounted) {
      await ref.read(authNotifierProvider.notifier).refreshProfile();
    }
  }

  Future<void> _openTwoFactorManage() async {
    final updated = await showAfabBottomSheet<bool>(
      context: context,
      title: context.l10n.securityManage2faTitle,
      builder: (_) => const _TwoFactorManageSheet(),
    );
    if (updated == true && mounted) {
      await ref.read(authNotifierProvider.notifier).refreshProfile();
    }
  }

  Future<void> _revokeSingleSession(SessionDto session) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.securityRevokeSessionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.navLogout),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _revokingId = session.id);
    try {
      await ref.read(settingsRepositoryProvider).revokeSession(session.id);
      ref.invalidate(activeSessionsProvider);
    } on AppFailure catch (e) {
      if (mounted) AfabToast.showError(context, e.message);
    } finally {
      if (mounted) setState(() => _revokingId = null);
    }
  }

  Future<void> _revokeAllSessions() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.securityLogOutAllTitle),
        content: Text(l10n.securityLogOutAllDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.securityLogOutAllBtn),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _revokingAll = true);
    try {
      await ref.read(settingsRepositoryProvider).revokeAllSessions();
      await ref.read(biometricLockServiceProvider).clearFlag();
      await ref.read(authNotifierProvider.notifier).forceLocalLogout();
      if (mounted) context.go('/login');
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() => _revokingAll = false);
        AfabToast.showError(context, e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final locale = Localizations.localeOf(context).languageCode;
    final user = ref.watch(authNotifierProvider).user;
    final sessionsAsync = ref.watch(activeSessionsProvider);
    final twoFactorOn = user?.twoFactorEnabled ?? false;

    final pwdDateStr = user?.passwordChangedAt != null
        ? l10n.securityPasswordChanged(
            AfabDateFormatter.formatDateTime(
              user!.passwordChangedAt!,
              locale: locale,
            ),
          )
        : l10n.securityPasswordStrong;

    final mainCol = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Security Overview Card
        AfabCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: twoFactorOn ? colors.successBg : colors.warningBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      twoFactorOn
                          ? LucideIcons.shieldCheck
                          : LucideIcons.shieldAlert,
                      size: 20,
                      color: twoFactorOn ? colors.success : colors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      twoFactorOn
                          ? l10n.securityOverviewSecure
                          : l10n.securityOverviewRecommend,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AfabStatusBadge(
                    label:
                        '${l10n.securityTwoFactorLabel}: ${twoFactorOn ? l10n.settingsBadge2faOn : l10n.settingsBadge2faOff}',
                    variant: twoFactorOn
                        ? AfabBadgeVariant.success
                        : AfabBadgeVariant.warning,
                  ),
                  AfabStatusBadge(
                    label: '${l10n.securityPasswordLabel}: $pwdDateStr',
                    variant: AfabBadgeVariant.neutral,
                  ),
                  AfabStatusBadge(
                    label: l10n.securityActiveSessionsCount(
                      sessionsAsync.value?.length ?? 0,
                    ),
                    variant: AfabBadgeVariant.info,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Password, 2FA & Biometrics Card
        AfabCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.keyRound, size: 18, color: colors.primary),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.securityPasswordLabel,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            pwdDateStr,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  AfabButton(
                    label: l10n.securityChangePasswordBtn,
                    variant: AfabButtonVariant.secondary,
                    compact: true,
                    onPressed: _openChangePassword,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: colors.border),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.lock, size: 18, color: colors.primary),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.securityTwoFactorLabel,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          AfabStatusBadge(
                            label: twoFactorOn
                                ? l10n.settingsBadge2faOn
                                : l10n.settingsBadge2faOff,
                            variant: twoFactorOn
                                ? AfabBadgeVariant.success
                                : AfabBadgeVariant.warning,
                          ),
                        ],
                      ),
                    ],
                  ),
                  AfabButton(
                    label: twoFactorOn
                        ? l10n.securityManage2faBtn
                        : l10n.securityEnable2faBtn,
                    variant: twoFactorOn
                        ? AfabButtonVariant.secondary
                        : AfabButtonVariant.primary,
                    compact: true,
                    onPressed:
                        twoFactorOn ? _openTwoFactorManage : _openTwoFactorSetup,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: colors.border),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  LucideIcons.fingerprint,
                  size: 20,
                  color: colors.primary,
                ),
                value: _biometricEnabled,
                onChanged: (_loadingBio || !_biometricSupported)
                    ? null
                    : _toggleBiometric,
                title: Text(l10n.securityBiometricTitle),
                subtitle: Text(
                  _biometricSupported
                      ? l10n.securityBiometricSub
                      : l10n.securityBiometricUnavailable,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Active Sessions Card
        AfabCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    l10n.securitySessionsTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  AfabButton(
                    label: l10n.securityLogOutAllBtn,
                    variant: AfabButtonVariant.danger,
                    compact: true,
                    isLoading: _revokingAll,
                    onPressed: _revokingAll ? null : _revokeAllSessions,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AfabInsetPanel(
                padding: const EdgeInsets.all(10),
                child: Text(
                  l10n.securitySessionCaveatNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 12),
              sessionsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: AfabLoader(size: 36)),
                ),
                error: (e, _) => Row(
                  children: [
                    Expanded(child: Text(e.toString())),
                    TextButton(
                      onPressed: () => ref.invalidate(activeSessionsProvider),
                      child: Text(l10n.commonRetry),
                    ),
                  ],
                ),
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return Text(
                      l10n.securityNoSessions,
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  }
                  return Column(
                    children: [
                      for (final s in sessions) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AfabInsetPanel(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.smartphone,
                                  size: 18,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (s.deviceInfo?.isNotEmpty == true)
                                            ? s.deviceInfo!
                                            : 'Unknown Device',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                      if (s.ipAddress != null &&
                                          s.ipAddress!.isNotEmpty)
                                        Directionality(
                                          textDirection: TextDirection.ltr,
                                          child: Text(
                                            s.ipAddress!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ),
                                      if (s.createdAt != null)
                                        Text(
                                          AfabDateFormatter
                                              .formatRelativeTimestamp(
                                            s.createdAt,
                                            locale,
                                          ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall,
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: l10n.navLogout,
                                  onPressed: _revokingId == s.id
                                      ? null
                                      : () => _revokeSingleSession(s),
                                  icon: Icon(
                                    LucideIcons.trash2,
                                    size: 17,
                                    color: colors.danger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );

    final tipsCard = AfabCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.securityTipsTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          _TipRow(
            title: l10n.securityTip1Title,
            desc: l10n.securityTip1Desc,
            checked: true,
          ),
          const SizedBox(height: 10),
          _TipRow(
            title: l10n.securityTip2Title,
            desc: l10n.securityTip2Desc,
            checked: twoFactorOn,
          ),
          const SizedBox(height: 10),
          _TipRow(
            title: l10n.securityTip3Title,
            desc: l10n.securityTip3Desc,
            checked: true,
          ),
          const SizedBox(height: 10),
          _TipRow(
            title: l10n.securityTip4Title,
            desc: l10n.securityTip4Desc,
            checked: twoFactorOn,
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: mainCol),
                        const SizedBox(width: 16),
                        Expanded(child: tipsCard),
                      ],
                    )
                  : Column(
                      children: [
                        mainCol,
                        const SizedBox(height: 16),
                        tipsCard,
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({
    required this.title,
    required this.desc,
    required this.checked,
  });

  final String title;
  final String desc;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    final colors = context.afabColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          checked ? LucideIcons.circleCheck : LucideIcons.circleAlert,
          size: 16,
          color: checked ? colors.success : colors.warning,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 2),
              Text(desc, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCur = true;
  bool _obscureNew = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final cur = _currentCtrl.text;
    final next = _newCtrl.text;
    final conf = _confirmCtrl.text;
    if (cur.isEmpty || next.length < 8) {
      setState(() => _error = l10n.authPwReqLength);
      return;
    }
    if (next != conf) {
      setState(() => _error = l10n.authResetPasswordMismatch);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(settingsRepositoryProvider).changePassword(
            currentPassword: cur,
            newPassword: next,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AfabInsetPanel(
            borderColor: colors.warning.withValues(alpha: 0.4),
            padding: const EdgeInsets.all(10),
            child: Text(
              l10n.securityChangePwdWarning,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _currentCtrl,
              obscureText: _obscureCur,
              decoration: InputDecoration(
                labelText: l10n.securityCurrentPwd,
                suffixIcon: IconButton(
                  icon: Icon(_obscureCur ? LucideIcons.eye : LucideIcons.eyeOff),
                  onPressed: () => setState(() => _obscureCur = !_obscureCur),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _newCtrl,
              obscureText: _obscureNew,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.securityNewPwd,
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? LucideIcons.eye : LucideIcons.eyeOff),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          PasswordStrengthIndicator(password: _newCtrl.text),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _confirmCtrl,
              obscureText: _obscureNew,
              decoration: InputDecoration(labelText: l10n.securityConfirmPwd),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.danger),
            ),
          ],
          const SizedBox(height: 16),
          AfabButton(
            label: l10n.securityChangePasswordBtn,
            variant: AfabButtonVariant.primary,
            expand: true,
            isLoading: _saving,
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _TwoFactorSetupSheet extends ConsumerStatefulWidget {
  const _TwoFactorSetupSheet();

  @override
  ConsumerState<_TwoFactorSetupSheet> createState() =>
      _TwoFactorSetupSheetState();
}

class _TwoFactorSetupSheetState extends ConsumerState<_TwoFactorSetupSheet> {
  TwoFactorSetupDto? _setup;
  String? _error;
  bool _loading = true;
  int _step = 1;
  final _codeCtrl = TextEditingController();
  bool _verifying = false;
  String? _verifyError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final setup = await ref.read(settingsRepositoryProvider).setupTwoFactor();
      if (mounted) {
        setState(() {
          _setup = setup;
          _loading = false;
        });
      }
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    }
  }

  Future<void> _verifyAndEnable() async {
    final setup = _setup;
    final code = _codeCtrl.text.trim();
    if (setup == null || !RegExp(r'^[0-9]{6}$').hasMatch(code)) {
      setState(() => _verifyError = context.l10n.security2faStep2Desc);
      return;
    }
    setState(() {
      _verifying = true;
      _verifyError = null;
    });
    try {
      await ref.read(settingsRepositoryProvider).enableTwoFactor(
            secret: setup.secret,
            code: code,
            backupCodes: setup.backupCodes,
          );
      if (mounted) {
        setState(() {
          _verifying = false;
          _step = 3;
        });
      }
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() {
          _verifying = false;
          _verifyError = e.message;
        });
      }
    }
  }

  Future<void> _shareBackupCodes(List<String> codes) async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/afab-recovery-codes.txt');
    await f.writeAsString(codes.join('\n'));
    await SharePlus.instance.share(
      ShareParams(files: [XFile(f.path, mimeType: 'text/plain')]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: AfabLoader(size: 40)),
      );
    }

    if (_error != null || _setup == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error ?? l10n.errorGenericTitle),
          const SizedBox(height: 12),
          AfabButton(label: l10n.commonRetry, onPressed: _load),
        ],
      );
    }

    final setup = _setup!;
    if (_step == 1) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.security2faStep1Desc,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          Center(
            child: Semantics(
              label: l10n.securityTwoFactorLabel,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _QrCodeWidget(data: setup.qrCodeUri, size: 170),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.ltr,
            child: SelectableText(
              setup.secret,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: setup.secret));
                  AfabToast.showSuccess(context, l10n.securityCopySecret);
                },
                icon: const Icon(LucideIcons.copy, size: 14),
                label: Text(l10n.securityCopySecret),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AfabButton(
            label: l10n.commonContinue,
            variant: AfabButtonVariant.primary,
            expand: true,
            onPressed: () => setState(() => _step = 2),
          ),
        ],
      );
    }

    if (_step == 2) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.security2faStep2Desc,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  letterSpacing: 6,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: '000000',
                  counterText: '',
                  errorText: _verifyError,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AfabButton(
              label: l10n.security2faVerifyEnable,
              variant: AfabButtonVariant.primary,
              expand: true,
              isLoading: _verifying,
              onPressed: _verifying ? null : _verifyAndEnable,
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.security2faBackupTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.security2faBackupDesc,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in setup.backupCodes)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceInset,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    c,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: setup.backupCodes.join('\n')),
                );
                AfabToast.showSuccess(context, l10n.securityCopyAllCodes);
              },
              icon: const Icon(LucideIcons.copy, size: 14),
              label: Text(l10n.securityCopyAllCodes),
            ),
            TextButton.icon(
              onPressed: () => _shareBackupCodes(setup.backupCodes),
              icon: const Icon(LucideIcons.share2, size: 14),
              label: Text(l10n.securityShareTxt),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AfabButton(
          label: l10n.commonClose,
          variant: AfabButtonVariant.primary,
          expand: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

class _TwoFactorManageSheet extends ConsumerStatefulWidget {
  const _TwoFactorManageSheet();

  @override
  ConsumerState<_TwoFactorManageSheet> createState() =>
      _TwoFactorManageSheetState();
}

class _TwoFactorManageSheetState extends ConsumerState<_TwoFactorManageSheet> {
  List<String>? _newCodes;
  final _pwdCtrl = TextEditingController();
  bool _regenBusy = false;
  bool _disableBusy = false;
  String? _disableError;

  @override
  void dispose() {
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _regenerate() async {
    setState(() => _regenBusy = true);
    try {
      final codes =
          await ref.read(settingsRepositoryProvider).regenerateBackupCodes();
      if (mounted) {
        setState(() {
          _newCodes = codes;
          _regenBusy = false;
        });
      }
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() => _regenBusy = false);
        AfabToast.showError(context, e.message);
      }
    }
  }

  Future<void> _disable() async {
    if (_pwdCtrl.text.isEmpty) return;
    setState(() {
      _disableBusy = true;
      _disableError = null;
    });
    try {
      await ref
          .read(settingsRepositoryProvider)
          .disableTwoFactor(password: _pwdCtrl.text);
      if (mounted) Navigator.of(context).pop(true);
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() {
          _disableBusy = false;
          _disableError = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AfabButton(
            label: l10n.securityRegenerateCodes,
            icon: LucideIcons.refreshCw,
            variant: AfabButtonVariant.secondary,
            expand: true,
            isLoading: _regenBusy,
            onPressed: _regenBusy ? null : _regenerate,
          ),
          if (_newCodes != null) ...[
            const SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final c in _newCodes!)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceInset,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        c,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.dangerBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.danger.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.securityDisable2faTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: colors.danger),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.securityDisable2faDesc,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextField(
                    controller: _pwdCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: l10n.securityCurrentPwd,
                      errorText: _disableError,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                AfabButton(
                  label: l10n.securityDisable2faBtn,
                  variant: AfabButtonVariant.danger,
                  expand: true,
                  isLoading: _disableBusy,
                  onPressed: _disableBusy ? null : _disable,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QrCodeWidget extends StatelessWidget {
  const _QrCodeWidget({required this.data, required this.size});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final qrCode = QrCode.fromData(
      data: data.isEmpty ? 'otpauth://totp/AFAB' : data,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final qrImage = QrImage(qrCode);
    return CustomPaint(
      size: Size.square(size),
      painter: _QrPainter(qrImage),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.qrImage);

  final QrImage qrImage;

  @override
  void paint(Canvas canvas, Size size) {
    final count = qrImage.moduleCount;
    if (count <= 0) return;
    final cell = size.width / count;
    final paint = Paint()..color = const Color(0xFF0F172A);
    for (var r = 0; r < count; r++) {
      for (var c = 0; c < count; c++) {
        if (qrImage.isDark(r, c)) {
          canvas.drawRect(
            Rect.fromLTWH(c * cell, r * cell, cell + 0.3, cell + 0.3),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) => false;
}

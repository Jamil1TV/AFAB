import 'dart:async';

import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/auth/presentation/widgets/auth_error_localizer.dart';
import 'package:afab_mobile/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `AUTH-05`: 6-digit email OTP verification with LTR digit boxes,
/// 6-digit paste auto-fill, 60-second resend timer, and debug `devOtp` support.
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  bool _submitting = false;
  bool _resending = false;
  int _cooldown = 0;
  Timer? _timer;
  String? _errorBanner;

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text.trim()).join();

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_cooldown <= 1) {
        t.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  void _applyCodeString(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    for (var i = 0; i < 6; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }
    if (digits.length >= 6) {
      _focusNodes[5].unfocus();
      _verify();
    } else {
      _focusNodes[digits.length].requestFocus();
    }
    setState(() {});
  }

  Future<void> _verify() async {
    final code = _code;
    if (code.length < 6) {
      setState(() => _errorBanner = context.l10n.authVerifyCodeIncomplete);
      return;
    }
    setState(() {
      _submitting = true;
      _errorBanner = null;
    });
    try {
      await ref.read(authNotifierProvider.notifier).verifyEmail(code: code);
      if (!mounted) return;
      AfabToast.showSuccess(context, context.l10n.authVerifySuccess);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorBanner = localizeAuthFailure(context, e));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _resending) return;
    setState(() {
      _resending = true;
      _errorBanner = null;
    });
    try {
      await ref.read(authNotifierProvider.notifier).resendVerification();
      if (!mounted) return;
      _startCooldown();
      AfabToast.showSuccess(context, context.l10n.authCodeResent);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorBanner = localizeAuthFailure(context, e));
    } finally {
      if (mounted) {
        setState(() => _resending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final session = ref.watch(authNotifierProvider);
    final email = session.user?.email ?? '';

    if (email.isEmpty) {
      return AuthScaffold(
        child: Column(
          children: [
            Text(l10n.authNoEmailFound),
            const SizedBox(height: 16),
            AfabButton(
              label: l10n.authBackToLogin,
              expand: true,
              onPressed: () => context.go('/login'),
            ),
          ],
        ),
      );
    }

    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.secondaryBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(LucideIcons.mailCheck, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.authVerifyEmailTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.authVerifyEmailSubtitle(email),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colors.textMuted),
          ),
          if (kDebugMode && session.devOtp != null) ...[
            const SizedBox(height: 14),
            AfabInsetPanel(
              borderColor: colors.info.withValues(alpha: 0.4),
              child: InkWell(
                onTap: () => _applyCodeString(session.devOtp!),
                child: Text(
                  l10n.authDevOtpNotice(session.devOtp!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.info,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ],
          if (_errorBanner != null) ...[
            const SizedBox(height: 14),
            AfabInsetPanel(
              borderColor: colors.danger.withValues(alpha: 0.45),
              child: Text(
                _errorBanner!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.danger, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                for (var i = 0; i < 6; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: SizedBox(
                        height: 54,
                        child: TextFormField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            if (value.length > 1) {
                              _applyCodeString(value);
                              return;
                            }
                            if (value.isNotEmpty && i < 5) {
                              _focusNodes[i + 1].requestFocus();
                            } else if (value.isEmpty && i > 0) {
                              _focusNodes[i - 1].requestFocus();
                            }
                            if (_code.length == 6) {
                              _verify();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          AfabButton(
            label: l10n.authVerifyButton,
            isLoading: _submitting,
            expand: true,
            onPressed: _verify,
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              Text(
                l10n.authDidntReceiveCode,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              TextButton(
                onPressed: (_cooldown > 0 || _resending) ? null : _resend,
                child: Text(
                  _cooldown > 0
                      ? l10n.authResendIn(_cooldown)
                      : l10n.authResendCode,
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: Text(l10n.authUseDifferentAccount),
          ),
        ],
      ),
    );
  }
}

import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/validation/validators.dart';
import 'package:afab_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/auth/presentation/widgets/auth_error_localizer.dart';
import 'package:afab_mobile/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_loader.dart';
import 'package:afab_mobile/shared/widgets/afab_text_field.dart';
import 'package:afab_mobile/shared/widgets/password_strength_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum _ResetTokenStatus { needsInput, validating, valid, expired, invalid, success }

/// Screen `AUTH-07`: Password reset via deep-linked or manually pasted token.
/// Explicitly preserves `_` in Base64URL tokens via `AppValidators.sanitizeResetToken`.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.initialToken});

  final String? initialToken;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tokenCtrl;
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  _ResetTokenStatus _status = _ResetTokenStatus.needsInput;
  bool _submitting = false;
  String? _errorBanner;

  @override
  void initState() {
    super.initState();
    final sanitized = widget.initialToken != null
        ? AppValidators.sanitizeResetToken(widget.initialToken!)
        : '';
    _tokenCtrl = TextEditingController(text: sanitized);
    if (sanitized.isNotEmpty) {
      Future.microtask(() => _validateToken(sanitized));
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _validateToken(String raw) async {
    final token = AppValidators.sanitizeResetToken(raw);
    if (token.isEmpty) {
      setState(() => _status = _ResetTokenStatus.invalid);
      return;
    }
    setState(() {
      _status = _ResetTokenStatus.validating;
      _errorBanner = null;
    });
    try {
      await ref.read(authRepositoryProvider).validateResetToken(token: token);
      if (!mounted) return;
      setState(() => _status = _ResetTokenStatus.valid);
    } on AppFailure catch (e) {
      if (!mounted) return;
      if (e.code == 'TOKEN_EXPIRED') {
        setState(() => _status = _ResetTokenStatus.expired);
      } else if (e.code == 'INVALID_TOKEN') {
        setState(() => _status = _ResetTokenStatus.invalid);
      } else {
        setState(() {
          _status = _ResetTokenStatus.needsInput;
          _errorBanner = localizeAuthFailure(context, e);
        });
      }
    }
  }

  Future<void> _submitReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final token = AppValidators.sanitizeResetToken(_tokenCtrl.text);
    setState(() {
      _submitting = true;
      _errorBanner = null;
    });
    try {
      await ref.read(authRepositoryProvider).resetPasswordByToken(
            token: token,
            password: _passwordCtrl.text,
          );
      await ref.read(authNotifierProvider.notifier).handleSessionExpired();
      if (!mounted) return;
      setState(() => _status = _ResetTokenStatus.success);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorBanner = localizeAuthFailure(context, e));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;

    return AuthScaffold(
      child: switch (_status) {
        _ResetTokenStatus.validating => Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: AfabLoader(label: l10n.authResetPasswordValidating),
            ),
          ),
        _ResetTokenStatus.expired || _ResetTokenStatus.invalid => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                LucideIcons.link2Off,
                size: 40,
                color: colors.danger,
              ),
              const SizedBox(height: 14),
              Text(
                _status == _ResetTokenStatus.expired
                    ? l10n.authTokenExpiredTitle
                    : l10n.authTokenInvalidTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _status == _ResetTokenStatus.expired
                    ? l10n.authTokenExpiredMessage
                    : l10n.authTokenInvalidMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colors.textMuted),
              ),
              const SizedBox(height: 20),
              AfabButton(
                label: l10n.authRequestNewLink,
                expand: true,
                onPressed: () => context.go('/forgot-password'),
              ),
              const SizedBox(height: 10),
              AfabButton(
                label: l10n.authBackToLogin,
                variant: AfabButtonVariant.secondary,
                expand: true,
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        _ResetTokenStatus.success => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                LucideIcons.circleCheck,
                size: 44,
                color: colors.success,
              ),
              const SizedBox(height: 14),
              Text(
                l10n.authPasswordResetSuccessTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.authPasswordResetSuccessMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colors.textMuted),
              ),
              const SizedBox(height: 20),
              AfabButton(
                label: l10n.authBackToLogin,
                expand: true,
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        _ResetTokenStatus.needsInput => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.authResetPasswordTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 14),
              if (_errorBanner != null) ...[
                AfabInsetPanel(
                  borderColor: colors.danger.withValues(alpha: 0.45),
                  child: Text(
                    _errorBanner!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colors.danger),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              AfabTextField(
                label: l10n.authResetTokenLabel,
                controller: _tokenCtrl,
                hintText: l10n.authResetTokenHint,
                forceLtr: true,
                prefixIcon: const Icon(LucideIcons.keyRound, size: 18),
              ),
              const SizedBox(height: 18),
              AfabButton(
                label: l10n.authValidateTokenButton,
                expand: true,
                onPressed: () => _validateToken(_tokenCtrl.text),
              ),
            ],
          ),
        _ResetTokenStatus.valid => Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.authResetPasswordTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.authResetPasswordSubtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: colors.textMuted),
                ),
                const SizedBox(height: 18),
                if (_errorBanner != null) ...[
                  AfabInsetPanel(
                    borderColor: colors.danger.withValues(alpha: 0.45),
                    child: Text(
                      _errorBanner!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colors.danger),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                AfabPasswordField(
                  label: l10n.authNewPassword,
                  controller: _passwordCtrl,
                  hintText: l10n.authNewPasswordPlaceholder,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final pw = v ?? '';
                    if (!AppValidators.evaluatePassword(pw).isStrongEnough) {
                      return l10n.authResetPasswordWeak;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                PasswordStrengthIndicator(password: _passwordCtrl.text),
                const SizedBox(height: 14),
                AfabPasswordField(
                  label: l10n.authConfirmPassword,
                  controller: _confirmCtrl,
                  hintText: l10n.authConfirmPasswordPlaceholder,
                  textInputAction: TextInputAction.done,
                  validator: (v) => v != _passwordCtrl.text
                      ? l10n.authResetPasswordMismatch
                      : null,
                  onFieldSubmitted: (_) => _submitReset(),
                ),
                const SizedBox(height: 20),
                AfabButton(
                  label: l10n.authResetButton,
                  isLoading: _submitting,
                  expand: true,
                  onPressed: _submitReset,
                ),
              ],
            ),
          ),
      },
    );
  }
}

import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/auth/presentation/widgets/auth_error_localizer.dart';
import 'package:afab_mobile/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `AUTH-03`: 2FA login challenge accepting 6-digit TOTP or
/// 8-char emergency backup codes (`XXXX-XXXX`).
class TwoFactorChallengeScreen extends ConsumerStatefulWidget {
  const TwoFactorChallengeScreen({super.key});

  @override
  ConsumerState<TwoFactorChallengeScreen> createState() =>
      _TwoFactorChallengeScreenState();
}

class _TwoFactorChallengeScreenState
    extends ConsumerState<TwoFactorChallengeScreen> {
  final _codeCtrl = TextEditingController();
  bool _useBackupCode = false;
  bool _submitting = false;
  String? _errorBanner;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeCtrl.text.trim();
    if (_useBackupCode ? code.length < 8 : code.length < 6) {
      setState(() => _errorBanner = context.l10n.authVerifyCodeIncomplete);
      return;
    }

    setState(() {
      _submitting = true;
      _errorBanner = null;
    });
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .verifyTwoFactor(code: code);
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
                child: Icon(
                  LucideIcons.shieldCheck,
                  color: colors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.authTwoFactorTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.authTwoFactorSubtitle,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: 20),
          if (_errorBanner != null) ...[
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
            const SizedBox(height: 16),
          ],
          AfabTextField(
            label: _useBackupCode
                ? l10n.authBackupCodeLabel
                : l10n.authTwoFactorEnterCode,
            controller: _codeCtrl,
            hintText: _useBackupCode ? l10n.authBackupCodePlaceholder : '000000',
            forceLtr: true,
            keyboardType:
                _useBackupCode ? TextInputType.text : TextInputType.number,
            maxLength: _useBackupCode ? 16 : 6,
            prefixIcon: Icon(
              _useBackupCode ? LucideIcons.keyRound : LucideIcons.smartphone,
              size: 18,
            ),
            onChanged: (val) {
              if (_useBackupCode) {
                final upper = val.toUpperCase();
                if (upper != val) {
                  _codeCtrl.value = TextEditingValue(
                    text: upper,
                    selection: TextSelection.collapsed(offset: upper.length),
                  );
                }
              } else {
                final digits = val.replaceAll(RegExp(r'\D'), '');
                if (digits != val) {
                  _codeCtrl.value = TextEditingValue(
                    text: digits,
                    selection: TextSelection.collapsed(offset: digits.length),
                  );
                }
              }
            },
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () {
                _codeCtrl.clear();
                setState(() {
                  _useBackupCode = !_useBackupCode;
                  _errorBanner = null;
                });
              },
              child: Text(
                _useBackupCode ? l10n.authUseTotpCode : l10n.authUseBackupCode,
              ),
            ),
          ),
          const SizedBox(height: 16),
          AfabButton(
            label: l10n.authTwoFactorVerifyButton,
            isLoading: _submitting,
            expand: true,
            onPressed: _submit,
          ),
          const SizedBox(height: 12),
          AfabButton(
            label: l10n.authBackToLogin,
            variant: AfabButtonVariant.ghost,
            expand: true,
            onPressed: () {
              ref.read(authNotifierProvider.notifier).cancelTwoFactor();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

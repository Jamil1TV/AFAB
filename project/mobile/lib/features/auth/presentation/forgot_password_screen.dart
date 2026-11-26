import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/validation/validators.dart';
import 'package:afab_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:afab_mobile/features/auth/presentation/widgets/auth_error_localizer.dart';
import 'package:afab_mobile/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `AUTH-06`: Enumeration-safe password reset link request screen.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _submitting = false;
  bool _sent = false;
  String? _errorBanner;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _errorBanner = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .forgotPasswordLink(email: _emailCtrl.text);
      if (!mounted) return;
      setState(() => _sent = true);
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

    if (_sent) {
      return AuthScaffold(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.successBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.mailCheck,
                  color: colors.success,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.authResetEmailSent,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.authResetEmailSentSubtitle(_emailCtrl.text.trim()),
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: 22),
            AfabButton(
              label: l10n.authEnterTokenManually,
              variant: AfabButtonVariant.soft,
              expand: true,
              onPressed: () => context.push('/reset-password'),
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
      );
    }

    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.authForgotPasswordTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.authForgotPasswordSubtitle,
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            AfabTextField(
              label: l10n.authEmail,
              controller: _emailCtrl,
              hintText: l10n.authEmailPlaceholder,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              forceLtr: true,
              prefixIcon: const Icon(LucideIcons.mail, size: 18),
              validator: (v) {
                final val = (v ?? '').trim();
                if (val.isEmpty) return l10n.authEmailRequired;
                if (!AppValidators.isValidEmail(val)) return l10n.authEmailInvalid;
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            AfabButton(
              label: l10n.authSendResetLink,
              isLoading: _submitting,
              expand: true,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(l10n.authBackToLogin),
                ),
                TextButton(
                  onPressed: () => context.push('/reset-password'),
                  child: Text(l10n.authEnterTokenManually),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

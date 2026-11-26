import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/validation/validators.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/auth/presentation/widgets/auth_error_localizer.dart';
import 'package:afab_mobile/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_text_field.dart';
import 'package:afab_mobile/shared/widgets/password_strength_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `AUTH-04`: User registration creating initial user + workspace.
/// Includes live 5-rule `PasswordStrengthIndicator`.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _submitting = false;
  String? _errorBanner;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _businessNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _errorBanner = null;
    });
    try {
      await ref.read(authNotifierProvider.notifier).register(
            firstName: _firstNameCtrl.text,
            lastName: _lastNameCtrl.text,
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
            businessName: _businessNameCtrl.text,
          );
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.authSignupTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.authSignupSubtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: 20),
            if (_errorBanner != null) ...[
              AfabInsetPanel(
                borderColor: colors.danger.withValues(alpha: 0.45),
                child: Row(
                  children: [
                    Icon(LucideIcons.circleAlert, size: 18, color: colors.danger),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorBanner!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: AfabTextField(
                    label: l10n.authFirstName,
                    controller: _firstNameCtrl,
                    hintText: l10n.authFirstNamePlaceholder,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.authFieldRequired
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AfabTextField(
                    label: l10n.authLastName,
                    controller: _lastNameCtrl,
                    hintText: l10n.authLastNamePlaceholder,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.authFieldRequired
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AfabTextField(
              label: l10n.authBusinessName,
              controller: _businessNameCtrl,
              hintText: l10n.authBusinessNamePlaceholder,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(LucideIcons.building2, size: 18),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.authFieldRequired
                  : null,
            ),
            const SizedBox(height: 14),
            AfabTextField(
              label: l10n.authEmail,
              controller: _emailCtrl,
              hintText: l10n.authEmailPlaceholder,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              forceLtr: true,
              prefixIcon: const Icon(LucideIcons.mail, size: 18),
              validator: (v) {
                final val = (v ?? '').trim();
                if (val.isEmpty) return l10n.authEmailRequired;
                if (!AppValidators.isValidEmail(val)) return l10n.authEmailInvalid;
                return null;
              },
            ),
            const SizedBox(height: 14),
            AfabPasswordField(
              label: l10n.authPassword,
              controller: _passwordCtrl,
              hintText: l10n.authPasswordCreatePlaceholder,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              validator: (v) => (v == null || v.length < 8)
                  ? l10n.authPasswordMinLength
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_passwordCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              PasswordStrengthIndicator(password: _passwordCtrl.text),
            ],
            const SizedBox(height: 20),
            AfabButton(
              label: l10n.authSignupButton,
              isLoading: _submitting,
              expand: true,
              onPressed: _submit,
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text(
                  l10n.authHasAccount,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(l10n.authLoginTab),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

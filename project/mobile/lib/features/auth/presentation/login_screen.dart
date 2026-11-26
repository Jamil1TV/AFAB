import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/validation/validators.dart';
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

/// Screen `AUTH-02`: Email/password sign-in supporting `rememberMe` (30d),
/// backend lockout/rate-limit banners, and automatic 2FA challenge handoff.
/// Inert social login buttons from Web are intentionally omitted.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _rememberMe = false;
  bool _submitting = false;
  String? _errorBanner;

  @override
  void dispose() {
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
      final res = await ref.read(authNotifierProvider.notifier).login(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
            rememberMe: _rememberMe,
          );
      if (!mounted) return;
      if (res.requiresTwoFactor) {
        context.push('/two-factor');
      }
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
              l10n.authLoginTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.authLoginSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14.5,
                    color: colors.textMuted,
                  ),
            ),
            const SizedBox(height: 24),
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
              const SizedBox(height: 18),
            ],
            AfabTextField(
              label: l10n.authEmail,
              controller: _emailCtrl,
              hintText: l10n.authEmailPlaceholder,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              forceLtr: true,
              autofillHints: const [AutofillHints.email],
              prefixIcon: const Icon(LucideIcons.mail, size: 18),
              validator: (v) {
                final val = (v ?? '').trim();
                if (val.isEmpty) return l10n.authEmailRequired;
                if (!AppValidators.isValidEmail(val)) return l10n.authEmailInvalid;
                return null;
              },
            ),
            const SizedBox(height: 18),
            AfabPasswordField(
              label: l10n.authPassword,
              controller: _passwordCtrl,
              hintText: l10n.authPasswordPlaceholder,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: (v) =>
                  (v == null || v.isEmpty) ? l10n.authFieldRequired : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final rememberWidget = InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (v) =>
                              setState(() => _rememberMe = v ?? false),
                          visualDensity: const VisualDensity(
                            horizontal: -4,
                            vertical: -4,
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l10n.authRememberMe,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: 13.5,
                                  color: colors.textMuted,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                final forgotButton = TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.authForgotPassword,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                );

                final canKeepSingleRow = constraints.maxWidth >= 260 &&
                    MediaQuery.textScalerOf(context).scale(14) <= 16.5;

                if (canKeepSingleRow) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: rememberWidget),
                      const SizedBox(width: 8),
                      forgotButton,
                    ],
                  );
                }
                return Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [rememberWidget, forgotButton],
                );
              },
            ),
            const SizedBox(height: 22),
            AfabButton(
              label: l10n.authLoginButton,
              variant: AfabButtonVariant.premium,
              minHeight: 54,
              isLoading: _submitting,
              expand: true,
              onPressed: _submit,
            ),
            Divider(
              height: 32,
              color: colors.border.withValues(alpha: 0.65),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Text(
                  l10n.authNoAccount,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: colors.textMuted,
                      ),
                ),
                TextButton(
                  onPressed: () => context.go('/signup'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.authSignupTab,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

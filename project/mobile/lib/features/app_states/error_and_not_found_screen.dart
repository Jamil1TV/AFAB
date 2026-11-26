import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/auth/domain/session_state.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ErrorAndNotFoundScreen extends ConsumerWidget {
  const ErrorAndNotFoundScreen({
    super.key,
    this.isNotFound = true,
    this.onRetry,
  });

  final bool isNotFound;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final isAuthed =
        ref.watch(authNotifierProvider).status == SessionStatus.authenticated;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AfabCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isNotFound ? colors.secondaryBg : colors.dangerBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isNotFound
                            ? LucideIcons.compass
                            : LucideIcons.triangleAlert,
                        size: 28,
                        color: isNotFound ? colors.primary : colors.danger,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isNotFound ? '404' : l10n.errorGenericTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: isNotFound ? colors.primary : colors.danger,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isNotFound ? l10n.notFoundTitle : l10n.errorGenericDesc,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (isNotFound) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.notFoundDesc,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (onRetry != null) ...[
                      AfabButton(
                        label: l10n.commonRetry,
                        icon: LucideIcons.refreshCw,
                        expand: true,
                        onPressed: onRetry,
                      ),
                      const SizedBox(height: 10),
                    ],
                    AfabButton(
                      label: isAuthed ? l10n.notFoundGoHome : l10n.authLoginButton,
                      icon: isAuthed ? LucideIcons.house : LucideIcons.logIn,
                      variant: onRetry != null
                          ? AfabButtonVariant.secondary
                          : AfabButtonVariant.primary,
                      expand: true,
                      onPressed: () =>
                          context.go(isAuthed ? '/dashboard' : '/login'),
                    ),
                    if (isNotFound && context.canPop()) ...[
                      const SizedBox(height: 10),
                      AfabButton(
                        label: l10n.commonBack,
                        icon: LucideIcons.arrowLeft,
                        variant: AfabButtonVariant.ghost,
                        expand: true,
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Standalone fallback widget used by `ErrorWidget.builder` so render failures
/// before `MaterialApp`/`Localizations` initialize never cascade into secondary errors.
class AfabSafeErrorCard extends StatelessWidget {
  const AfabSafeErrorCard({super.key, this.debugDetails});

  final String? debugDetails;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Unable to display this section',
                  style: TextStyle(
                    color: Color(0xFF991B1B),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    decoration: TextDecoration.none,
                  ),
                ),
                if (debugDetails != null && debugDetails!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    debugDetails!,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7F1D1D),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

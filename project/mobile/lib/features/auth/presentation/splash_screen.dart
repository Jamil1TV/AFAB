import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/auth/domain/auth_notifier.dart';
import 'package:afab_mobile/features/auth/domain/session_state.dart';
import 'package:afab_mobile/shared/widgets/afab_brand_logo.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Screen `AUTH-01`: Branded entry point performing silent encrypted cookie-jar
/// session restoration without artificial timers.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();

    Future.microtask(() {
      if (mounted) {
        ref.read(authNotifierProvider.notifier).restoreSession();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final session = ref.watch(authNotifierProvider);
    final isDark = colors.isDark;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    final bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [Color(0xFF020817), Color(0xFF07142B), Color(0xFF020817)]
          : const [Color(0xFFF8FAFC), Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
    );

    Widget heroContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (session.status == SessionStatus.biometricLocked) ...[
          const AfabBrandLogo(size: 84),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: AfabCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.fingerprint,
                    size: 38,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.securityBiometricTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.securityBiometricPrompt,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  AfabButton(
                    label: l10n.securityUnlockBtn,
                    icon: LucideIcons.fingerprint,
                    expand: true,
                    onPressed: () => ref
                        .read(authNotifierProvider.notifier)
                        .unlockWithBiometrics(l10n.securityBiometricPrompt),
                  ),
                  const SizedBox(height: 10),
                  AfabButton(
                    label: l10n.splashContinueToLogin,
                    variant: AfabButtonVariant.secondary,
                    expand: true,
                    onPressed: () async {
                      await ref
                          .read(authNotifierProvider.notifier)
                          .handleSessionExpired();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ],
              ),
            ),
          ),
        ] else if (session.status == SessionStatus.offlineError) ...[
          const AfabBrandLogo(size: 76),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: AfabCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.wifiOff,
                    size: 36,
                    color: colors.warning,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.splashOfflineTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.splashOfflineSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  AfabButton(
                    label: l10n.commonRetry,
                    icon: LucideIcons.refreshCw,
                    expand: true,
                    onPressed: () =>
                        ref.read(authNotifierProvider.notifier).restoreSession(),
                  ),
                  const SizedBox(height: 10),
                  AfabButton(
                    label: l10n.splashContinueToLogin,
                    variant: AfabButtonVariant.secondary,
                    expand: true,
                    onPressed: () async {
                      await ref
                          .read(authNotifierProvider.notifier)
                          .handleSessionExpired();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          const AfabBrandLogo(size: 124),
          const SizedBox(height: 22),
          Text(
            l10n.appTitle,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.splashTagline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 148,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.splashRestoring,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ],
    );

    if (!reducedMotion && session.status != SessionStatus.offlineError) {
      heroContent = FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: heroContent,
        ),
      );
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: bgGradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(
              child: Center(
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        colors.primary.withValues(alpha: isDark ? 0.14 : 0.08),
                        colors.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 48)
                            .clamp(0.0, double.infinity),
                      ),
                      child: Center(child: heroContent),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

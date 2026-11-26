import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_status_badge.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Standalone Maintenance screen placed outside the authenticated shell
/// (fixing Web's `(dashboard)/maintenance/page.tsx` layout bug) and polling
/// `GET /api/v1/health` instead of using a fake progress bar.
class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen>
    with WidgetsBindingObserver {
  bool _checking = false;
  bool? _isHealthy;
  String? _mailStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_checking && mounted) {
      _checkHealth();
    }
  }

  Future<void> _checkHealth() async {
    setState(() => _checking = true);
    try {
      final response = await ref.read(dioProvider).get<dynamic>(
            '/health',
            options: Options(extra: const {'requireAuth': false}),
          );
      final data = response.data;
      final healthy = data is Map && data['status'] == 'UP';
      final mailStatus =
          data is Map && data['mail'] is Map ? data['mail']['status']?.toString() : null;
      if (!mounted) return;
      setState(() {
        _isHealthy = healthy;
        _mailStatus = mailStatus;
        _checking = false;
      });
      if (healthy && mounted) {
        context.go('/splash');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isHealthy = false;
        _mailStatus = null;
        _checking = false;
      });
    }
  }

  Future<void> _contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@afab.ai',
      queryParameters: const {'subject': 'AFAB Service Status'},
    );
    final launched = await launchUrl(uri);
    if (!launched) {
      await Clipboard.setData(const ClipboardData(text: 'support@afab.ai'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AfabCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: colors.warningBg,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.warning.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(
                        LucideIcons.wrench,
                        size: 28,
                        color: colors.warning,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_isHealthy != null) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          AfabStatusBadge(
                            label: _isHealthy!
                                ? l10n.maintenanceStatusOnline
                                : l10n.maintenanceStatusOffline,
                            variant: _isHealthy!
                                ? AfabBadgeVariant.success
                                : AfabBadgeVariant.danger,
                          ),
                          if (_mailStatus != null && _mailStatus!.isNotEmpty)
                            AfabStatusBadge(
                              label: 'Mail: $_mailStatus',
                              variant: _mailStatus == 'UP'
                                  ? AfabBadgeVariant.success
                                  : AfabBadgeVariant.warning,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      l10n.maintenanceTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.maintenanceDesc,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textMuted,
                          ),
                    ),
                    const SizedBox(height: 24),
                    AfabButton(
                      label: l10n.maintenanceCheckStatus,
                      icon: LucideIcons.refreshCw,
                      isLoading: _checking,
                      expand: true,
                      onPressed: _checkHealth,
                    ),
                    const SizedBox(height: 10),
                    AfabButton(
                      label: l10n.notFoundGoHome,
                      variant: AfabButtonVariant.secondary,
                      expand: true,
                      onPressed: () => context.go('/splash'),
                    ),
                    const SizedBox(height: 8),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: TextButton.icon(
                        onPressed: _contactSupport,
                        icon: const Icon(LucideIcons.mail, size: 15),
                        label: const Text('support@afab.ai'),
                      ),
                    ),
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

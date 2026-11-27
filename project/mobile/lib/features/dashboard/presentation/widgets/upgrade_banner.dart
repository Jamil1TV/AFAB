import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/shared/widgets/afab_button.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class UpgradeBanner extends StatelessWidget {
  const UpgradeBanner({
    super.key,
    required this.subscription,
  });

  final SubscriptionSnapshotDto? subscription;

  @override
  Widget build(BuildContext context) {
    if (subscription == null || subscription!.isPro) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final colors = context.afabColors;

    return AfabCard(
      borderColor: colors.primary.withValues(alpha: 0.35),
      backgroundColor: colors.secondaryBg.withValues(alpha: 0.55),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dpr = MediaQuery.devicePixelRatioOf(context);
          final thumbPx = (56 * dpr).round().clamp(64, 256);
          final artwork = ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/crystal-cube.jpg',
              width: 56,
              height: 56,
              cacheWidth: thumbPx,
              cacheHeight: thumbPx,
              filterQuality: FilterQuality.medium,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 56,
                height: 56,
                color: colors.primary.withValues(alpha: 0.18),
                child: Icon(LucideIcons.crown, color: colors.primary),
              ),
            ),
          );

          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.dashboardUpgradeTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.dashboardUpgradeDesc,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );

          final cta = AfabButton(
            label: l10n.dashboardUpgradeBtn,
            variant: AfabButtonVariant.premium,
            compact: true,
            onPressed: () => context.go('/plans'),
          );

          if (constraints.maxWidth < 460) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    artwork,
                    const SizedBox(width: 14),
                    Expanded(child: copy),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: cta,
                ),
              ],
            );
          }

          return Row(
            children: [
              artwork,
              const SizedBox(width: 14),
              Expanded(child: copy),
              const SizedBox(width: 12),
              cta,
            ],
          );
        },
      ),
    );
  }
}

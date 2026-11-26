import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/shared/widgets/afab_card.dart';
import 'package:afab_mobile/shared/widgets/afab_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Clean localized module entry placeholder for Phases 3–6 routes wired into
/// the shell navigation before those feature phases are implemented.
class PhasePlaceholderScreen extends StatelessWidget {
  const PhasePlaceholderScreen({
    super.key,
    required this.title,
    this.icon = LucideIcons.layers,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        AfabCard(
          child: AfabEmptyState(
            icon: icon,
            title: l10n.commonComingSoon,
            description: l10n.commonComingSoonDesc,
          ),
        ),
      ],
    );
  }
}

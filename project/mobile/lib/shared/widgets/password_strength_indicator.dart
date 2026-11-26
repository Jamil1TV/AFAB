import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:afab_mobile/core/theme/afab_colors.dart';
import 'package:afab_mobile/core/validation/validators.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.afabColors;
    final eval = AppValidators.evaluatePassword(password);

    final (label, barColor) = switch (eval.score) {
      <= 1 => (l10n.authPwStrengthWeak, colors.danger),
      2 => (l10n.authPwStrengthFair, colors.warning),
      3 => (l10n.authPwStrengthGood, colors.info),
      4 => (l10n.authPwStrengthStrong, colors.success),
      _ => (l10n.authPwStrengthVeryStrong, colors.success),
    };

    final rules = [
      (eval.hasMinLength, l10n.authPwReqLength),
      (eval.hasUppercase, l10n.authPwReqUppercase),
      (eval.hasLowercase, l10n.authPwReqLowercase),
      (eval.hasDigit, l10n.authPwReqNumber),
      (eval.hasSpecial, l10n.authPwReqSpecial),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceInset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  l10n.authPwStrengthLabel,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: barColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < 5; i++)
                Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsetsDirectional.only(end: i < 4 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: i < eval.score ? barColor : colors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              for (final (met, text) in rules)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      met ? LucideIcons.circleCheck : LucideIcons.circle,
                      size: 13,
                      color: met ? colors.success : colors.textMuted,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        text,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: met ? colors.textPrimary : colors.textMuted,
                            ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

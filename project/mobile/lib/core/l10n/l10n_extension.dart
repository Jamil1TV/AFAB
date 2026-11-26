import 'package:afab_mobile/core/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';

export 'package:afab_mobile/core/l10n/generated/app_localizations.dart';

extension AfabL10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

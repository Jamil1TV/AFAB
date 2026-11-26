import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/l10n/l10n_extension.dart';
import 'package:flutter/widgets.dart';

String localizeAuthFailure(BuildContext context, Object error) {
  final l10n = context.l10n;
  if (error is NetworkFailure) {
    return l10n.authErrorNetworkFailure;
  }
  if (error is RateLimitedFailure) {
    return l10n.authErrorRateLimited;
  }
  if (error is AppFailure) {
    return switch (error.code) {
      'INVALID_CREDENTIALS' => l10n.authErrorInvalidCredentials,
      'ACCOUNT_DISABLED' => l10n.authErrorAccountDisabled,
      'ACCOUNT_LOCKED' =>
        error.message.isNotEmpty ? error.message : l10n.authErrorAccountLocked,
      'INVALID_2FA_CODE' => l10n.authErrorInvalid2FaCode,
      'RATE_LIMITED' || 'RATE_LIMIT_UNAVAILABLE' => l10n.authErrorRateLimited,
      'NETWORK_ERROR' => l10n.authErrorNetworkFailure,
      _ => error.message.isNotEmpty ? error.message : l10n.authErrorServerFailure,
    };
  }
  return l10n.authErrorServerFailure;
}

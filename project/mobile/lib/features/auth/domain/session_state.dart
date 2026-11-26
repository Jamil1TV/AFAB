import 'package:afab_mobile/features/auth/data/auth_dtos.dart';
import 'package:flutter/foundation.dart';

enum SessionStatus {
  initial,
  restoring,
  biometricLocked,
  unauthenticated,
  requiresTwoFactor,
  authenticated,
  offlineError,
}

@immutable
class SessionState {
  const SessionState({
    this.status = SessionStatus.initial,
    this.user,
    this.twoFactorToken,
    this.rememberMe = false,
    this.devOtp,
    this.errorMessage,
  });

  final SessionStatus status;
  final UserProfile? user;
  final String? twoFactorToken;
  final bool rememberMe;
  final String? devOtp;
  final String? errorMessage;

  bool get isAuthenticated =>
      status == SessionStatus.authenticated && user != null;
  bool get needsEmailVerification =>
      isAuthenticated && !(user!.emailVerified);
  bool get needsOnboarding =>
      isAuthenticated && user!.emailVerified && !(user!.onboardingComplete);

  SessionState copyWith({
    SessionStatus? status,
    UserProfile? user,
    bool clearUser = false,
    String? twoFactorToken,
    bool clearTwoFactorToken = false,
    bool? rememberMe,
    String? devOtp,
    bool clearDevOtp = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SessionState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      twoFactorToken: clearTwoFactorToken
          ? null
          : (twoFactorToken ?? this.twoFactorToken),
      rememberMe: rememberMe ?? this.rememberMe,
      devOtp: clearDevOtp ? null : (devOtp ?? this.devOtp),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

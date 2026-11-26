import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/theme/appearance_settings.dart';
import 'package:afab_mobile/features/auth/data/auth_dtos.dart';
import 'package:afab_mobile/features/auth/data/auth_repository_impl.dart';
import 'package:afab_mobile/features/auth/domain/session_state.dart';
import 'package:afab_mobile/features/settings/domain/biometric_lock_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthNotifier extends Notifier<SessionState> {
  @override
  SessionState build() => const SessionState();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> restoreSession() async {
    state = state.copyWith(status: SessionStatus.restoring, clearError: true);
    try {
      final profile = await _repo.restoreSession();
      if (profile == null) {
        state = const SessionState(status: SessionStatus.unauthenticated);
        return;
      }
      await ref
          .read(appearanceNotifierProvider.notifier)
          .syncCompactFromProfile(profile.compactMode);
      final bioSvc = ref.read(biometricLockServiceProvider);
      if (await bioSvc.isEnabled()) {
        final ok = await bioSvc.authenticate('Authenticate to unlock AFAB');
        if (!ok) {
          state = SessionState(
            status: SessionStatus.biometricLocked,
            user: profile,
          );
          return;
        }
      }
      state = SessionState(
        status: SessionStatus.authenticated,
        user: profile,
      );
    } on NetworkFailure catch (e) {
      state = SessionState(
        status: SessionStatus.offlineError,
        errorMessage: e.message,
      );
    } on AppFailure {
      await _repo.clearLocalAuth();
      state = const SessionState(status: SessionStatus.unauthenticated);
    } catch (_) {
      state = const SessionState(status: SessionStatus.unauthenticated);
    }
  }

  Future<AuthResponseDto> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final res = await _repo.login(
      email: email,
      password: password,
      rememberMe: rememberMe,
    );
    if (res.requiresTwoFactor && res.twoFactorToken != null) {
      state = SessionState(
        status: SessionStatus.requiresTwoFactor,
        twoFactorToken: res.twoFactorToken,
        rememberMe: rememberMe,
      );
      return res;
    }

    UserProfile? user = res.user;
    try {
      user = await _repo.getMyProfile();
    } catch (_) {}

    if (user != null) {
      await ref
          .read(appearanceNotifierProvider.notifier)
          .syncCompactFromProfile(user.compactMode);
    }

    state = SessionState(
      status: SessionStatus.authenticated,
      user: user,
      rememberMe: rememberMe,
      devOtp: res.devOtp,
    );
    return res;
  }

  Future<void> verifyTwoFactor({required String code}) async {
    final token = state.twoFactorToken;
    if (token == null || token.isEmpty) {
      throw const UnauthorizedFailure(
        message: 'Two-factor challenge expired. Please sign in again.',
        code: 'INVALID_2FA_REQUEST',
      );
    }
    final res = await _repo.verifyTwoFactor(
      twoFactorToken: token,
      code: code,
      rememberMe: state.rememberMe,
    );
    var user = res.user;
    try {
      user = await _repo.getMyProfile();
    } catch (_) {}
    if (user != null) {
      await ref
          .read(appearanceNotifierProvider.notifier)
          .syncCompactFromProfile(user.compactMode);
    }
    state = SessionState(
      status: SessionStatus.authenticated,
      user: user,
      rememberMe: state.rememberMe,
    );
  }

  void cancelTwoFactor() {
    state = const SessionState(status: SessionStatus.unauthenticated);
  }

  Future<AuthResponseDto> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String businessName,
  }) async {
    final res = await _repo.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      businessName: businessName,
    );
    state = SessionState(
      status: SessionStatus.authenticated,
      user: res.user,
      devOtp: res.devOtp,
    );
    return res;
  }

  Future<void> verifyEmail({required String code}) async {
    final email = state.user?.email;
    if (email == null || email.isEmpty) {
      throw const UnauthorizedFailure(
        message: 'Session invalid. Please sign in again.',
      );
    }
    await _repo.verifyEmail(email: email, code: code);
    state = state.copyWith(
      user: state.user!.copyWith(emailVerified: true),
      clearDevOtp: true,
    );
  }

  Future<String?> resendVerification() async {
    final email = state.user?.email;
    if (email == null || email.isEmpty) {
      throw const UnauthorizedFailure(
        message: 'Session invalid. Please sign in again.',
      );
    }
    final otp = await _repo.resendVerification(email: email);
    if (otp != null) {
      state = state.copyWith(devOtp: otp);
    }
    return otp;
  }

  Future<void> completeOnboarding({
    required String country,
    required String industry,
    required String businessType,
    required String currency,
    required String timezone,
    required int fiscalYearStartMonth,
  }) async {
    final businessId = state.user?.businessId;
    if (businessId == null || businessId.isEmpty) {
      throw const ValidationFailure(
        message: 'Missing active business workspace.',
      );
    }
    final updated = await _repo.completeOnboarding(
      businessId: businessId,
      country: country,
      industry: industry,
      businessType: businessType,
      currency: currency,
      timezone: timezone,
      fiscalYearStartMonth: fiscalYearStartMonth,
    );
    state = state.copyWith(
      user: updated.copyWith(onboardingComplete: true),
    );
  }

  Future<void> refreshProfile() async {
    if (!state.isAuthenticated) return;
    final profile = await _repo.getMyProfile();
    await ref
        .read(appearanceNotifierProvider.notifier)
        .syncCompactFromProfile(profile.compactMode);
    state = state.copyWith(user: profile);
  }

  Future<void> updateCachedUser(UserProfile profile) async {
    await ref
        .read(appearanceNotifierProvider.notifier)
        .syncCompactFromProfile(profile.compactMode);
    state = state.copyWith(user: profile);
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const SessionState(status: SessionStatus.unauthenticated);
  }

  Future<void> forceLocalLogout() async {
    await _repo.clearLocalAuth();
    state = const SessionState(status: SessionStatus.unauthenticated);
  }

  Future<void> unlockWithBiometrics(String reason) async {
    if (state.status != SessionStatus.biometricLocked || state.user == null) {
      return;
    }
    final ok = await ref.read(biometricLockServiceProvider).authenticate(reason);
    if (ok) {
      state = SessionState(
        status: SessionStatus.authenticated,
        user: state.user,
      );
    }
  }

  Future<void> handleSessionExpired() async {
    await _repo.clearLocalAuth();
    state = const SessionState(status: SessionStatus.unauthenticated);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, SessionState>(
  AuthNotifier.new,
);

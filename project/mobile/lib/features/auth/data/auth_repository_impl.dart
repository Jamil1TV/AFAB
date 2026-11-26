import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/network/auth_interceptor.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/core/network/tenant_interceptor.dart';
import 'package:afab_mobile/core/storage/encrypted_cookie_storage.dart';
import 'package:afab_mobile/core/storage/prefs_store.dart';
import 'package:afab_mobile/core/storage/session_token_holder.dart';
import 'package:afab_mobile/features/auth/data/auth_dtos.dart';
import 'package:afab_mobile/features/auth/data/auth_remote_datasource.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthRepository {
  AuthRepository({
    required this.remote,
    required this.tokenHolder,
    required this.businessHolder,
    required this.authInterceptor,
    required this.cookieStorage,
    required this.prefsStore,
  });

  final AuthRemoteDataSource remote;
  final SessionTokenHolder tokenHolder;
  final ActiveBusinessHolder businessHolder;
  final AuthInterceptor authInterceptor;
  final EncryptedCookieStorage cookieStorage;
  final PrefsStore prefsStore;

  Future<bool> hasStoredSessionCookies() =>
      cookieStorage.hasAnyPersistedCookies();

  Future<AuthResponseDto> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final res = await remote.login(
      email: email,
      password: password,
      rememberMe: rememberMe,
    );
    if (!res.requiresTwoFactor) {
      await _applyAuthenticatedTokens(res);
    }
    return res;
  }

  Future<AuthResponseDto> verifyTwoFactor({
    required String twoFactorToken,
    required String code,
    required bool rememberMe,
  }) async {
    final res = await remote.verifyTwoFactorLogin(
      twoFactorToken: twoFactorToken,
      code: code,
      rememberMe: rememberMe,
    );
    await _applyAuthenticatedTokens(res);
    return res;
  }

  Future<AuthResponseDto> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String businessName,
  }) async {
    final res = await remote.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      businessName: businessName,
    );
    await _applyAuthenticatedTokens(res);
    return res;
  }

  Future<UserProfile?> restoreSession() async {
    final hasCookies = await cookieStorage.hasAnyPersistedCookies();
    if (!hasCookies && !tokenHolder.hasAccessToken) {
      return null;
    }

    if (!tokenHolder.hasAccessToken) {
      final res = await remote.refresh();
      await _applyAuthenticatedTokens(res);
      if (res.user != null) {
        try {
          return await remote.getMyProfile();
        } on AppFailure {
          return res.user;
        }
      }
    }
    return remote.getMyProfile();
  }

  Future<UserProfile> getMyProfile() => remote.getMyProfile();

  Future<void> verifyEmail({required String email, required String code}) =>
      remote.verifyEmail(email: email, code: code);

  Future<String?> resendVerification({required String email}) =>
      remote.resendVerification(email: email);

  Future<void> forgotPasswordLink({required String email}) =>
      remote.forgotPasswordLink(email: email);

  Future<void> validateResetToken({required String token}) =>
      remote.validateResetToken(token: token);

  Future<void> resetPasswordByToken({
    required String token,
    required String password,
  }) =>
      remote.resetPasswordByToken(token: token, password: password);

  Future<UserProfile> completeOnboarding({
    required String businessId,
    required String country,
    required String industry,
    required String businessType,
    required String currency,
    required String timezone,
    required int fiscalYearStartMonth,
  }) async {
    await remote.completeBusinessOnboarding(
      businessId: businessId,
      country: country,
      industry: industry,
      businessType: businessType,
      currency: currency,
      timezone: timezone,
      fiscalYearStartMonth: fiscalYearStartMonth,
    );
    return remote.getMyProfile();
  }

  Future<void> logout() async {
    try {
      await remote.logout();
    } catch (_) {
      // Always wipe local session even if backend logout call fails offline.
    } finally {
      await clearLocalAuth();
    }
  }

  Future<void> clearLocalAuth() async {
    await authInterceptor.clearLocalSession();
    businessHolder.clear();
    await prefsStore.setActiveBusinessId(null);
  }

  Future<void> _applyAuthenticatedTokens(AuthResponseDto res) async {
    tokenHolder.setTokens(
      accessToken: res.accessToken,
      csrfToken: res.csrfToken,
    );
    final bizId = res.user?.businessId;
    if (bizId != null && bizId.isNotEmpty) {
      businessHolder.setBusinessId(bizId);
      await prefsStore.setActiveBusinessId(bizId);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    remote: ref.watch(authRemoteDataSourceProvider),
    tokenHolder: ref.watch(sessionTokenHolderProvider),
    businessHolder: ref.watch(activeBusinessHolderProvider),
    authInterceptor: ref.watch(authInterceptorProvider),
    cookieStorage: ref.watch(encryptedCookieStorageProvider),
    prefsStore: ref.watch(prefsStoreProvider),
  );
});

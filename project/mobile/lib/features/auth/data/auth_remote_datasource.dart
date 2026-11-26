import 'package:afab_mobile/core/error/error_mapper.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/features/auth/data/auth_dtos.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AuthResponseDto> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'email': email.trim(),
          'password': password,
          'rememberMe': rememberMe,
        },
        options: Options(extra: const {'requireAuth': false}),
      );
      return AuthResponseDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<AuthResponseDto> verifyTwoFactorLogin({
    required String twoFactorToken,
    required String code,
    required bool rememberMe,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/2fa/verify-login',
        data: {
          'twoFactorToken': twoFactorToken,
          'code': code.trim(),
          'rememberMe': rememberMe,
        },
        options: Options(extra: const {'requireAuth': false}),
      );
      return AuthResponseDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<AuthResponseDto> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String businessName,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          'email': email.trim(),
          'password': password,
          'businessName': businessName.trim(),
        },
        options: Options(extra: const {'requireAuth': false}),
      );
      return AuthResponseDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<AuthResponseDto> refresh() async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        options: Options(extra: const {'requireAuth': false}),
      );
      return AuthResponseDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<dynamic>(
        '/auth/logout',
        options: Options(extra: const {'requireAuth': false}),
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/auth/verify-email',
        data: {'email': email.trim(), 'code': code.trim()},
        options: Options(extra: const {'requireAuth': false}),
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<String?> resendVerification({required String email}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/resend-verification',
        data: {'email': email.trim()},
        options: Options(extra: const {'requireAuth': false}),
      );
      return res.data?['devOtp']?.toString();
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> forgotPasswordLink({required String email}) async {
    try {
      await _dio.post<dynamic>(
        '/auth/forgot-password-link',
        data: {'email': email.trim()},
        options: Options(extra: const {'requireAuth': false}),
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> validateResetToken({required String token}) async {
    try {
      await _dio.post<dynamic>(
        '/auth/validate-reset-token',
        data: {'token': token},
        options: Options(extra: const {'requireAuth': false}),
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> resetPasswordByToken({
    required String token,
    required String password,
  }) async {
    try {
      await _dio.post<dynamic>(
        '/auth/reset-password-token',
        data: {'token': token, 'password': password},
        options: Options(extra: const {'requireAuth': false}),
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<UserProfile> getMyProfile() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/user/me');
      return UserProfile.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> completeBusinessOnboarding({
    required String businessId,
    required String country,
    required String industry,
    required String businessType,
    required String currency,
    required String timezone,
    required int fiscalYearStartMonth,
  }) async {
    try {
      await _dio.put<dynamic>(
        '/business/$businessId',
        data: {
          'country': country,
          'industry': industry,
          'businessType': businessType,
          'currency': currency,
          'timezone': timezone,
          'fiscalYearStartMonth': fiscalYearStartMonth,
        },
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(dioProvider));
});

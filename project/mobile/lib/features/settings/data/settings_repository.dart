import 'package:afab_mobile/core/error/error_mapper.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/features/auth/data/auth_dtos.dart';
import 'package:afab_mobile/features/settings/data/settings_dtos.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsRepository {
  SettingsRepository(this._dio);

  final Dio _dio;

  Future<UserProfile> updateProfile(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/user/me',
        data: payload,
      );
      return UserProfile.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> exportUserData() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/user/me/export');
      return res.data ?? const {};
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<AccountDeletionPreflightDto> getDeletionPreflight() async {
    try {
      final res =
          await _dio.get<Map<String, dynamic>>('/user/me/deletion-preflight');
      return AccountDeletionPreflightDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> deleteMyAccount(String confirmation) async {
    try {
      await _dio.delete<void>(
        '/user/me',
        data: {'confirmation': confirmation},
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post<void>(
        '/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<TwoFactorSetupDto> setupTwoFactor() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/user/2fa/setup');
      return TwoFactorSetupDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> enableTwoFactor({
    required String secret,
    required String code,
    required List<String> backupCodes,
  }) async {
    try {
      await _dio.post<void>(
        '/user/2fa/enable',
        data: {
          'secret': secret,
          'code': code,
          'backupCodes': backupCodes,
        },
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> disableTwoFactor({required String password}) async {
    try {
      await _dio.post<void>(
        '/user/2fa/disable',
        data: {'password': password},
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<List<String>> regenerateBackupCodes() async {
    try {
      final res = await _dio.post<List<dynamic>>('/user/2fa/backup-codes');
      final list = res.data ?? const [];
      return list.map((e) => e.toString()).toList();
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<List<SessionDto>> listSessions() async {
    try {
      final res = await _dio.get<List<dynamic>>('/user/me/sessions');
      final list = res.data ?? const [];
      return list
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => SessionDto.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> revokeSession(String tokenId) async {
    try {
      await _dio.delete<void>('/user/me/sessions/$tokenId');
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> revokeAllSessions() async {
    try {
      await _dio.delete<void>('/user/me/sessions');
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(dioProvider));
});

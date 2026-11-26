import 'package:afab_mobile/core/error/error_mapper.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/features/notifications/data/notification_dto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationsRepository {
  NotificationsRepository(this._dio);

  final Dio _dio;

  Future<NotificationsResponseDto> fetchNotifications() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/notifications');
      return NotificationsResponseDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<NotificationsResponseDto> markRead(String id) async {
    try {
      final res =
          await _dio.put<Map<String, dynamic>>('/notifications/$id/read');
      return NotificationsResponseDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<NotificationsResponseDto> markAllRead() async {
    try {
      final res =
          await _dio.put<Map<String, dynamic>>('/notifications/read-all');
      return NotificationsResponseDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }
}

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(dioProvider));
});

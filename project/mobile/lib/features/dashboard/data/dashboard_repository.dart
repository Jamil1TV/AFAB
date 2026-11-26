import 'package:afab_mobile/core/error/error_mapper.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<DashboardSummaryDto> getSummary(DashboardPeriod period) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/dashboard/summary',
        queryParameters: {'period': period.apiValue},
      );
      return DashboardSummaryDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<AiPulseDto> getAiPulse() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/ai/pulse');
      return AiPulseDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<SubscriptionSnapshotDto> getMySubscription() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/subscription/me');
      return SubscriptionSnapshotDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});

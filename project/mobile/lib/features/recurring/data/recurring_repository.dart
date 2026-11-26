import 'package:afab_mobile/core/error/error_mapper.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/features/recurring/data/recurring_dtos.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecurringRepository {
  RecurringRepository(this.dio);

  final Dio dio;

  Future<List<RecurringTransactionDto>> listRules({
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await dio.get<List<dynamic>>(
        '/recurring-transactions',
        cancelToken: cancelToken,
      );
      final list = res.data ?? const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(RecurringTransactionDto.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<RecurringTransactionDto> createRule(
    RecurringTransactionRequestDto request,
  ) async {
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/recurring-transactions',
        data: request.toJson(),
      );
      return RecurringTransactionDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<RecurringTransactionDto> updateRule(
    String id,
    RecurringTransactionRequestDto request,
  ) async {
    try {
      final res = await dio.put<Map<String, dynamic>>(
        '/recurring-transactions/$id',
        data: request.toJson(),
      );
      return RecurringTransactionDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<RecurringTransactionDto> updateStatus(
    String id, {
    required bool active,
  }) async {
    try {
      final res = await dio.patch<Map<String, dynamic>>(
        '/recurring-transactions/$id/status',
        data: {'active': active},
      );
      return RecurringTransactionDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<RecurringRunResultDto> runDue(String id) async {
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/recurring-transactions/$id/run-due',
      );
      return RecurringRunResultDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> deleteRule(String id) async {
    try {
      await dio.delete<void>('/recurring-transactions/$id');
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }
}

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  return RecurringRepository(ref.watch(dioProvider));
});

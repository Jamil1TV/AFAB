import 'package:afab_mobile/core/error/error_mapper.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/features/budgets/data/budget_dtos.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetsRepository {
  BudgetsRepository(this.dio);

  final Dio dio;

  Future<List<BudgetDto>> listBudgets({
    bool includeArchived = false,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await dio.get<List<dynamic>>(
        '/budgets',
        queryParameters: {'includeArchived': includeArchived},
        cancelToken: cancelToken,
      );
      final list = res.data ?? const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(BudgetDto.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<BudgetOverviewSummaryDto> getSummary({
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await dio.get<Map<String, dynamic>>(
        '/budgets/summary',
        cancelToken: cancelToken,
      );
      return BudgetOverviewSummaryDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<BudgetDto> getBudgetById(String id) async {
    try {
      final res = await dio.get<Map<String, dynamic>>('/budgets/$id');
      return BudgetDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<BudgetDto> createBudget(BudgetRequestDto request) async {
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/budgets',
        data: request.toJson(),
      );
      return BudgetDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<BudgetDto> updateBudget(String id, BudgetRequestDto request) async {
    try {
      final res = await dio.put<Map<String, dynamic>>(
        '/budgets/$id',
        data: request.toJson(),
      );
      return BudgetDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> archiveBudget(String id) async {
    try {
      await dio.delete<void>('/budgets/$id');
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }
}

final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  return BudgetsRepository(ref.watch(dioProvider));
});

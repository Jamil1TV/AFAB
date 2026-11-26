import 'package:afab_mobile/core/error/error_mapper.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/features/expenses/data/expense_dtos.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpenseRepository {
  ExpenseRepository(this.dio);

  final Dio dio;

  Future<ExpenseSummaryDto> getSummary(DashboardPeriod period) async {
    try {
      final res = await dio.get<Map<String, dynamic>>(
        '/expenses/summary',
        queryParameters: {'period': period.apiValue},
      );
      return ExpenseSummaryDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<TransactionPageDto> getExpenses({
    String? categoryId,
    String? search,
    int page = 0,
    int size = 15,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await dio.get<Map<String, dynamic>>(
        '/expenses',
        queryParameters: {
          'page': page,
          'size': size,
          if (categoryId != null && categoryId.isNotEmpty)
            'categoryId': categoryId,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
        cancelToken: cancelToken,
      );
      return TransactionPageDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(dioProvider));
});

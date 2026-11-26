import 'package:afab_mobile/core/error/error_mapper.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/features/transactions/data/transaction_dtos.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionRepository {
  TransactionRepository(this.dio);

  final Dio dio;

  Future<TransactionPageDto> getTransactions({
    TransactionType? type,
    String? categoryId,
    TransactionStatus? status,
    PaymentMethod? paymentMethod,
    bool? taxDeductible,
    String? startDate,
    String? endDate,
    String? search,
    int page = 0,
    int size = 15,
    CancelToken? cancelToken,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'size': size,
        if (type != null) 'type': type.apiValue,
        if (categoryId != null && categoryId.isNotEmpty)
          'categoryId': categoryId,
        if (status != null) 'status': status.apiValue,
        if (paymentMethod != null) 'paymentMethod': paymentMethod.apiValue,
        'taxDeductible': ?taxDeductible,
        if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
        if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
        if (search != null && search.trim().isNotEmpty)
          'search': search.trim(),
      };
      final res = await dio.get<Map<String, dynamic>>(
        '/transactions',
        queryParameters: query,
        cancelToken: cancelToken,
      );
      return TransactionPageDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<TransactionDto> getTransactionById(String id) async {
    try {
      final res = await dio.get<Map<String, dynamic>>('/transactions/$id');
      return TransactionDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<TransactionDto> createTransaction(
    CreateTransactionPayload payload,
  ) async {
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/transactions',
        data: payload.toJson(),
      );
      return TransactionDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<TransactionDto> updateTransaction(
    String id,
    UpdateTransactionPayload payload,
  ) async {
    try {
      final res = await dio.put<Map<String, dynamic>>(
        '/transactions/$id',
        data: payload.toJson(),
      );
      return TransactionDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await dio.delete<void>('/transactions/$id');
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<FxConvertResultDto> convertCurrency({
    required String from,
    required String to,
    required Decimal amount,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await dio.get<Map<String, dynamic>>(
        '/currencies/convert',
        queryParameters: {
          'from': from.toUpperCase(),
          'to': to.toUpperCase(),
          'amount': amount.toString(),
        },
        cancelToken: cancelToken,
      );
      return FxConvertResultDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(dioProvider));
});

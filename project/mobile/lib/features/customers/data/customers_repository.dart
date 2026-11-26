import 'package:afab_mobile/core/error/error_mapper.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/features/customers/data/customer_dtos.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomersRepository {
  CustomersRepository(this.dio);

  final Dio dio;

  Future<CustomerPageDto> listCustomers({
    String? search,
    String? status,
    String? group,
    int page = 0,
    int size = 15,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    CancelToken? cancelToken,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'size': size,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        if (search != null && search.trim().isNotEmpty)
          'search': search.trim(),
        if (status != null && status.isNotEmpty && status != 'All')
          'status': status,
        if (group != null && group.isNotEmpty && group != 'All')
          'group': group,
      };
      final res = await dio.get<Map<String, dynamic>>(
        '/customers',
        queryParameters: query,
        cancelToken: cancelToken,
      );
      return CustomerPageDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<CustomerSummaryDto> getSummary({
    String period = 'month',
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await dio.get<Map<String, dynamic>>(
        '/customers/summary',
        queryParameters: {'period': period},
        cancelToken: cancelToken,
      );
      return CustomerSummaryDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<CustomerDto> getCustomerById(String id) async {
    try {
      final res = await dio.get<Map<String, dynamic>>('/customers/$id');
      return CustomerDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<CustomerDto> createCustomer(CustomerMutationRequest request) async {
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/customers',
        data: request.toJson(),
      );
      return CustomerDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<CustomerDto> updateCustomer(
    String id,
    CustomerMutationRequest request,
  ) async {
    try {
      final res = await dio.put<Map<String, dynamic>>(
        '/customers/$id',
        data: request.toJson(),
      );
      return CustomerDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> archiveCustomer(String id) async {
    try {
      await dio.delete<void>('/customers/$id');
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }
}

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  return CustomersRepository(ref.watch(dioProvider));
});

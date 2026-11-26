import 'package:afab_mobile/core/error/error_mapper.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/features/invoices/data/invoice_dtos.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InvoicesRepository {
  InvoicesRepository(this.dio);

  final Dio dio;

  Future<InvoiceSummaryDto> getSummary({CancelToken? cancelToken}) async {
    try {
      final res = await dio.get<Map<String, dynamic>>(
        '/invoices/summary',
        cancelToken: cancelToken,
      );
      return InvoiceSummaryDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<InvoicePageDto> listInvoices({
    String? customerId,
    InvoiceStatus? status,
    String? search,
    int page = 0,
    int size = 15,
    CancelToken? cancelToken,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'size': size,
        if (customerId != null && customerId.isNotEmpty)
          'customerId': customerId,
        if (status != null) 'status': status.apiValue,
        if (search != null && search.trim().isNotEmpty)
          'search': search.trim(),
      };
      final res = await dio.get<Map<String, dynamic>>(
        '/invoices',
        queryParameters: query,
        cancelToken: cancelToken,
      );
      return InvoicePageDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<InvoiceDto> getInvoiceById(String id) async {
    try {
      final res = await dio.get<Map<String, dynamic>>('/invoices/$id');
      return InvoiceDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<InvoiceDto> createInvoice(CreateInvoiceRequestDto request) async {
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/invoices',
        data: request.toJson(),
      );
      return InvoiceDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<InvoiceDto> updateDraftInvoice(
    String id,
    CreateInvoiceRequestDto request,
  ) async {
    try {
      final res = await dio.put<Map<String, dynamic>>(
        '/invoices/$id',
        data: request.toJson(),
      );
      return InvoiceDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<InvoiceDto> issueInvoice(String id, {bool sent = false}) async {
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/invoices/$id/issue',
        queryParameters: {'sent': sent},
      );
      return InvoiceDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<InvoiceDto> cancelInvoice(String id) async {
    try {
      final res = await dio.post<Map<String, dynamic>>('/invoices/$id/cancel');
      return InvoiceDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<PaymentDto> recordPayment(
    String invoiceId,
    RecordPaymentRequestDto request,
  ) async {
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/invoices/$invoiceId/payments',
        data: request.toJson(),
        options: Options(headers: {'Idempotency-Key': request.idempotencyKey}),
      );
      return PaymentDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<List<PaymentDto>> listPayments(String invoiceId) async {
    try {
      final res = await dio.get<List<dynamic>>('/invoices/$invoiceId/payments');
      final list = res.data ?? const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(PaymentDto.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }
}

final invoicesRepositoryProvider = Provider<InvoicesRepository>((ref) {
  return InvoicesRepository(ref.watch(dioProvider));
});

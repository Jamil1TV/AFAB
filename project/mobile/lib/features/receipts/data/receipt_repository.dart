import 'dart:typed_data';

import 'package:afab_mobile/core/error/error_mapper.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/features/receipts/data/receipt_dto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';

class ReceiptRepository {
  ReceiptRepository(this.dio);

  final Dio dio;

  Future<List<ReceiptDto>> listForTransaction(String transactionId) async {
    try {
      final res = await dio.get<List<dynamic>>(
        '/receipts/transactions/$transactionId',
      );
      final raw = res.data ?? const [];
      return raw
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => ReceiptDto.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<ReceiptDto> uploadReceipt({
    required String transactionId,
    required String filePath,
    required String filename,
    required String detectedMime,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final part = await MultipartFile.fromFile(
        filePath,
        filename: filename,
        contentType: MediaType.parse(detectedMime),
      );
      final formData = FormData.fromMap({'file': part});
      final res = await dio.post<Map<String, dynamic>>(
        '/receipts/transactions/$transactionId',
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
      return ReceiptDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<Uint8List> downloadContent(String receiptId) async {
    try {
      final res = await dio.get<List<int>>(
        '/receipts/$receiptId/content',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(res.data ?? const []);
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<PresignedDownloadDto> getDownloadUrl(String receiptId) async {
    try {
      final res = await dio.get<Map<String, dynamic>>(
        '/receipts/$receiptId/download-url',
      );
      return PresignedDownloadDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> deleteReceipt(String receiptId) async {
    try {
      await dio.delete<void>('/receipts/$receiptId');
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }
}

final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  return ReceiptRepository(ref.watch(dioProvider));
});

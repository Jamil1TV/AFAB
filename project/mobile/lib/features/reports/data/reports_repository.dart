import 'dart:io';
import 'dart:typed_data';

import 'package:afab_mobile/core/error/error_mapper.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/features/reports/data/report_dtos.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ReportsRepository {
  ReportsRepository(this.dio);

  final Dio dio;

  Future<ProfitAndLossReportDto> getProfitAndLoss({
    required String period,
    String? startDate,
    String? endDate,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await dio.get<Map<String, dynamic>>(
        '/reports/profit-loss',
        queryParameters: {
          'period': period,
          if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
          if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
        },
        cancelToken: cancelToken,
      );
      return ProfitAndLossReportDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<CashFlowReportDto> getCashFlow({
    required String period,
    String? startDate,
    String? endDate,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await dio.get<Map<String, dynamic>>(
        '/reports/cash-flow',
        queryParameters: {
          'period': period,
          if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
          if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
        },
        cancelToken: cancelToken,
      );
      return CashFlowReportDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<ComparisonReportDto> getComparison({
    required String primaryPeriod,
    required String comparisonPeriod,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await dio.get<Map<String, dynamic>>(
        '/reports/comparison',
        queryParameters: {
          'primaryPeriod': primaryPeriod,
          'comparisonPeriod': comparisonPeriod,
        },
        cancelToken: cancelToken,
      );
      return ComparisonReportDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<ExportedReportFile> exportCsv({
    required String period,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final res = await dio.get<List<int>>(
        '/reports/export/csv',
        queryParameters: {
          'period': period,
          if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
          if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(res.data ?? const []);
      return ExportedReportFile(
        bytes: bytes,
        filename: 'AFAB-report-$period.csv',
        mimeType: 'text/csv',
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<ExportedReportFile> exportPdf({
    required String period,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final res = await dio.get<List<int>>(
        '/reports/export/pdf',
        queryParameters: {
          'period': period,
          if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
          if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(res.data ?? const []);
      return ExportedReportFile(
        bytes: bytes,
        filename: 'AFAB-statement-$period.pdf',
        mimeType: 'application/pdf',
      );
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> saveAndShareExport(ExportedReportFile file) async {
    final dir = await getTemporaryDirectory();
    final safe = file.filename.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final out = File('${dir.path}/$safe');
    await out.writeAsBytes(file.bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(out.path, mimeType: file.mimeType)],
        subject: file.filename,
      ),
    );
  }
}

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.watch(dioProvider));
});

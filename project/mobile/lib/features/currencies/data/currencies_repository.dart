import 'package:afab_mobile/core/error/error_mapper.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/features/currencies/data/currency_dtos.dart';
import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CurrenciesRepository {
  CurrenciesRepository(this.dio);

  final Dio dio;

  Future<List<CurrencyPairDto>> getMarketRates({
    required String base,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await dio.get<List<dynamic>>(
        '/currencies/rates',
        queryParameters: {'base': base.toUpperCase()},
        cancelToken: cancelToken,
      );
      final list = res.data ?? const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(CurrencyPairDto.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<List<HistoricalRatePointDto>> getHistoricalRates({
    required String from,
    required String to,
    required String timeframe,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await dio.get<List<dynamic>>(
        '/currencies/history',
        queryParameters: {
          'from': from.toUpperCase(),
          'to': to.toUpperCase(),
          'timeframe': timeframe.toUpperCase(),
        },
        cancelToken: cancelToken,
      );
      final list = res.data ?? const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(HistoricalRatePointDto.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<CurrencyConversionResultDto> convert({
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
      return CurrencyConversionResultDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<CurrencyChangePreviewDto> previewBusinessCurrencyChange({
    required String newCurrency,
    CancelToken? cancelToken,
  }) async {
    try {
      final res = await dio.get<Map<String, dynamic>>(
        '/currencies/business/preview',
        queryParameters: {'newCurrency': newCurrency.toUpperCase()},
        cancelToken: cancelToken,
      );
      return CurrencyChangePreviewDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<CurrencyChangeResultDto> changeBusinessCurrency({
    required String newCurrency,
  }) async {
    try {
      // Policy P1.1: historical transactions are immutable (`convertExistingTransactions: false`).
      final res = await dio.post<Map<String, dynamic>>(
        '/currencies/business/change',
        data: {
          'newCurrency': newCurrency.toUpperCase(),
          'convertExistingTransactions': false,
        },
      );
      return CurrencyChangeResultDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }
}

final currenciesRepositoryProvider = Provider<CurrenciesRepository>((ref) {
  return CurrenciesRepository(ref.watch(dioProvider));
});

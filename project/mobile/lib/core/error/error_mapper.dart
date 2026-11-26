import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:dio/dio.dart';

abstract final class ErrorMapper {
  static AppFailure fromDio(DioException err) {
    final errObj = err.error;
    if (errObj is AppFailure) {
      return errObj;
    }

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }

    final response = err.response;
    if (response == null) {
      return const NetworkFailure();
    }

    return fromResponse(
      statusCode: response.statusCode ?? 500,
      data: response.data,
      headers: response.headers.map,
    );
  }

  static AppFailure fromResponse({
    required int statusCode,
    dynamic data,
    Map<String, List<String>>? headers,
  }) {
    final map = data is Map<String, dynamic>
        ? data
        : (data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{});

    final code = (map['code'] as String?) ??
        (map['error'] as String?) ??
        'HTTP_$statusCode';
    final message = (map['message'] as String?) ??
        (map['error'] as String?) ??
        'Something went wrong. Please try again later.';

    if (statusCode == 403 && code == 'PLAN_LIMIT_REACHED') {
      return PlanLimitReachedFailure(
        message: message,
        feature: (map['feature'] as String?) ?? 'feature',
        limit: (map['limit'] as num?)?.toInt() ?? 0,
        used: (map['used'] as num?)?.toInt() ?? 0,
        upgradeTo: (map['upgradeTo'] as String?) ?? 'plus',
      );
    }

    if (statusCode == 403 && code == 'BUSINESS_READ_ONLY') {
      return BusinessReadOnlyFailure(
        message: message,
        businessId: map['businessId']?.toString(),
        businessName: map['businessName']?.toString(),
      );
    }

    if (statusCode == 503 && code == 'AI_SERVICE_UNAVAILABLE') {
      return AiUnavailableFailure(message: message);
    }

    if (statusCode == 429) {
      final retryHeader = headers?['retry-after']?.firstOrNull ??
          headers?['Retry-After']?.firstOrNull;
      final retrySeconds = int.tryParse(retryHeader ?? '') ?? 60;
      return RateLimitedFailure(
        message: message,
        code: code,
        retryAfterSeconds: retrySeconds,
      );
    }

    if (statusCode == 400) {
      final rawFieldErrors = map['fieldErrors'];
      final fieldErrors = <String, String>{};
      if (rawFieldErrors is Map) {
        for (final entry in rawFieldErrors.entries) {
          fieldErrors[entry.key.toString()] = entry.value.toString();
        }
      }
      return ValidationFailure(
        message: message,
        code: code,
        fieldErrors: fieldErrors,
      );
    }

    if (statusCode == 401) {
      return UnauthorizedFailure(message: message, code: code);
    }

    if (statusCode == 403) {
      return ForbiddenFailure(message: message, code: code);
    }

    if (statusCode == 404) {
      return NotFoundFailure(message: message, code: code);
    }

    if (statusCode == 409) {
      return ConflictFailure(message: message, code: code);
    }

    return ServerFailure(
      message: message,
      code: code,
      statusCode: statusCode,
    );
  }
}

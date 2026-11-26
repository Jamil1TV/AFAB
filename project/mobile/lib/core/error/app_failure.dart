/// Typed failure hierarchy mapped from Spring Boot `GlobalExceptionHandler`,
/// `SecurityConfig`, `AuthController`, and network transport errors.
sealed class AppFailure implements Exception {
  const AppFailure({
    required this.message,
    this.code = 'UNKNOWN_ERROR',
    this.statusCode,
  });

  final String message;
  final String code;
  final int? statusCode;

  @override
  String toString() => 'AppFailure($code, $statusCode): $message';
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure({
    super.message = 'Unable to connect to the server.',
    super.code = 'NETWORK_ERROR',
  }) : super(statusCode: 0);
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure({
    required super.message,
    super.code = 'UNAUTHORIZED',
  }) : super(statusCode: 401);
}

final class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure({
    required super.message,
    super.code = 'FORBIDDEN',
  }) : super(statusCode: 403);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure({
    required super.message,
    super.code = 'BAD_REQUEST',
    this.fieldErrors = const {},
  }) : super(statusCode: 400);

  final Map<String, String> fieldErrors;
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure({
    required super.message,
    super.code = 'NOT_FOUND',
  }) : super(statusCode: 404);
}

final class ConflictFailure extends AppFailure {
  const ConflictFailure({
    required super.message,
    super.code = 'CONFLICT',
  }) : super(statusCode: 409);
}

final class RateLimitedFailure extends AppFailure {
  const RateLimitedFailure({
    required super.message,
    super.code = 'RATE_LIMITED',
    this.retryAfterSeconds = 60,
  }) : super(statusCode: 429);

  final int retryAfterSeconds;
}

final class PlanLimitReachedFailure extends AppFailure {
  const PlanLimitReachedFailure({
    required super.message,
    required this.feature,
    required this.limit,
    required this.used,
    required this.upgradeTo,
  }) : super(code: 'PLAN_LIMIT_REACHED', statusCode: 403);

  final String feature;
  final int limit;
  final int used;
  final String upgradeTo;
}

final class BusinessReadOnlyFailure extends AppFailure {
  const BusinessReadOnlyFailure({
    required super.message,
    this.businessId,
    this.businessName,
  }) : super(code: 'BUSINESS_READ_ONLY', statusCode: 403);

  final String? businessId;
  final String? businessName;
}

final class AiUnavailableFailure extends AppFailure {
  const AiUnavailableFailure({
    required super.message,
  }) : super(code: 'AI_SERVICE_UNAVAILABLE', statusCode: 503);
}

final class ServerFailure extends AppFailure {
  const ServerFailure({
    required super.message,
    super.code = 'SERVER_ERROR',
    super.statusCode = 500,
  });
}

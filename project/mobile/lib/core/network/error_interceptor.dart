import 'package:afab_mobile/core/error/app_failure.dart';
import 'package:afab_mobile/core/error/error_mapper.dart';
import 'package:afab_mobile/core/network/global_events.dart';
import 'package:afab_mobile/core/network/tenant_interceptor.dart';
import 'package:afab_mobile/core/storage/prefs_store.dart';
import 'package:dio/dio.dart';

/// Translates global backend policy responses (`PLAN_LIMIT_REACHED`,
/// `BUSINESS_READ_ONLY`, `503`) into broadcast `GlobalApiEvent` notifications.
class ErrorInterceptor extends Interceptor {
  ErrorInterceptor({
    required this.eventBus,
    required this.businessHolder,
    required this.prefsStore,
  });

  final GlobalEventBus eventBus;
  final ActiveBusinessHolder businessHolder;
  final PrefsStore prefsStore;

  static const _domain503Codes = {
    'AI_SERVICE_UNAVAILABLE',
    'EMAIL_DELIVERY_FAILED',
    'RATE_LIMIT_UNAVAILABLE',
    'BILLING_NOT_CONFIGURED',
  };

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final failure = ErrorMapper.fromDio(err);
    switch (failure) {
      case PlanLimitReachedFailure():
        eventBus.emit(
          PlanLimitReachedEvent(
            feature: failure.feature,
            limit: failure.limit,
            used: failure.used,
            upgradeTo: failure.upgradeTo,
            message: failure.message,
          ),
        );
      case BusinessReadOnlyFailure():
        final currentBizId = businessHolder.businessId;
        if (currentBizId != null &&
            (failure.businessId == null ||
                failure.businessId == currentBizId)) {
          businessHolder.clear();
          await prefsStore.setActiveBusinessId(null);
        }
        eventBus.emit(
          BusinessReadOnlyEvent(
            businessId: failure.businessId,
            businessName: failure.businessName,
            message: failure.message,
          ),
        );
      case ServerFailure():
        if (failure.statusCode == 503 &&
            !_domain503Codes.contains(failure.code.toUpperCase())) {
          eventBus.emit(const MaintenanceDetectedEvent());
        }
      default:
        break;
    }
    handler.next(err);
  }
}

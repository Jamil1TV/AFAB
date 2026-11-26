import 'dart:async';

/// Global application-wide events emitted by Dio interceptors so UI layers can
/// open paywall sheets, handle read-only workspace locks, or redirect to login.
sealed class GlobalApiEvent {
  const GlobalApiEvent();
}

final class PlanLimitReachedEvent extends GlobalApiEvent {
  const PlanLimitReachedEvent({
    required this.feature,
    required this.limit,
    required this.used,
    required this.upgradeTo,
    required this.message,
  });

  final String feature;
  final int limit;
  final int used;
  final String upgradeTo;
  final String message;
}

final class BusinessReadOnlyEvent extends GlobalApiEvent {
  const BusinessReadOnlyEvent({
    this.businessId,
    this.businessName,
    required this.message,
  });

  final String? businessId;
  final String? businessName;
  final String message;
}

final class SessionExpiredEvent extends GlobalApiEvent {
  const SessionExpiredEvent({this.reason});

  final String? reason;
}

final class MaintenanceDetectedEvent extends GlobalApiEvent {
  const MaintenanceDetectedEvent();
}

class GlobalEventBus {
  final StreamController<GlobalApiEvent> _controller =
      StreamController<GlobalApiEvent>.broadcast();

  Stream<GlobalApiEvent> get stream => _controller.stream;

  void emit(GlobalApiEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  void dispose() {
    _controller.close();
  }
}

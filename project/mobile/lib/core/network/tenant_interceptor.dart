import 'package:dio/dio.dart';

/// Holds the active business UUID in RAM so `TenantInterceptor` can synchronously
/// attach `X-Business-Id` to all business-scoped API requests.
class ActiveBusinessHolder {
  String? _businessId;

  String? get businessId => _businessId;

  void setBusinessId(String? id) {
    _businessId = (id == null || id.trim().isEmpty) ? null : id.trim();
  }

  void clear() {
    _businessId = null;
  }
}

class TenantInterceptor extends Interceptor {
  TenantInterceptor(this._holder);

  final ActiveBusinessHolder _holder;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!options.path.contains('/auth/') &&
        !options.headers.containsKey('X-Business-Id')) {
      final id = _holder.businessId;
      if (id != null && id.isNotEmpty) {
        options.headers['X-Business-Id'] = id;
      }
    }
    handler.next(options);
  }
}

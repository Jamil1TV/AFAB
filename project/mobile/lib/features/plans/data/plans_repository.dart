import 'package:afab_mobile/core/error/error_mapper.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/features/dashboard/data/dashboard_dtos.dart';
import 'package:afab_mobile/features/plans/data/plans_dtos.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Abstraction over external Stripe Checkout / Portal launching so widget tests
/// can inspect launched URLs without triggering OS browser channels.
abstract class BillingUrlLauncher {
  Future<bool> launchExternal(Uri uri);
}

class DefaultBillingUrlLauncher implements BillingUrlLauncher {
  const DefaultBillingUrlLauncher();

  @override
  Future<bool> launchExternal(Uri uri) async {
    if (await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) {
      return true;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

final billingUrlLauncherProvider = Provider<BillingUrlLauncher>((ref) {
  return const DefaultBillingUrlLauncher();
});

class PlansRepository {
  PlansRepository(this._dio);

  final Dio _dio;

  static const String defaultReturnPath = '/dashboard/settings/subscription';

  Future<CheckoutSessionResponseDto> createCheckout({
    required String planSlug,
    required String billingInterval,
    required String locale,
    String returnPath = defaultReturnPath,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/billing/checkout',
        data: {
          'planSlug': planSlug,
          'billingInterval': billingInterval,
          'locale': locale == 'ar' ? 'ar' : 'en',
          'returnPath': returnPath,
        },
      );
      return CheckoutSessionResponseDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<UpgradeSubscriptionResponseDto> upgradeSubscription({
    required String planSlug,
    required String billingInterval,
    required String locale,
    String returnPath = defaultReturnPath,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/billing/upgrade',
        data: {
          'planSlug': planSlug,
          'billingInterval': billingInterval,
          'locale': locale == 'ar' ? 'ar' : 'en',
          'returnPath': returnPath,
        },
      );
      return UpgradeSubscriptionResponseDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<PortalSessionResponseDto> createPortal({
    required String locale,
    String returnPath = defaultReturnPath,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/billing/portal',
        data: {
          'locale': locale == 'ar' ? 'ar' : 'en',
          'returnPath': returnPath,
        },
      );
      return PortalSessionResponseDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<SubscriptionSnapshotDto> verifyCheckout(String sessionId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/billing/checkout/verify',
        data: {'sessionId': sessionId},
      );
      return SubscriptionSnapshotDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<SubscriptionSnapshotDto> cancelSubscription({
    List<String>? selectedBusinessIds,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/billing/cancel',
        data: {
          if (selectedBusinessIds != null && selectedBusinessIds.isNotEmpty)
            'selectedBusinessIds': selectedBusinessIds,
        },
      );
      return SubscriptionSnapshotDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<SubscriptionSnapshotDto> resumeSubscription() async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/billing/resume');
      return SubscriptionSnapshotDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<SubscriptionSnapshotDto> scheduleDowngrade({
    required String targetPlanSlug,
    String? billingInterval,
    List<String>? selectedBusinessIds,
    bool deferAllocation = false,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/billing/downgrade',
        data: {
          'targetPlanSlug': targetPlanSlug,
          if (billingInterval != null && billingInterval.isNotEmpty)
            'billingInterval': billingInterval,
          if (selectedBusinessIds != null && selectedBusinessIds.isNotEmpty)
            'selectedBusinessIds': selectedBusinessIds,
          'deferAllocation': deferAllocation,
        },
      );
      return SubscriptionSnapshotDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<BillingHistoryResponseDto> getBillingHistory() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/billing/history');
      return BillingHistoryResponseDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }
}

final plansRepositoryProvider = Provider<PlansRepository>((ref) {
  return PlansRepository(ref.watch(dioProvider));
});

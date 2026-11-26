import 'package:afab_mobile/core/error/error_mapper.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/features/business/data/business_dto.dart';
import 'package:afab_mobile/features/plans/data/plans_dtos.dart';
import 'package:afab_mobile/features/settings/data/settings_dtos.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BusinessRepository {
  BusinessRepository(this._dio);

  final Dio _dio;

  Future<List<BusinessDto>> listBusinesses() async {
    try {
      final res = await _dio.get<List<dynamic>>('/business');
      final list = res.data ?? const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(BusinessDto.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<BusinessDto?> getMine() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/business/mine');
      return res.data != null ? BusinessDto.fromJson(res.data!) : null;
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<BusinessDto> createBusiness({
    required String name,
    required String currency,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/business',
        data: {'name': name.trim(), 'currency': currency},
      );
      return BusinessDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<BusinessDto> switchBusiness(String businessId) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/business/$businessId/switch',
      );
      return BusinessDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<BusinessDto> updateBusiness(
    String businessId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/business/$businessId',
        data: payload,
      );
      return BusinessDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> archiveBusiness(String businessId) async {
    try {
      await _dio.delete<void>('/business/$businessId');
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<List<BusinessMemberDto>> listMembers(String businessId) async {
    try {
      final res = await _dio.get<List<dynamic>>(
        '/business/$businessId/members',
      );
      final list = res.data ?? const [];
      return list
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) => BusinessMemberDto.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<BusinessDto> transferOwnership(
    String businessId,
    String targetUserId,
  ) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/business/$businessId/transfer-ownership',
        data: {'targetUserId': targetUserId},
      );
      return BusinessDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<BusinessAllocationDto> getAllocations() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/business/allocations',
      );
      return BusinessAllocationDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<BusinessAllocationDto> updateAllocations({
    required List<String> selectedBusinessIds,
    String? primaryBusinessId,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/business/allocations',
        data: {
          'selectedBusinessIds': selectedBusinessIds,
          if (primaryBusinessId != null && primaryBusinessId.isNotEmpty)
            'primaryBusinessId': primaryBusinessId,
        },
      );
      return BusinessAllocationDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<BusinessAllocationDto> savePendingAllocations({
    required String targetPlanSlug,
    required List<String> selectedBusinessIds,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/business/allocations/pending',
        data: {
          'targetPlanSlug': targetPlanSlug,
          'selectedBusinessIds': selectedBusinessIds,
        },
      );
      return BusinessAllocationDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }
}

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BusinessRepository(ref.watch(dioProvider));
});

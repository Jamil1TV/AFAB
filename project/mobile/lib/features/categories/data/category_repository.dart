import 'package:afab_mobile/core/error/error_mapper.dart';
import 'package:afab_mobile/core/network/dio_client.dart';
import 'package:afab_mobile/features/categories/data/category_dto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryRepository {
  CategoryRepository(this.dio);

  final Dio dio;

  Future<List<CategoryDto>> getCategories() async {
    try {
      final res = await dio.get<List<dynamic>>('/categories');
      final list = res.data ?? const [];
      return list
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => CategoryDto.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<CategoryDto> createCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/categories',
        data: <String, dynamic>{
          'name': name.trim(),
          'type': type.toUpperCase(),
          if (icon != null && icon.isNotEmpty) 'icon': icon,
          if (color != null && color.isNotEmpty) 'color': color,
        },
      );
      return CategoryDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<CategoryDto> updateCategory({
    required String id,
    required String name,
    String? icon,
    String? color,
  }) async {
    try {
      final res = await dio.put<Map<String, dynamic>>(
        '/categories/$id',
        data: <String, dynamic>{
          'name': name.trim(),
          if (icon != null && icon.isNotEmpty) 'icon': icon,
          if (color != null && color.isNotEmpty) 'color': color,
        },
      );
      return CategoryDto.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await dio.delete<void>('/categories/$id');
    } on DioException catch (e) {
      throw ErrorMapper.fromDio(e);
    }
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(dioProvider));
});

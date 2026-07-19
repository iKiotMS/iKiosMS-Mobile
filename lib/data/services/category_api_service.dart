import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

part 'category_api_service.g.dart';

/// Riverpod-generated provider for [CategoryApiService].
@riverpod
CategoryApiService categoryApiService(Ref ref) {
  final dio = ref.watch(apiClientProvider);
  return CategoryApiService(dio);
}

/// Makes raw HTTP calls to `GET /categories` — only used to populate the
/// promotion form's category multi-select picker.
class CategoryApiService {
  final Dio _dio;

  CategoryApiService(this._dio);

  Future<List<Map<String, dynamic>>> getList({String? search, required int limit}) async {
    final response = await _dio.get(
      ApiEndpoints.categories,
      queryParameters: {
        'page': 1,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final data = response.data;
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).cast<Map<String, dynamic>>();
    }
    return const [];
  }
}

import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/category_option_model.dart';
import '../../services/category_api_service.dart';
import 'category_option_repository.dart';

const int _categoryOptionsLimit = 200;

/// Concrete implementation of [CategoryOptionRepository].
class CategoryOptionRepositoryImpl implements CategoryOptionRepository {
  final CategoryApiService _apiService;

  CategoryOptionRepositoryImpl(this._apiService);

  @override
  Future<List<CategoryOption>> getCategoryOptions({String? search}) async {
    try {
      final raw = await _apiService.getList(search: search, limit: _categoryOptionsLimit);
      return raw.map(CategoryOption.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException(
        message: e.response?.data?['message']?.toString() ?? e.message ?? 'Lỗi kết nối máy chủ',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}

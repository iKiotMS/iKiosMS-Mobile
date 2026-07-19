import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/product_item_option_model.dart';
import '../../services/product_item_api_service.dart';
import 'product_item_option_repository.dart';

const int _productItemOptionsLimit = 200;

/// Concrete implementation of [ProductItemOptionRepository].
class ProductItemOptionRepositoryImpl implements ProductItemOptionRepository {
  final ProductItemApiService _apiService;

  ProductItemOptionRepositoryImpl(this._apiService);

  @override
  Future<List<ProductItemOption>> getProductItemOptions({String? search}) async {
    try {
      final raw = await _apiService.listItems(search: search, limit: _productItemOptionsLimit);
      return raw.map(ProductItemOption.fromJson).toList();
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

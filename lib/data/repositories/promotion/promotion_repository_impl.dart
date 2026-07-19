import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/promotion_model.dart';
import '../../services/promotion_api_service.dart';
import 'promotion_repository.dart';

/// Concrete implementation of [PromotionRepository].
class PromotionRepositoryImpl implements PromotionRepository {
  final PromotionApiService _apiService;

  PromotionRepositoryImpl(this._apiService);

  Future<T> _run<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException(
        message:
            e.response?.data?['message']?.toString() ??
            e.message ??
            'Lỗi kết nối máy chủ',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<List<PromotionModel>> getList({
    String? search,
    String? status,
    required int page,
    required int limit,
  }) {
    return _run(() async {
      final raw = await _apiService.getList(
        search: search,
        status: status,
        page: page,
        limit: limit,
      );
      return (raw['data'] as List)
          .map((e) => PromotionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<PromotionModel> getDetail(String id) {
    return _run(() async {
      final raw = await _apiService.getDetail(id);
      return PromotionModel.fromJson(raw);
    });
  }

  @override
  Future<List<PromotionLogModel>> getLogs(
    String id, {
    required int page,
    required int limit,
  }) {
    return _run(() async {
      final raw = await _apiService.getLogs(id, page: page, limit: limit);
      return (raw['data'] as List)
          .map((e) => PromotionLogModel.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<PromotionModel> create(PromotionFormPayload payload) {
    return _run(() async {
      final raw = await _apiService.create(payload);
      return PromotionModel.fromJson(raw);
    });
  }

  @override
  Future<PromotionModel> update(String id, PromotionFormPayload payload) {
    return _run(() async {
      final raw = await _apiService.update(id, payload);
      return PromotionModel.fromJson(raw);
    });
  }

  @override
  Future<PromotionModel> remove(String id) {
    return _run(() async {
      final raw = await _apiService.remove(id);
      return PromotionModel.fromJson(raw);
    });
  }
}

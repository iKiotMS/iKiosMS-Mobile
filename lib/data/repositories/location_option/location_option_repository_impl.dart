import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/location_option_model.dart';
import '../../services/location_option_api_service.dart';
import 'location_option_repository.dart';

/// Concrete implementation of [LocationOptionRepository].
class LocationOptionRepositoryImpl implements LocationOptionRepository {
  final LocationOptionApiService _apiService;

  LocationOptionRepositoryImpl(this._apiService);

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
  Future<List<LocationOption>> getLocationOptions() {
    return _run(() async {
      final results = await Future.wait([_apiService.getBranches(), _apiService.getWarehouses()]);
      final branches = results[0].map((e) => LocationOption.fromJson(e, 'branch'));
      final warehouses = results[1].map((e) => LocationOption.fromJson(e, 'warehouse'));
      return [...branches, ...warehouses];
    });
  }

  @override
  Future<List<LocationOption>> getBranchOptions() {
    return _run(() async {
      final raw = await _apiService.getBranches();
      return raw.map((e) => LocationOption.fromJson(e, 'branch')).toList();
    });
  }
}

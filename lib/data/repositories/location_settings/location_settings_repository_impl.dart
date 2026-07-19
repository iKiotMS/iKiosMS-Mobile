import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/location_settings_model.dart';
import '../../services/location_settings_api_service.dart';
import 'location_settings_repository.dart';

/// Concrete implementation of [LocationSettingsRepository].
class LocationSettingsRepositoryImpl implements LocationSettingsRepository {
  final LocationSettingsApiService _apiService;

  LocationSettingsRepositoryImpl(this._apiService);

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
  Future<LocationSettingsModel> getBranch(String id) {
    return _run(() async {
      final raw = await _apiService.getBranch(id);
      return LocationSettingsModel.fromBranchJson(raw);
    });
  }

  @override
  Future<LocationSettingsModel> updateBranch({
    required String id,
    required String name,
    String? phoneNumber,
    String? address,
  }) {
    return _run(() async {
      final raw = await _apiService.updateBranch(
        id: id,
        name: name,
        phoneNumber: phoneNumber,
        address: address,
      );
      return LocationSettingsModel.fromBranchJson(raw);
    });
  }

  @override
  Future<LocationSettingsModel> getWarehouse(String id) {
    return _run(() async {
      final raw = await _apiService.getWarehouse(id);
      return LocationSettingsModel.fromWarehouseJson(raw);
    });
  }

  @override
  Future<LocationSettingsModel> updateWarehouse({
    required String id,
    required String name,
    String? address,
  }) {
    return _run(() async {
      final raw = await _apiService.updateWarehouse(id: id, name: name, address: address);
      return LocationSettingsModel.fromWarehouseJson(raw);
    });
  }
}

import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/staff_model.dart';
import '../../services/staff_api_service.dart';
import 'staff_repository.dart';

class StaffRepositoryImpl implements StaffRepository {
  final StaffApiService _apiService;

  StaffRepositoryImpl(this._apiService);

  @override
  Future<StaffListResult> getList({
    int page = 1,
    int recordPerPage = 50,
    String? keyword,
    String? status,
    String? role,
  }) async {
    try {
      final raw = await _apiService.getList(
        page: page,
        recordPerPage: recordPerPage,
        keyword: keyword,
        status: status,
        role: role,
      );
      final items = _extractList(raw)
          .map(StaffModel.fromJson)
          .where((s) => s.status != 'DELETED')
          .toList();
      final pagination = raw['pagination'] as Map<String, dynamic>?;
      final total = pagination?['total'] as int? ?? items.length;
      final record = pagination?['recordPerPage'] as int? ?? recordPerPage;
      final totalPages = pagination?['totalPages'] as int? ??
          pagination?['totalPage'] as int? ??
          (record == 0 ? 1 : (total / record).ceil().clamp(1, 9999));

      return StaffListResult(
        data: items,
        total: total,
        page: pagination?['page'] as int? ?? page,
        totalPages: totalPages,
      );
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<StaffModel> create(StaffFormFields input) async {
    try {
      final raw = await _apiService.create(input.toCreateJson());
      final data = raw['data'] is Map
          ? Map<String, dynamic>.from(raw['data'] as Map)
          : raw;
      final staff = StaffModel.fromJson(data);

      if (input.hasPassword) {
        await _apiService.createAccount(
          staff.id,
          StaffPasswordInput(
            newPassword: input.newPassword!,
            reEnterPassword: input.reEnterPassword!,
          ).toJson(),
        );
      }

      if (input.annualLeaveDays != null) {
        await _apiService.createLeaveBalance(staff.id, input.annualLeaveDays!);
      }

      return staff;
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<void> update(String staffId, StaffFormFields input) async {
    try {
      await _apiService.update(staffId, input.toUpdateJson());
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  @override
  Future<void> createAccount(String staffId, StaffPasswordInput input) async {
    try {
      await _apiService.createAccount(staffId, input.toJson());
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  @override
  Future<void> updatePassword(String staffId, StaffPasswordInput input) async {
    try {
      await _apiService.updatePassword(staffId, input.toJson());
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  @override
  Future<void> deactivateAccount(String staffId) async {
    try {
      await _apiService.deactivateAccount(staffId);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  @override
  Future<void> remove(String staffId) async {
    try {
      await _apiService.remove(staffId);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  @override
  Future<void> upsertLeaveBalance(
    String staffId,
    int annualLeaveDays, {
    required bool exists,
  }) async {
    try {
      if (exists) {
        await _apiService.updateLeaveBalance(staffId, annualLeaveDays);
      } else {
        await _apiService.createLeaveBalance(staffId, annualLeaveDays);
      }
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  @override
  Future<List<StaffModel>> getActiveStaffOptions() async {
    final result = await getList(page: 1, recordPerPage: 100, status: 'ACTIVE');
    return result.data.where((s) => s.role == 'STAFF').toList();
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> raw) {
    final data = raw['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  ApiException _toApiException(DioException e) => ApiException.fromDio(e);
}

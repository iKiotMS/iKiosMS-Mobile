import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/shift_template_model.dart';
import '../../models/working_schedule_admin_model.dart';
import '../../services/schedule_admin_api_service.dart';
import 'schedule_admin_repository.dart';

class ScheduleAdminRepositoryImpl implements ScheduleAdminRepository {
  final ScheduleAdminApiService _apiService;

  ScheduleAdminRepositoryImpl(this._apiService);

  @override
  Future<List<ShiftTemplateModel>> getShiftTemplates() async {
    try {
      final raw = await _apiService.getShiftTemplates();
      return _extractList(raw)
          .map(ShiftTemplateModel.fromJson)
          .where((t) => t.status != 'DELETED')
          .toList();
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<ShiftTemplateModel> createShiftTemplate(
    CreateShiftTemplateInput input,
  ) async {
    try {
      final raw = await _apiService.createShiftTemplate(input.toJson());
      final data = raw['data'] is Map
          ? Map<String, dynamic>.from(raw['data'] as Map)
          : raw;
      return ShiftTemplateModel.fromJson(data);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<ShiftTemplateModel> updateShiftTemplate(
    String id,
    CreateShiftTemplateInput input,
  ) async {
    try {
      final raw = await _apiService.updateShiftTemplate(id, input.toJson());
      final data = raw['data'] is Map
          ? Map<String, dynamic>.from(raw['data'] as Map)
          : raw;
      return ShiftTemplateModel.fromJson(data);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<void> deleteShiftTemplate(String id) async {
    try {
      await _apiService.deleteShiftTemplate(id);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  @override
  Future<WorkingScheduleListResult> getSchedules({
    int page = 1,
    int recordPerPage = 50,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final raw = await _apiService.getBranchSchedules(
        page: page,
        recordPerPage: recordPerPage,
        startDate: startDate,
        endDate: endDate,
      );
      final items = _extractList(raw)
          .map(WorkingScheduleAdminModel.fromJson)
          .where((s) => !s.isDeleted)
          .toList();
      final pagination = raw['pagination'] as Map<String, dynamic>?;
      final total = pagination?['total'] as int? ?? items.length;
      final record = pagination?['recordPerPage'] as int? ?? recordPerPage;
      final totalPages = pagination?['totalPages'] as int? ??
          pagination?['totalPage'] as int? ??
          (record == 0 ? 1 : (total / record).ceil().clamp(1, 9999));

      return WorkingScheduleListResult(
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
  Future<List<WorkingScheduleAdminModel>> createBulk(
    List<CreateWorkingScheduleInput> schedules,
  ) async {
    try {
      final raw = await _apiService.createBulkSchedules(
        schedules.map((s) => s.toJson()).toList(),
      );
      return _extractList(raw).map(WorkingScheduleAdminModel.fromJson).toList();
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<void> deleteSchedule(String id) async {
    try {
      await _apiService.deleteSchedule(id);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
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

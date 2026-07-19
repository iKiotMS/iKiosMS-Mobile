import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../models/leave_request_model.dart';
import '../../services/leave_request_api_service.dart';
import 'leave_request_repository.dart';

class LeaveRequestRepositoryImpl implements LeaveRequestRepository {
  final LeaveRequestApiService _apiService;

  LeaveRequestRepositoryImpl(this._apiService);

  @override
  Future<LeaveRequestListResult> getList({
    int page = 1,
    int recordPerPage = 50,
    String? status,
    String? keyword,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final raw = await _apiService.getList(
        page: page,
        recordPerPage: recordPerPage,
        status: status,
        keyword: keyword,
        startDate: startDate,
        endDate: endDate,
      );
      final items = _extractList(raw).map(LeaveRequestModel.fromJson).toList();
      final pagination = raw['pagination'] as Map<String, dynamic>?;
      final total = pagination?['total'] as int? ?? items.length;
      final record = pagination?['recordPerPage'] as int? ?? recordPerPage;
      final totalPages = pagination?['totalPages'] as int? ??
          pagination?['totalPage'] as int? ??
          (record == 0 ? 1 : (total / record).ceil().clamp(1, 9999));

      return LeaveRequestListResult(
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
  Future<void> approve(String id, ApproveLeaveInput input) async {
    try {
      await _apiService.approve(id, input.toJson());
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  @override
  Future<void> reject(String id, String reviewNote) async {
    try {
      await _apiService.reject(id, reviewNote);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  @override
  Future<LeaveRequestModel> createEmergency(
    CreateEmergencyLeaveInput input,
  ) async {
    try {
      final raw = await _apiService.createEmergency(input.toJson());
      final data = raw['data'] is Map
          ? Map<String, dynamic>.from(raw['data'] as Map)
          : raw;
      return LeaveRequestModel.fromJson(data);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<LeaveRequestModel> createPersonal(
    CreatePersonalLeaveInput input,
  ) async {
    try {
      final raw = await _apiService.createPersonal(input.toJson());
      final data = raw['data'] is Map
          ? Map<String, dynamic>.from(raw['data'] as Map)
          : raw;
      return LeaveRequestModel.fromJson(data);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<void> cancel(String id) async {
    try {
      await _apiService.cancel(id);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  @override
  Future<({int annual, int remaining, int used})> getBalance() async {
    try {
      final raw = await _apiService.getBalance();
      final data = raw['data'] is Map
          ? Map<String, dynamic>.from(raw['data'] as Map)
          : raw;
      return (
        annual: int.tryParse(data['annualLeaveDays']?.toString() ?? '') ?? 12,
        remaining:
            int.tryParse(data['remainingDays']?.toString() ?? '') ?? 12,
        used: int.tryParse(data['usedDays']?.toString() ?? '') ?? 0,
      );
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  @override
  Future<HandoverPreview> previewHandover({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final raw = await _apiService.previewHandover(
        startDate: startDate,
        endDate: endDate,
      );
      return HandoverPreview.fromJson(raw);
    } on DioException catch (e) {
      throw _toApiException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
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

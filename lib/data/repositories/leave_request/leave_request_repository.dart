import '../../models/leave_request_model.dart';

abstract class LeaveRequestRepository {
  Future<LeaveRequestListResult> getList({
    int page = 1,
    int recordPerPage = 50,
    String? status,
    String? keyword,
    String? startDate,
    String? endDate,
  });

  Future<void> approve(String id, ApproveLeaveInput input);

  Future<void> reject(String id, String reviewNote);

  Future<LeaveRequestModel> createEmergency(CreateEmergencyLeaveInput input);

  Future<LeaveRequestModel> createPersonal(CreatePersonalLeaveInput input);

  Future<void> cancel(String id);

  Future<({int annual, int remaining, int used})> getBalance();

  Future<HandoverPreview> previewHandover({
    required String startDate,
    required String endDate,
  });
}

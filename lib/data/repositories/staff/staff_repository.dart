import '../../models/staff_model.dart';

abstract class StaffRepository {
  Future<StaffListResult> getList({
    int page = 1,
    int recordPerPage = 50,
    String? keyword,
    String? status,
    String? role,
  });

  Future<StaffModel> create(StaffFormFields input);

  Future<void> update(String staffId, StaffFormFields input);

  Future<void> createAccount(String staffId, StaffPasswordInput input);

  Future<void> updatePassword(String staffId, StaffPasswordInput input);

  Future<void> deactivateAccount(String staffId);

  Future<void> remove(String staffId);

  Future<void> upsertLeaveBalance(
    String staffId,
    int annualLeaveDays, {
    required bool exists,
  });

  Future<List<StaffModel>> getActiveStaffOptions();
}

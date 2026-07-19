import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../data/models/shift_template_model.dart';
import '../../../data/models/staff_model.dart';
import '../../../data/models/working_schedule_admin_model.dart';
import '../../../data/repositories/schedule_admin/schedule_admin_repository.dart';
import '../../../data/repositories/schedule_admin/schedule_admin_repository_provider.dart';
import '../../../data/repositories/staff/staff_repository.dart';
import '../../../data/repositories/staff/staff_repository_provider.dart';
import '../../auth/viewmodels/user_profile_provider.dart';

part 'shift_management_view_model.g.dart';

class ShiftManagementState {
  final List<WorkingScheduleAdminModel> schedules;
  final List<ShiftTemplateModel> templates;
  final List<StaffModel> staffOptions;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;
  final DateTime month;
  final String? staffFilterId;

  const ShiftManagementState({
    this.schedules = const [],
    this.templates = const [],
    this.staffOptions = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
    required this.month,
    this.staffFilterId,
  });

  List<WorkingScheduleAdminModel> get visibleSchedules {
    if (staffFilterId == null || staffFilterId!.isEmpty) return schedules;
    return schedules
        .where(
          (s) => s.assignees.any((a) => a.userId == staffFilterId),
        )
        .toList();
  }

  ShiftManagementState copyWith({
    List<WorkingScheduleAdminModel>? schedules,
    List<ShiftTemplateModel>? templates,
    List<StaffModel>? staffOptions,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    DateTime? month,
    String? staffFilterId,
    bool clearStaffFilter = false,
  }) {
    return ShiftManagementState(
      schedules: schedules ?? this.schedules,
      templates: templates ?? this.templates,
      staffOptions: staffOptions ?? this.staffOptions,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      month: month ?? this.month,
      staffFilterId:
          clearStaffFilter ? null : (staffFilterId ?? this.staffFilterId),
    );
  }
}

@riverpod
class ShiftManagementViewModel extends _$ShiftManagementViewModel {
  @override
  ShiftManagementState build() {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month, 1);
    Future.microtask(() => _loadAll(month));
    return ShiftManagementState(isLoading: true, month: month);
  }

  ScheduleAdminRepository get _scheduleRepo =>
      ref.read(scheduleAdminRepositoryProvider);
  StaffRepository get _staffRepo => ref.read(staffRepositoryProvider);

  Future<void> load() async => _loadAll(state.month);

  void setStaffFilter(String? staffId) {
    state = state.copyWith(
      staffFilterId: staffId,
      clearStaffFilter: staffId == null,
    );
  }

  Future<void> changeMonth(DateTime month) async {
    final normalized = DateTime(month.year, month.month, 1);
    state = state.copyWith(month: normalized, isLoading: true, clearError: true);
    await _loadSchedules(normalized);
  }

  Future<void> _loadAll(DateTime month) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final results = await Future.wait([
        _fetchSchedules(month),
        _scheduleRepo.getShiftTemplates(),
        _staffRepo.getActiveStaffOptions(),
      ]);
      final schedules = results[0] as List<WorkingScheduleAdminModel>;
      final templates = results[1] as List<ShiftTemplateModel>;
      final staff = results[2] as List<StaffModel>;
      state = state.copyWith(
        schedules: schedules,
        templates: templates,
        staffOptions: staff,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is ApiException
            ? e.message
            : 'Không thể tải dữ liệu ca làm.',
      );
    }
  }

  Future<void> _loadSchedules(DateTime month) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final schedules = await _fetchSchedules(month);
      state = state.copyWith(schedules: schedules, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is ApiException
            ? e.message
            : 'Không thể tải dữ liệu ca làm.',
      );
    }
  }

  Future<List<WorkingScheduleAdminModel>> _fetchSchedules(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0);
    final result = await _scheduleRepo.getSchedules(
      startDate: DateTimeUtils.formatApiDate(start),
      endDate: DateTimeUtils.formatApiDate(end),
      recordPerPage: 100,
    );
    final sorted = [...result.data]
      ..sort((a, b) => a.workDate.compareTo(b.workDate));
    return sorted;
  }

  Future<bool> createTemplate(CreateShiftTemplateInput input) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      await _scheduleRepo.createShiftTemplate(input);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Đã tạo ca mẫu.',
      );
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            e is ApiException ? e.message : 'Không thể tạo ca mẫu.',
      );
      return false;
    }
  }

  Future<bool> deleteTemplate(String id) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      await _scheduleRepo.deleteShiftTemplate(id);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Đã xóa ca mẫu.',
      );
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            e is ApiException ? e.message : 'Không thể xóa ca mẫu.',
      );
      return false;
    }
  }

  Future<bool> updateTemplate(
    String id,
    CreateShiftTemplateInput input,
  ) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      await _scheduleRepo.updateShiftTemplate(id, input);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Đã cập nhật ca mẫu.',
      );
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            e is ApiException ? e.message : 'Không thể cập nhật ca mẫu.',
      );
      return false;
    }
  }

  Future<bool> createSchedule({
    required List<String> userIds,
    required String shiftTemplateId,
    required List<String> workDates,
    String scheduleType = 'NORMAL',
  }) async {
    if (userIds.isEmpty || workDates.isEmpty) {
      state = state.copyWith(errorMessage: 'Chọn nhân viên và ngày làm việc.');
      return false;
    }
    if (shiftTemplateId.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Chọn ca mẫu.');
      return false;
    }
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      final payloads = workDates
          .map(
            (date) => CreateWorkingScheduleInput(
              userIds: userIds,
              shiftTemplateId: shiftTemplateId,
              workDate: date,
              scheduleType: scheduleType,
            ),
          )
          .toList();
      await _scheduleRepo.createBulk(payloads);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Đã phân ca thành công.',
      );
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            e is ApiException ? e.message : 'Không thể phân ca.',
      );
      return false;
    }
  }

  Future<bool> deleteSchedule(String id) async {
    final profile = ref.read(userProfileProvider).valueOrNull;
    final schedule = state.schedules.where((s) => s.id == id).firstOrNull;
    if (profile?.role == 'BRANCH_MANAGER' &&
        profile?.id != null &&
        schedule != null &&
        schedule.assignees.any((a) => a.userId == profile!.id)) {
      state = state.copyWith(
        errorMessage: 'Bạn không thể xóa ca làm của chính mình.',
      );
      return false;
    }
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      await _scheduleRepo.deleteSchedule(id);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Đã xóa lịch làm.',
      );
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            e is ApiException ? e.message : 'Không thể xóa lịch làm.',
      );
      return false;
    }
  }

  /// FE pattern: edit = DELETE then bulk create.
  Future<bool> editSchedule({
    required String scheduleId,
    required List<String> userIds,
    required String shiftTemplateId,
    required String workDate,
    String scheduleType = 'NORMAL',
  }) async {
    if (userIds.isEmpty) {
      state = state.copyWith(errorMessage: 'Chọn ít nhất một nhân viên.');
      return false;
    }
    if (shiftTemplateId.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Chọn ca mẫu.');
      return false;
    }
    final profile = ref.read(userProfileProvider).valueOrNull;
    final schedule =
        state.schedules.where((s) => s.id == scheduleId).firstOrNull;
    if (profile?.role == 'BRANCH_MANAGER' &&
        profile?.id != null &&
        schedule != null &&
        schedule.assignees.any((a) => a.userId == profile!.id)) {
      state = state.copyWith(
        errorMessage: 'Bạn không thể sửa ca làm của chính mình.',
      );
      return false;
    }
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      await _scheduleRepo.deleteSchedule(scheduleId);
      await _scheduleRepo.createBulk([
        CreateWorkingScheduleInput(
          userIds: userIds,
          shiftTemplateId: shiftTemplateId,
          workDate: workDate,
          scheduleType: scheduleType,
        ),
      ]);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Đã cập nhật lịch làm.',
      );
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            e is ApiException ? e.message : 'Không thể sửa lịch làm.',
      );
      await load();
      return false;
    }
  }
}

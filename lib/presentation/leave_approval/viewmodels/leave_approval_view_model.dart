import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../data/models/leave_request_model.dart';
import '../../../data/models/staff_model.dart';
import '../../../data/repositories/leave_request/leave_request_repository.dart';
import '../../../data/repositories/leave_request/leave_request_repository_provider.dart';
import '../../../data/repositories/staff/staff_repository.dart';
import '../../../data/repositories/staff/staff_repository_provider.dart';
import '../../auth/viewmodels/user_profile_provider.dart';

part 'leave_approval_view_model.g.dart';

class LeaveApprovalState {
  final List<LeaveRequestModel> requests;
  final List<StaffModel> staffOptions;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;
  final String? statusFilter;
  final String keyword;
  final int? remainingLeaveDays;
  final DateTime? filterStart;
  final DateTime? filterEnd;

  const LeaveApprovalState({
    this.requests = const [],
    this.staffOptions = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
    this.statusFilter = 'PENDING',
    this.keyword = '',
    this.remainingLeaveDays,
    this.filterStart,
    this.filterEnd,
  });

  LeaveApprovalState copyWith({
    List<LeaveRequestModel>? requests,
    List<StaffModel>? staffOptions,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    String? statusFilter,
    bool clearStatusFilter = false,
    String? keyword,
    int? remainingLeaveDays,
    DateTime? filterStart,
    DateTime? filterEnd,
    bool clearDateFilter = false,
  }) {
    return LeaveApprovalState(
      requests: requests ?? this.requests,
      staffOptions: staffOptions ?? this.staffOptions,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      keyword: keyword ?? this.keyword,
      remainingLeaveDays: remainingLeaveDays ?? this.remainingLeaveDays,
      filterStart: clearDateFilter ? null : (filterStart ?? this.filterStart),
      filterEnd: clearDateFilter ? null : (filterEnd ?? this.filterEnd),
    );
  }
}

@riverpod
class LeaveApprovalViewModel extends _$LeaveApprovalViewModel {
  @override
  LeaveApprovalState build() {
    Future.microtask(_bootstrap);
    return const LeaveApprovalState(isLoading: true);
  }

  LeaveRequestRepository get _leaveRepo =>
      ref.read(leaveRequestRepositoryProvider);
  StaffRepository get _staffRepo => ref.read(staffRepositoryProvider);

  String? get currentUserId =>
      ref.read(userProfileProvider).valueOrNull?.id;

  String? get currentUserRole =>
      ref.read(userProfileProvider).valueOrNull?.role;

  bool get canCreatePersonalLeave => currentUserRole == 'BRANCH_MANAGER';

  Future<void> _bootstrap() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final listFuture = _leaveRepo.getList(
        status: state.statusFilter,
        keyword: state.keyword,
        startDate: state.filterStart == null
            ? null
            : DateTimeUtils.formatApiDate(state.filterStart!),
        endDate: state.filterEnd == null
            ? null
            : DateTimeUtils.formatApiDate(state.filterEnd!),
        recordPerPage: 50,
      );
      final staffFuture = _staffRepo.getActiveStaffOptions();
      final list = await listFuture;
      final staff = await staffFuture;
      int? remaining = state.remainingLeaveDays;
      try {
        remaining = (await _leaveRepo.getBalance()).remaining;
      } catch (_) {}
      state = state.copyWith(
        requests: list.data,
        staffOptions: staff,
        remainingLeaveDays: remaining,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is ApiException
            ? e.message
            : 'Không thể tải đơn nghỉ phép.',
      );
    }
  }

  /// Chỉ reload danh sách (filter/search) — không gọi lại staff/balance.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final result = await _leaveRepo.getList(
        status: state.statusFilter,
        keyword: state.keyword,
        startDate: state.filterStart == null
            ? null
            : DateTimeUtils.formatApiDate(state.filterStart!),
        endDate: state.filterEnd == null
            ? null
            : DateTimeUtils.formatApiDate(state.filterEnd!),
        recordPerPage: 50,
      );
      state = state.copyWith(requests: result.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is ApiException
            ? e.message
            : 'Không thể tải đơn nghỉ phép.',
      );
    }
  }

  Future<void> search(String keyword) async {
    state = state.copyWith(keyword: keyword);
    await load();
  }

  Future<void> setStatusFilter(String? status) async {
    state = state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
    );
    await load();
  }

  Future<void> setDateFilter({DateTime? start, DateTime? end}) async {
    state = state.copyWith(
      filterStart: start,
      filterEnd: end,
      clearDateFilter: start == null && end == null,
    );
    await load();
  }

  Future<bool> approve(
    LeaveRequestModel request,
    ApproveLeaveInput input,
  ) async {
    final total = input.paidLeaveDays + input.unpaidLeaveDays;
    if (total <= 0) {
      state = state.copyWith(errorMessage: 'Tổng ngày phép phải lớn hơn 0.');
      return false;
    }
    if (total > request.totalDays) {
      state = state.copyWith(
        errorMessage:
            'Tổng ngày phép không được vượt quá ${request.totalDays} ngày.',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      await _leaveRepo.approve(request.id, input);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Đã duyệt đơn nghỉ phép.',
      );
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            e is ApiException ? e.message : 'Không thể duyệt đơn.',
      );
      return false;
    }
  }

  Future<bool> reject(String id, String reviewNote) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      await _leaveRepo.reject(id, reviewNote);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Đã từ chối đơn nghỉ phép.',
      );
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            e is ApiException ? e.message : 'Không thể từ chối đơn.',
      );
      return false;
    }
  }

  Future<bool> createEmergency(
    CreateEmergencyLeaveInput input, {
    bool approveImmediately = false,
    int? paidLeaveDays,
    int? unpaidLeaveDays,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      final created = await _leaveRepo.createEmergency(input);
      if (approveImmediately) {
        final totalDays = created.totalDays;
        await _leaveRepo.approve(
          created.id,
          ApproveLeaveInput(
            paidLeaveDays: paidLeaveDays ?? totalDays,
            unpaidLeaveDays: unpaidLeaveDays ?? 0,
            reviewNote: 'Duyệt kèm đơn khẩn',
          ),
        );
      }
      state = state.copyWith(
        isSubmitting: false,
        successMessage: approveImmediately
            ? 'Đã tạo và duyệt đơn nghỉ khẩn.'
            : 'Đã tạo đơn nghỉ khẩn.',
      );
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e is ApiException
            ? e.message
            : 'Không thể tạo đơn nghỉ khẩn.',
      );
      return false;
    }
  }

  Future<bool> createPersonal(CreatePersonalLeaveInput input) async {
    if (!canCreatePersonalLeave) {
      state = state.copyWith(
        errorMessage: 'Chỉ quản lý chi nhánh tạo đơn nghỉ trên màn này.',
      );
      return false;
    }
    if (input.handoverToUserId == null || input.handoverToUserId!.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Quản lý chi nhánh cần chọn người bàn giao.',
      );
      return false;
    }
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      await _leaveRepo.createPersonal(input);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Đã gửi đơn xin nghỉ phép.',
      );
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            e is ApiException ? e.message : 'Không thể tạo đơn nghỉ phép.',
      );
      return false;
    }
  }

  Future<HandoverPreview?> previewHandover({
    required String startDate,
    required String endDate,
  }) async {
    try {
      return await _leaveRepo.previewHandover(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (_) {
      // Không chặn form xin nghỉ — BM vẫn bắt buộc chọn handover.
      return null;
    }
  }

  Future<bool> cancel(String id) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      await _leaveRepo.cancel(id);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Đã hủy đơn nghỉ phép.',
      );
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            e is ApiException ? e.message : 'Không thể hủy đơn nghỉ phép.',
      );
      return false;
    }
  }
}

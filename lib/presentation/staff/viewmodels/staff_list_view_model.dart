import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/staff_model.dart';
import '../../../data/repositories/staff/staff_repository.dart';
import '../../../data/repositories/staff/staff_repository_provider.dart';
import '../../auth/viewmodels/user_profile_provider.dart';

part 'staff_list_view_model.g.dart';

class StaffListState {
  final List<StaffModel> staff;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;
  final String keyword;
  final String? statusFilter;
  final String? roleFilter;
  /// Chi nhánh khóa theo BM session.
  final String? lockedBranchId;

  const StaffListState({
    this.staff = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
    this.keyword = '',
    this.statusFilter,
    this.roleFilter,
    this.lockedBranchId,
  });

  StaffListState copyWith({
    List<StaffModel>? staff,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    String? keyword,
    String? statusFilter,
    bool clearStatusFilter = false,
    String? roleFilter,
    bool clearRoleFilter = false,
    String? lockedBranchId,
    bool clearLockedBranchId = false,
  }) {
    return StaffListState(
      staff: staff ?? this.staff,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      keyword: keyword ?? this.keyword,
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      roleFilter: clearRoleFilter ? null : (roleFilter ?? this.roleFilter),
      lockedBranchId: clearLockedBranchId
          ? null
          : (lockedBranchId ?? this.lockedBranchId),
    );
  }
}

@riverpod
class StaffListViewModel extends _$StaffListViewModel {
  @override
  StaffListState build() {
    final profile = ref.read(userProfileProvider).valueOrNull;
    final locked = profile?.branchId?.trim();
    Future.microtask(loadStaff);
    return StaffListState(
      isLoading: true,
      lockedBranchId: (locked != null && locked.isNotEmpty) ? locked : null,
    );
  }

  StaffRepository get _repository => ref.read(staffRepositoryProvider);

  String? get lockedBranchId {
    final fromState = state.lockedBranchId;
    if (fromState != null && fromState.isNotEmpty) return fromState;
    final fromProfile =
        ref.read(userProfileProvider).valueOrNull?.branchId?.trim();
    return (fromProfile != null && fromProfile.isNotEmpty) ? fromProfile : null;
  }

  Future<void> loadStaff() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final result = await _repository.getList(
        keyword: state.keyword,
        status: state.statusFilter,
        role: state.roleFilter,
        recordPerPage: 100,
      );
      state = state.copyWith(staff: result.data, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is ApiException
            ? e.message
            : 'Không thể tải danh sách nhân viên.',
      );
    }
  }

  Future<void> search(String keyword) async {
    state = state.copyWith(keyword: keyword);
    await loadStaff();
  }

  Future<void> setStatusFilter(String? status) async {
    state = state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
    );
    await loadStaff();
  }

  Future<void> setRoleFilter(String? role) async {
    state = state.copyWith(
      roleFilter: role,
      clearRoleFilter: role == null,
    );
    await loadStaff();
  }

  Future<bool> createStaff(StaffFormFields input) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      final branchId = input.branchId?.trim().isNotEmpty == true
          ? input.branchId!.trim()
          : lockedBranchId;

      if (branchId == null || branchId.isEmpty) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage:
              'Không xác định được chi nhánh. Đăng nhập lại bằng tài khoản quản lý chi nhánh.',
        );
        return false;
      }

      await _repository.create(
        StaffFormFields(
          firstName: input.firstName,
          lastName: input.lastName,
          phoneNumber: input.phoneNumber,
          email: input.email,
          hireDate: input.hireDate,
          gender: input.gender,
          address: input.address,
          identificationId: input.identificationId,
          dob: input.dob,
          taxNumber: input.taxNumber,
          accountNote: input.accountNote,
          branchId: branchId,
          newPassword: input.newPassword,
          reEnterPassword: input.reEnterPassword,
          annualLeaveDays: input.annualLeaveDays,
        ),
      );
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Đã tạo nhân viên thành công.',
      );
      await loadStaff();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            e is ApiException ? e.message : 'Không thể tạo nhân viên.',
      );
      return false;
    }
  }

  Future<bool> updateStaff(String staffId, StaffFormFields input) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      final branchId = input.branchId?.trim().isNotEmpty == true
          ? input.branchId!.trim()
          : lockedBranchId;

      await _repository.update(
        staffId,
        StaffFormFields(
          firstName: input.firstName,
          lastName: input.lastName,
          phoneNumber: input.phoneNumber,
          email: input.email,
          hireDate: input.hireDate,
          gender: input.gender,
          address: input.address,
          identificationId: input.identificationId,
          dob: input.dob,
          taxNumber: input.taxNumber,
          accountNote: input.accountNote,
          branchId: branchId,
        ),
      );
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Đã cập nhật nhân viên.',
      );
      await loadStaff();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            e is ApiException ? e.message : 'Không thể cập nhật nhân viên.',
      );
      return false;
    }
  }

  Future<bool> activateStaff(String staffId, StaffPasswordInput input) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      await _repository.createAccount(staffId, input);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Đã kích hoạt tài khoản nhân viên.',
      );
      await loadStaff();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            e is ApiException ? e.message : 'Không thể kích hoạt tài khoản.',
      );
      return false;
    }
  }

  Future<bool> resetPassword(String staffId, StaffPasswordInput input) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      await _repository.updatePassword(staffId, input);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Đã đổi mật khẩu nhân viên.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            e is ApiException ? e.message : 'Không thể đổi mật khẩu.',
      );
      return false;
    }
  }

  Future<bool> deactivateStaff(String staffId) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      await _repository.deactivateAccount(staffId);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Đã ngưng tài khoản nhân viên.',
      );
      await loadStaff();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            e is ApiException ? e.message : 'Không thể ngưng tài khoản.',
      );
      return false;
    }
  }

  Future<bool> deleteStaff(String staffId) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      await _repository.remove(staffId);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Đã xóa nhân viên.',
      );
      await loadStaff();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            e is ApiException ? e.message : 'Không thể xóa nhân viên.',
      );
      return false;
    }
  }

  Future<bool> upsertLeaveBalance(
    String staffId,
    int annualLeaveDays, {
    required bool exists,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true);
    try {
      await _repository.upsertLeaveBalance(
        staffId,
        annualLeaveDays,
        exists: exists,
      );
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Đã cập nhật phép năm.',
      );
      await loadStaff();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            e is ApiException ? e.message : 'Không thể cập nhật phép năm.',
      );
      return false;
    }
  }
}

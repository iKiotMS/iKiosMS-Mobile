import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/models/location_settings_model.dart';
import '../../../data/repositories/location_settings/location_settings_repository.dart';
import '../../../data/repositories/location_settings/location_settings_repository_provider.dart';
import '../../auth/viewmodels/user_profile_provider.dart';

part 'location_settings_view_model.g.dart';

// ── State ─────────────────────────────────────────────────────────────────

/// Holds all UI state for "Setting chi nhánh, kho" — view/edit the caller's
/// OWN branch (BRANCH_MANAGER) or warehouse (WAREHOUSE_MANAGER) settings.
///
/// Deliberately scoped to a single, self-owned location: the web app's
/// `/settings` branches/warehouses tabs list and let you edit ANY location
/// in the tenant with no server-side ownership check — a decision was made
/// to not replicate that on mobile, and instead lock this screen to the
/// caller's own `branchId`/`warehouseId` client-side.
class LocationSettingsState {
  final bool isLoading;
  final bool isSaving;
  final LocationSettingsModel? settings;
  final String? errorMessage;

  /// True when the signed-in role has no single owned branch/warehouse
  /// (e.g. TENANT_OWNER) — this screen has nothing to show for them.
  final bool notApplicable;

  const LocationSettingsState({
    this.isLoading = false,
    this.isSaving = false,
    this.settings,
    this.errorMessage,
    this.notApplicable = false,
  });

  LocationSettingsState copyWith({
    bool? isLoading,
    bool? isSaving,
    LocationSettingsModel? settings,
    String? errorMessage,
    bool clearError = false,
    bool? notApplicable,
  }) {
    return LocationSettingsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      settings: settings ?? this.settings,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      notApplicable: notApplicable ?? this.notApplicable,
    );
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────

@riverpod
class LocationSettingsViewModel extends _$LocationSettingsViewModel {
  String? _locationId;
  String? _locationType; // 'branch' | 'warehouse'

  @override
  LocationSettingsState build() {
    Future.microtask(_init);
    return const LocationSettingsState(isLoading: true);
  }

  LocationSettingsRepository get _repository => ref.read(locationSettingsRepositoryProvider);

  Future<void> refetch() => _load();

  Future<void> _init() async {
    final profile = await ref.read(userProfileProvider.future);
    if (profile == null) {
      state = state.copyWith(isLoading: false, errorMessage: 'Không tìm thấy thông tin người dùng.');
      return;
    }

    if (profile.role == 'BRANCH_MANAGER') {
      _locationId = profile.branchId;
      _locationType = 'branch';
    } else if (profile.role == 'WAREHOUSE_MANAGER') {
      _locationId = profile.warehouseId;
      _locationType = 'warehouse';
    } else {
      state = state.copyWith(isLoading: false, notApplicable: true);
      return;
    }

    if (_locationId == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Tài khoản chưa được gán chi nhánh/kho.',
      );
      return;
    }

    await _load();
  }

  Future<void> _load() async {
    if (_locationId == null || _locationType == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final settings = _locationType == 'warehouse'
          ? await _repository.getWarehouse(_locationId!)
          : await _repository.getBranch(_locationId!);
      state = state.copyWith(settings: settings, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Tải thông tin thất bại');
    }
  }

  /// Returns an error message on failure, or null on success.
  Future<String?> save({required String name, String? phoneNumber, String? address}) async {
    final current = state.settings;
    if (_locationId == null || current == null) return 'Không xác định được chi nhánh/kho.';

    state = state.copyWith(isSaving: true);
    try {
      final updated = current.locationType == 'warehouse'
          ? await _repository.updateWarehouse(id: _locationId!, name: name, address: address)
          : await _repository.updateBranch(id: _locationId!, name: name, phoneNumber: phoneNumber, address: address);
      state = state.copyWith(settings: updated, isSaving: false);
      return null;
    } catch (e) {
      state = state.copyWith(isSaving: false);
      return 'Cập nhật thất bại';
    }
  }
}

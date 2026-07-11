import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_exception.dart';

import '../../../data/models/shift_model.dart';
import '../../../data/repositories/shift/shift_repository.dart';
import '../../../data/repositories/shift/shift_repository_provider.dart';

part 'shift_detail_view_model.g.dart';

// ── State ─────────────────────────────────────────────────────────────────────

/// Holds all UI state for the shift detail screen.
class ShiftDetailState {
  final ShiftModel? shift;
  final bool isLoading;
  final bool isCheckingIn;
  final String? errorMessage;
  final double? currentLatitude;
  final double? currentLongitude;

  const ShiftDetailState({
    this.shift,
    this.isLoading = false,
    this.isCheckingIn = false,
    this.errorMessage,
    this.currentLatitude,
    this.currentLongitude,
  });

  ShiftDetailState copyWith({
    ShiftModel? shift,
    bool? isLoading,
    bool? isCheckingIn,
    String? errorMessage,
    double? currentLatitude,
    double? currentLongitude,
    bool clearError = false,
  }) {
    return ShiftDetailState(
      shift: shift ?? this.shift,
      isLoading: isLoading ?? this.isLoading,
      isCheckingIn: isCheckingIn ?? this.isCheckingIn,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

/// Riverpod-generated notifier for the shift detail screen.
///
/// [shiftId] is passed as a family argument so each detail screen
/// has its own isolated provider instance.
@riverpod
class ShiftDetailViewModel extends _$ShiftDetailViewModel {
  @override
  ShiftDetailState build(String shiftId) {
    // Defer load until after build() returns — same reason as ScheduleViewModel.
    Future.microtask(() => _loadShift(shiftId));
    return const ShiftDetailState(isLoading: true);
  }

  ShiftRepository get _repository => ref.read(shiftRepositoryProvider);

  /// Reloads shift data from the backend.
  Future<void> loadShift(String shiftId) async {
    await _loadShift(shiftId);
  }

  /// Performs the check-in action for this shift.
  ///
  /// Shows a loading indicator on the button while the request is in-flight.
  /// The view reads [state.isCheckingIn] to disable/enable the button.
  Future<String?> checkIn() async {
    final shift = state.shift;
    if (shift == null || !shift.isCheckInEligible)
      return 'Lỗi: Không đủ điều kiện chấm công';

    state = state.copyWith(isCheckingIn: true, clearError: true);
    try {
      final updatedShift = await _repository.checkIn(shift.id);
      state = state.copyWith(shift: updatedShift, isCheckingIn: false);
      return null; // signal success to the view
    } catch (e) {
      String msg = 'Chấm công thất bại. Vui lòng thử lại.';
      if (e is ApiException) {
        msg = e.message;
      }
      state = state.copyWith(isCheckingIn: false, errorMessage: msg);
      return msg;
    }
  }

  Future<void> _loadShift(String shiftId) async {
    // build() already returns isLoading:true; only set it again on manual reload.
    if (state.shift != null || state.errorMessage != null) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final shift = await _repository.getShiftById(shiftId);

      // Also fetch live GPS coordinates for display
      double? lat;
      double? lon;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            Position position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
              ),
            );
            lat = position.latitude;
            lon = position.longitude;
          }
        }
      } catch (_) {
        // Ignore location errors here, it's just for UI display
      }

      state = state.copyWith(
        shift: shift,
        isLoading: false,
        currentLatitude: lat,
        currentLongitude: lon,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải thông tin ca làm.',
      );
    }
  }
}

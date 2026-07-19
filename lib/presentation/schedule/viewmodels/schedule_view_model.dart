import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/utils/date_time_utils.dart';
import '../../../data/models/shift_model.dart';
import '../../../data/repositories/shift/shift_repository.dart';
import '../../../data/repositories/shift/shift_repository_provider.dart';

part 'schedule_view_model.g.dart';

// ── State ─────────────────────────────────────────────────────────────────────

/// Holds all UI state for the schedule screen.
class ScheduleState {
  final List<ShiftModel> shifts;
  final bool isLoading;
  final String? errorMessage;
  final DateTime selectedWeekStart; // always a Monday
  final DateTime selectedWeekEnd; // always the following Sunday

  const ScheduleState({
    this.shifts = const [],
    this.isLoading = false,
    this.errorMessage,
    required this.selectedWeekStart,
    required this.selectedWeekEnd,
  });

  /// The currently active shift (status == 'active'), or null.
  ShiftModel? get currentShift {
    try {
      return shifts.firstWhere((s) => s.status == 'active');
    } catch (_) {
      return null;
    }
  }

  /// The next upcoming or scheduled shift, or null.
  ShiftModel? get nextShift {
    final now = DateTime.now();
    final upcoming = shifts.where((s) {
      return (s.status == 'upcoming' || s.status == 'scheduled') &&
          (s.date.isAfter(now) || DateTimeUtils.isSameDay(s.date, now));
    }).toList();
    if (upcoming.isEmpty) return null;
    // Sort by date ascending and take the first.
    upcoming.sort((a, b) => a.date.compareTo(b.date));
    return upcoming.first;
  }

  ScheduleState copyWith({
    List<ShiftModel>? shifts,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    DateTime? selectedWeekStart,
    DateTime? selectedWeekEnd,
  }) {
    return ScheduleState(
      shifts: shifts ?? this.shifts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedWeekStart: selectedWeekStart ?? this.selectedWeekStart,
      selectedWeekEnd: selectedWeekEnd ?? this.selectedWeekEnd,
    );
  }
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

/// Riverpod-generated notifier for the schedule screen.
///
/// Holds the selected week and the list of shifts.
/// The view reads [state] and calls methods on this notifier.
@riverpod
class ScheduleViewModel extends _$ScheduleViewModel {
  @override
  ScheduleState build() {
    // Start with the current week when the screen opens.
    final now = DateTime.now();
    final weekStart = DateTimeUtils.getStartOfWeek(now);
    final weekEnd = DateTimeUtils.getEndOfWeek(now);

    // Defer the first load until AFTER build() has returned.
    // Setting state directly inside build() crashes with
    // 'Tried to read the state of an uninitialized provider'.
    Future.microtask(() => _loadShifts(weekStart, weekEnd));

    return ScheduleState(
      selectedWeekStart: weekStart,
      selectedWeekEnd: weekEnd,
      isLoading: true, // show spinner immediately
    );
  }

  ShiftRepository get _repository => ref.read(shiftRepositoryProvider);

  /// Called by the view to load (or reload) shifts for the current week.
  Future<void> loadShifts() async {
    await _loadShifts(state.selectedWeekStart, state.selectedWeekEnd);
  }

  /// Called when the user picks a date in the date picker.
  ///
  /// Calculates the Mon-Sun week for the chosen date and reloads shifts.
  Future<void> selectDate(DateTime pickedDate) async {
    final weekStart = DateTimeUtils.getStartOfWeek(pickedDate);
    final weekEnd = DateTimeUtils.getEndOfWeek(pickedDate);
    state = state.copyWith(
      selectedWeekStart: weekStart,
      selectedWeekEnd: weekEnd,
      isLoading: true,
      clearError: true,
    );
    await _loadShifts(weekStart, weekEnd);
  }

  Future<void> _loadShifts(DateTime start, DateTime end) async {
    // Only set loading if we are already initialized (called from methods,
    // not from build). build() already returns isLoading:true as initial state.
    if (state.shifts.isNotEmpty || state.errorMessage != null) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final shifts = await _repository.getShifts(
        startDate: start,
        endDate: end,
      );
      // Sort shifts by date then startTime.
      shifts.sort((a, b) {
        final dateCmp = a.date.compareTo(b.date);
        if (dateCmp != 0) return dateCmp;
        return a.startTime.compareTo(b.startTime);
      });
      state = state.copyWith(shifts: shifts, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải lịch làm. Vui lòng thử lại.',
      );
    }
  }
}

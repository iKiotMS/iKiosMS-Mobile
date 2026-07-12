import '../../models/shift_model.dart';

/// Abstract interface for the shift repository.
///
/// The ViewModel depends on this interface, not the concrete implementation.
/// This makes it easy to swap implementations (e.g., for testing).
abstract class ShiftRepository {
  /// Fetches shifts for the given week range.
  Future<List<ShiftModel>> getShifts({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Fetches a single shift by ID.
  Future<ShiftModel> getShiftById(String shiftId);

  /// Checks the employee in to the given shift.
  Future<ShiftModel> checkIn(String shiftId);
}

import '../../models/location_option_model.dart';

/// Abstract interface for the location-option repository (branches +
/// warehouses combined, for the ADJUST location picker).
abstract class LocationOptionRepository {
  Future<List<LocationOption>> getLocationOptions();

  /// Branches only (no warehouses) — used by the promotion form's branch
  /// multi-select, since promotions are never warehouse-scoped.
  Future<List<LocationOption>> getBranchOptions();
}

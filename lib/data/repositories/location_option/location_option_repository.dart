import '../../models/location_option_model.dart';

/// Abstract interface for the location-option repository (branches +
/// warehouses combined, for the ADJUST location picker).
abstract class LocationOptionRepository {
  Future<List<LocationOption>> getLocationOptions();
}

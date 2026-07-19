import '../../models/location_settings_model.dart';

/// Abstract interface for viewing/editing the caller's own branch or
/// warehouse settings.
abstract class LocationSettingsRepository {
  Future<LocationSettingsModel> getBranch(String id);

  Future<LocationSettingsModel> updateBranch({
    required String id,
    required String name,
    String? phoneNumber,
    String? address,
  });

  Future<LocationSettingsModel> getWarehouse(String id);

  Future<LocationSettingsModel> updateWarehouse({
    required String id,
    required String name,
    String? address,
  });
}

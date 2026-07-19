/// A single branch or warehouse, as offered in the location picker shown
/// only to TENANT_OWNER when creating a stock adjustment (BRANCH_MANAGER/
/// WAREHOUSE_MANAGER never see this picker — their own location is used
/// automatically, mirroring `location_settings_view_model.dart`).
class LocationOption {
  final String id;
  final String name;
  final String type; // 'branch' | 'warehouse'

  const LocationOption({required this.id, required this.name, required this.type});

  factory LocationOption.fromJson(Map<String, dynamic> json, String type) {
    return LocationOption(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: type,
    );
  }
}

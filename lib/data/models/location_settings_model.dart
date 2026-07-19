/// Settings for a single branch or warehouse — the fields the web app's
/// `/settings` "Quản lý chi nhánh"/"Quản lý kho tổng" edit form actually
/// exposes (`name`, `phoneNumber`/`address` for branch; `name`/`address`
/// for warehouse). `status` is read-only here (Web's form doesn't expose
/// editing it either, and flipping it accidentally would deactivate the
/// caller's own location).
///
/// Maps to `iKiotMS-BE/src/models/Branch.js` / `Warehouse.js`.
class LocationSettingsModel {
  final String id;
  final String locationType; // 'branch' | 'warehouse'
  final String name;
  final String? phoneNumber; // branch only — BE stores an array, UI shows one
  final String? address;
  final String status; // ACTIVE | INACTIVE | DELETED

  const LocationSettingsModel({
    required this.id,
    required this.locationType,
    required this.name,
    this.phoneNumber,
    this.address,
    required this.status,
  });

  factory LocationSettingsModel.fromBranchJson(Map<String, dynamic> json) {
    final phones = json['phoneNumber'] as List?;
    return LocationSettingsModel(
      id: json['_id']?.toString() ?? '',
      locationType: 'branch',
      name: json['name']?.toString() ?? '',
      phoneNumber: (phones != null && phones.isNotEmpty) ? phones.first?.toString() : null,
      address: json['address']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }

  factory LocationSettingsModel.fromWarehouseJson(Map<String, dynamic> json) {
    return LocationSettingsModel(
      id: json['_id']?.toString() ?? '',
      locationType: 'warehouse',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }
}

const Map<String, String> locationStatusLabels = {
  'ACTIVE': 'Đang hoạt động',
  'INACTIVE': 'Ngừng hoạt động',
  'DELETED': 'Đã xoá',
};

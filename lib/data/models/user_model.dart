class UserModel {
  final String id;
  final String phoneNumber;
  final String email;
  final String role;
  final String? tenantId;
  final String? branchId;
  final String? warehouseId;
  final String firstName;
  final String lastName;
  final String status;

  const UserModel({
    required this.id,
    required this.phoneNumber,
    required this.email,
    required this.role,
    this.tenantId,
    this.branchId,
    this.warehouseId,
    required this.firstName,
    required this.lastName,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      tenantId: _resolveId(json['tenantId']),
      branchId: _resolveId(json['branchId']),
      warehouseId: _resolveId(json['warehouseId']),
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  factory UserModel.fromProfileJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      tenantId: _resolveId(json['tenantId']),
      branchId: _resolveId(json['branchId']),
      warehouseId: _resolveId(json['warehouseId']),
      firstName: profile?['firstName']?.toString() ?? '',
      lastName: profile?['lastName']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  static String? _resolveId(dynamic ref) {
    if (ref == null) return null;
    if (ref is String) {
      final value = ref.trim();
      return value.isEmpty ? null : value;
    }
    if (ref is Map) {
      final id = ref['_id']?.toString() ?? ref['id']?.toString();
      if (id == null || id.isEmpty) return null;
      return id;
    }
    final value = ref.toString();
    return value.isEmpty ? null : value;
  }

  String get fullName {
    final names = [firstName, lastName].where((n) => n.isNotEmpty).toList();
    if (names.isEmpty) return 'Nhân viên';
    return names.join(' ');
  }

  /// Vietnamese label for the user's role, matching the dashboard's wording.
  String get roleLabel {
    switch (role) {
      case 'TENANT_OWNER':
        return 'Chủ cửa hàng';
      case 'BRANCH_MANAGER':
        return 'Quản lý chi nhánh';
      case 'WAREHOUSE_MANAGER':
        return 'Quản lý kho';
      case 'STAFF':
        return 'Nhân viên';
      case 'SUPER_ADMIN':
        return 'Quản trị hệ thống';
      case 'CUSTOMER':
        return 'Khách hàng';
      default:
        return role;
    }
  }
}

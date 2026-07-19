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
      id: json['id']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      tenantId: json['tenantId']?.toString(),
      branchId: json['branchId']?.toString(),
      warehouseId: json['warehouseId']?.toString(),
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  factory UserModel.fromProfileJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    return UserModel(
      id: json['id']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      tenantId: json['tenantId']?.toString(),
      branchId: json['branchId']?.toString(),
      warehouseId: json['warehouseId']?.toString(),
      firstName: profile?['firstName']?.toString() ?? '',
      lastName: profile?['lastName']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
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

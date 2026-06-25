class UserModel {
  final String id;
  final String phoneNumber;
  final String role;
  final String? tenantId;
  final String firstName;
  final String lastName;
  final String status;

  const UserModel({
    required this.id,
    required this.phoneNumber,
    required this.role,
    this.tenantId,
    required this.firstName,
    required this.lastName,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      tenantId: json['tenantId']?.toString(),
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  String get fullName {
    final names = [firstName, lastName].where((n) => n.isNotEmpty).toList();
    if (names.isEmpty) return 'Nhân viên';
    return names.join(' ');
  }
}

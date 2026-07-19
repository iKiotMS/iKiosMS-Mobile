/// Staff member returned by GET /staff (Branch Manager scope).
class StaffModel {
  final String id;
  final String phoneNumber;
  final String? email;
  final String role;
  final String status;
  final String firstName;
  final String lastName;
  final String branchId;
  final String branchName;
  final String? warehouseId;
  final String? warehouseName;
  final int? annualLeaveDays;
  final int? remainingLeaveDays;
  final int? usedLeaveDays;
  final String? hireDate;
  final String? gender;
  final String? address;
  final String? identificationId;
  final String? dob;
  final String? taxNumber;
  final String? accountNote;
  final String? paySheetId;
  final String? paySheetName;

  const StaffModel({
    required this.id,
    required this.phoneNumber,
    this.email,
    required this.role,
    required this.status,
    required this.firstName,
    required this.lastName,
    this.branchId = '',
    this.branchName = '',
    this.warehouseId,
    this.warehouseName,
    this.annualLeaveDays,
    this.remainingLeaveDays,
    this.usedLeaveDays,
    this.hireDate,
    this.gender,
    this.address,
    this.identificationId,
    this.dob,
    this.taxNumber,
    this.accountNote,
    this.paySheetId,
    this.paySheetName,
  });

  String get fullName {
    final names = [lastName, firstName].where((n) => n.isNotEmpty).toList();
    if (names.isEmpty) return phoneNumber;
    return names.join(' ');
  }

  String get roleLabel {
    const labels = {
      'STAFF': 'Nhân viên',
      'BRANCH_MANAGER': 'Quản lý chi nhánh',
      'WAREHOUSE_MANAGER': 'Quản lý kho',
    };
    return labels[role] ?? role;
  }

  String get statusLabel {
    const labels = {
      'ACTIVE': 'Đang làm',
      'INACTIVE': 'Ngưng hoạt động',
      'SUSPENDED': 'Tạm khóa',
    };
    return labels[status] ?? status;
  }

  String get genderLabel {
    const labels = {
      'MALE': 'Nam',
      'FEMALE': 'Nữ',
      'OTHER': 'Khác',
    };
    return labels[gender] ?? '—';
  }

  bool get hasLeaveBalance => annualLeaveDays != null;

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    final leaveBalance = json['leaveBalance'] as Map<String, dynamic>?;
    final branchRef = json['branchId'] ?? json['branch'];
    final warehouseRef = json['warehouseId'] ?? json['warehouse'];
    final paySheetRef = json['paySheetId'];

    return StaffModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      email: json['email']?.toString(),
      role: json['role']?.toString() ?? 'STAFF',
      status: json['status']?.toString() ?? 'ACTIVE',
      firstName:
          profile?['firstName']?.toString() ??
          json['firstName']?.toString() ??
          '',
      lastName:
          profile?['lastName']?.toString() ??
          json['lastName']?.toString() ??
          '',
      branchId: _resolveRefId(branchRef),
      branchName: _resolveRefName(branchRef),
      warehouseId: _resolveRefId(warehouseRef).isEmpty
          ? null
          : _resolveRefId(warehouseRef),
      warehouseName: _resolveRefName(warehouseRef) == '—'
          ? null
          : _resolveRefName(warehouseRef),
      annualLeaveDays: leaveBalance?['annualLeaveDays'] != null
          ? int.tryParse(leaveBalance!['annualLeaveDays'].toString())
          : null,
      remainingLeaveDays: leaveBalance?['remainingDays'] != null
          ? int.tryParse(leaveBalance!['remainingDays'].toString())
          : null,
      usedLeaveDays: leaveBalance?['usedDays'] != null
          ? int.tryParse(leaveBalance!['usedDays'].toString())
          : null,
      hireDate: _dateOnly(json['hireDate']?.toString()),
      gender: profile?['gender']?.toString(),
      address: profile?['address']?.toString(),
      identificationId: profile?['identificationId']?.toString(),
      dob: _dateOnly(profile?['dob']?.toString() ?? json['dob']?.toString()),
      taxNumber: profile?['taxNumber']?.toString() ??
          json['taxNumber']?.toString(),
      accountNote: json['accountNote']?.toString(),
      paySheetId: _resolveRefId(paySheetRef).isEmpty
          ? null
          : _resolveRefId(paySheetRef),
      paySheetName: paySheetRef is Map
          ? paySheetRef['name']?.toString()
          : null,
    );
  }

  static String _dateOnly(String? value) {
    if (value == null || value.isEmpty) return '';
    return value.length >= 10 ? value.substring(0, 10) : value;
  }

  static String _resolveRefId(dynamic ref) {
    if (ref == null) return '';
    if (ref is String) return ref;
    if (ref is Map) return ref['_id']?.toString() ?? '';
    return '';
  }

  static String _resolveRefName(dynamic ref) {
    if (ref == null) return '—';
    if (ref is String) return ref;
    if (ref is Map) {
      return ref['name']?.toString() ?? ref['_id']?.toString() ?? '—';
    }
    return '—';
  }
}

class StaffListResult {
  final List<StaffModel> data;
  final int total;
  final int page;
  final int totalPages;

  const StaffListResult({
    required this.data,
    required this.total,
    required this.page,
    required this.totalPages,
  });
}

/// Shared profile fields for create/update (BM → STAFF only).
class StaffFormFields {
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? email;
  final String? hireDate;
  final String? gender;
  final String? address;
  final String? identificationId;
  final String? dob;
  final String? taxNumber;
  final String? accountNote;
  final String? branchId;
  final String? newPassword;
  final String? reEnterPassword;
  final int? annualLeaveDays;

  const StaffFormFields({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.email,
    this.hireDate,
    this.gender,
    this.address,
    this.identificationId,
    this.dob,
    this.taxNumber,
    this.accountNote,
    this.branchId,
    this.newPassword,
    this.reEnterPassword,
    this.annualLeaveDays,
  });

  Map<String, dynamic> toCreateJson() {
    final profile = <String, dynamic>{
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
    };
    if (gender != null && gender!.isNotEmpty) profile['gender'] = gender;
    if (address != null && address!.trim().isNotEmpty) {
      profile['address'] = address!.trim();
    }
    if (identificationId != null && identificationId!.trim().isNotEmpty) {
      profile['identificationId'] = identificationId!.trim();
    }

    return {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'role': 'STAFF',
      if (email != null && email!.trim().isNotEmpty) 'email': email!.trim(),
      if (branchId != null && branchId!.trim().isNotEmpty)
        'branchId': branchId!.trim(),
      if (hireDate != null && hireDate!.isNotEmpty) 'hireDate': hireDate,
      if (dob != null && dob!.isNotEmpty) 'dob': dob,
      if (taxNumber != null && taxNumber!.trim().isNotEmpty)
        'taxNumber': taxNumber!.trim(),
      'profile': profile,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final profile = <String, dynamic>{
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
    };
    if (gender != null) profile['gender'] = gender;
    if (address != null) profile['address'] = address!.trim();
    if (identificationId != null) {
      profile['identificationId'] = identificationId!.trim();
    }
    if (dob != null && dob!.isNotEmpty) profile['dob'] = dob;
    if (taxNumber != null) profile['taxNumber'] = taxNumber!.trim();

    return {
      'data': {
        if (email != null) 'email': email!.trim(),
        if (hireDate != null && hireDate!.isNotEmpty) 'hireDate': hireDate,
        if (accountNote != null) 'accountNote': accountNote!.trim(),
        if (branchId != null && branchId!.trim().isNotEmpty)
          'branchId': branchId!.trim(),
        'profile': profile,
      },
    };
  }

  bool get hasPassword =>
      newPassword != null &&
      newPassword!.length >= 6 &&
      newPassword == reEnterPassword;
}

class StaffPasswordInput {
  final String newPassword;
  final String reEnterPassword;

  const StaffPasswordInput({
    required this.newPassword,
    required this.reEnterPassword,
  });

  Map<String, dynamic> toJson() => {
        'newPassword': newPassword,
        'reEnterPassword': reEnterPassword,
      };
}

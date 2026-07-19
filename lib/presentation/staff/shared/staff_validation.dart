// Mirrors FE identification-format.ts + staff-date-validation.ts.

const int kCccdLength = 12;
const int kMinStaffAge = 16;
const int kMinBirthYear = 1900;
const int kMinHireYear = 1970;
const int kMaxHireYearsAhead = 5;

String parseIdentificationId(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.length <= kCccdLength) return digits;
  return digits.substring(0, kCccdLength);
}

bool isValidIdentificationId(String? value) {
  final digits = parseIdentificationId(value);
  if (digits.isEmpty) return true;
  return digits.length == kCccdLength;
}

String parseTaxNumber(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.length <= 14) return digits;
  return digits.substring(0, 14);
}

bool isValidTaxNumber(String? value) {
  final digits = parseTaxNumber(value);
  if (digits.isEmpty) return true;
  return digits.length >= 10 && digits.length <= 14;
}

String? validateOptionalDob(DateTime? dob) {
  if (dob == null) return null;
  final today =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final d = DateTime(dob.year, dob.month, dob.day);
  if (d.isAfter(today)) return 'Ngày sinh không được ở tương lai';
  if (d.year < kMinBirthYear) {
    return 'Năm sinh phải từ $kMinBirthYear trở lên';
  }
  var age = today.year - d.year;
  if (today.month < d.month ||
      (today.month == d.month && today.day < d.day)) {
    age -= 1;
  }
  if (age < kMinStaffAge) {
    return 'Nhân viên phải đủ $kMinStaffAge tuổi trở lên';
  }
  return null;
}

String? validateOptionalHireDate(DateTime? hireDate, {DateTime? dob}) {
  if (hireDate == null) return null;
  final h = DateTime(hireDate.year, hireDate.month, hireDate.day);
  if (h.year < kMinHireYear) {
    return 'Ngày vào làm phải từ năm $kMinHireYear trở lên';
  }
  final today =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final maxHire =
      DateTime(today.year + kMaxHireYearsAhead, today.month, today.day);
  if (h.isAfter(maxHire)) {
    return 'Ngày vào làm không được quá $kMaxHireYearsAhead năm so với hiện tại';
  }
  if (dob != null) {
    final d = DateTime(dob.year, dob.month, dob.day);
    if (h.isBefore(d)) {
      return 'Ngày vào làm không được trước ngày sinh';
    }
    var ageAtHire = h.year - d.year;
    if (h.month < d.month || (h.month == d.month && h.day < d.day)) {
      ageAtHire -= 1;
    }
    if (ageAtHire < kMinStaffAge) {
      return 'Ngày vào làm phải sau khi nhân viên đủ $kMinStaffAge tuổi';
    }
  }
  return null;
}

import 'package:flutter/material.dart';

import '../../../data/models/staff_model.dart';
import '../shared/staff_validation.dart';

/// Form tạo/sửa STAFF — scope BM (chi nhánh khóa, không picker CN/kho).
class StaffFormFieldsEditor extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController lastNameCtrl;
  final TextEditingController firstNameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController identificationCtrl;
  final TextEditingController taxCtrl;
  final TextEditingController addressCtrl;
  final TextEditingController leaveDaysCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController rePasswordCtrl;
  final String? gender;
  final DateTime? hireDate;
  final DateTime? dob;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<DateTime?> onHireDateChanged;
  final ValueChanged<DateTime?> onDobChanged;
  final bool isEdit;
  final bool showPassword;
  final bool showLeaveDays;
  final String? lockedBranchLabel;

  const StaffFormFieldsEditor({
    super.key,
    required this.formKey,
    required this.lastNameCtrl,
    required this.firstNameCtrl,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.identificationCtrl,
    required this.taxCtrl,
    required this.addressCtrl,
    required this.leaveDaysCtrl,
    required this.passwordCtrl,
    required this.rePasswordCtrl,
    required this.gender,
    required this.hireDate,
    required this.dob,
    required this.onGenderChanged,
    required this.onHireDateChanged,
    required this.onDobChanged,
    this.isEdit = false,
    this.showPassword = false,
    this.showLeaveDays = false,
    this.lockedBranchLabel,
  });

  StaffFormFields buildFields({String? branchId}) {
    return StaffFormFields(
      firstName: firstNameCtrl.text,
      lastName: lastNameCtrl.text,
      phoneNumber: phoneCtrl.text,
      email: emailCtrl.text,
      hireDate: hireDate == null
          ? null
          : '${hireDate!.year.toString().padLeft(4, '0')}-'
              '${hireDate!.month.toString().padLeft(2, '0')}-'
              '${hireDate!.day.toString().padLeft(2, '0')}',
      gender: gender,
      address: addressCtrl.text,
      identificationId: identificationCtrl.text,
      dob: dob == null
          ? null
          : '${dob!.year.toString().padLeft(4, '0')}-'
              '${dob!.month.toString().padLeft(2, '0')}-'
              '${dob!.day.toString().padLeft(2, '0')}',
      taxNumber: taxCtrl.text,
      branchId: branchId,
      newPassword: passwordCtrl.text.isEmpty ? null : passwordCtrl.text,
      reEnterPassword: rePasswordCtrl.text.isEmpty ? null : rePasswordCtrl.text,
      annualLeaveDays: int.tryParse(leaveDaysCtrl.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hireErr = validateOptionalHireDate(hireDate, dob: dob);
    final dobErr = validateOptionalDob(dob);
    final errorStyle =
        TextStyle(color: Theme.of(context).colorScheme.error);

    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: lastNameCtrl,
            decoration: const InputDecoration(labelText: 'Họ *'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
          ),
          TextFormField(
            controller: firstNameCtrl,
            decoration: const InputDecoration(labelText: 'Tên *'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
          ),
          TextFormField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Số điện thoại *'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Bắt buộc';
              if (v.trim().length < 9) return 'SĐT không hợp lệ';
              return null;
            },
          ),
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: gender,
            decoration: const InputDecoration(labelText: 'Giới tính'),
            items: const [
              DropdownMenuItem(value: 'MALE', child: Text('Nam')),
              DropdownMenuItem(value: 'FEMALE', child: Text('Nữ')),
              DropdownMenuItem(value: 'OTHER', child: Text('Khác')),
            ],
            onChanged: onGenderChanged,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              hireDate == null
                  ? 'Ngày vào làm'
                  : 'Ngày vào làm: ${_fmt(hireDate!)}',
            ),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: hireDate ?? now,
                firstDate: DateTime(kMinHireYear),
                lastDate: DateTime(
                  now.year + kMaxHireYearsAhead,
                  now.month,
                  now.day,
                ),
              );
              if (picked != null) onHireDateChanged(picked);
            },
            subtitle: hireErr != null ? Text(hireErr, style: errorStyle) : null,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              dob == null ? 'Ngày sinh' : 'Ngày sinh: ${_fmt(dob!)}',
            ),
            trailing: const Icon(Icons.cake_outlined),
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: dob ?? DateTime(now.year - 20),
                firstDate: DateTime(kMinBirthYear),
                lastDate: now,
              );
              if (picked != null) onDobChanged(picked);
            },
            subtitle: dobErr != null ? Text(dobErr, style: errorStyle) : null,
          ),
          TextFormField(
            controller: identificationCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'CCCD / CMND'),
            onChanged: (v) {
              final parsed = parseIdentificationId(v);
              if (v != parsed) {
                identificationCtrl.value = TextEditingValue(
                  text: parsed,
                  selection: TextSelection.collapsed(offset: parsed.length),
                );
              }
            },
            validator: (v) {
              if (!isValidIdentificationId(v)) {
                return 'CCCD phải đủ $kCccdLength số';
              }
              return null;
            },
          ),
          TextFormField(
            controller: taxCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Mã số thuế'),
            onChanged: (v) {
              final parsed = parseTaxNumber(v);
              if (v != parsed) {
                taxCtrl.value = TextEditingValue(
                  text: parsed,
                  selection: TextSelection.collapsed(offset: parsed.length),
                );
              }
            },
            validator: (v) {
              if (!isValidTaxNumber(v)) {
                return 'MST phải từ 10–14 số';
              }
              return null;
            },
          ),
          TextFormField(
            controller: addressCtrl,
            decoration: const InputDecoration(labelText: 'Địa chỉ'),
          ),
          if (showLeaveDays)
            TextFormField(
              controller: leaveDaysCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số ngày phép năm'),
            ),
          if (showPassword) ...[
            TextFormField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: isEdit
                    ? 'Mật khẩu mới (tuỳ chọn)'
                    : 'Mật khẩu kích hoạt (tuỳ chọn)',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                if (v.length < 6) return 'Tối thiểu 6 ký tự';
                return null;
              },
            ),
            TextFormField(
              controller: rePasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nhập lại mật khẩu'),
              validator: (v) {
                if (passwordCtrl.text.isEmpty) return null;
                if (v != passwordCtrl.text) return 'Mật khẩu không khớp';
                return null;
              },
            ),
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              lockedBranchLabel != null && lockedBranchLabel!.isNotEmpty
                  ? 'Vai trò: Nhân viên (STAFF) · $lockedBranchLabel'
                  : 'Vai trò: Nhân viên (STAFF)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

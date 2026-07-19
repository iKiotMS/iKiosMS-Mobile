import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/staff_model.dart';
import '../../auth/viewmodels/user_profile_provider.dart';
import '../../shared/widgets/centered_detail_dialog.dart';
import '../shared/staff_validation.dart';
import '../viewmodels/staff_list_view_model.dart';
import '../widgets/staff_form_fields_editor.dart';

class StaffListView extends ConsumerStatefulWidget {
  const StaffListView({super.key});

  @override
  ConsumerState<StaffListView> createState() => _StaffListViewState();
}

class _StaffListViewState extends ConsumerState<StaffListView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(staffListViewModelProvider);
    final theme = Theme.of(context);

    ref.listen(staffListViewModelProvider, (prev, next) {
      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!)),
        );
      }
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage &&
          !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhân viên chi nhánh'),
        actions: [
          IconButton(
            tooltip: 'Thêm nhân viên',
            onPressed:
                state.isSubmitting ? null : () => _showFormDialog(context),
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên / SĐT...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                ref.read(staffListViewModelProvider.notifier).search(value);
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _Chip(
                  label: 'Tất cả TT',
                  selected: state.statusFilter == null,
                  onTap: () => ref
                      .read(staffListViewModelProvider.notifier)
                      .setStatusFilter(null),
                ),
                _Chip(
                  label: 'Đang làm',
                  selected: state.statusFilter == 'ACTIVE',
                  onTap: () => ref
                      .read(staffListViewModelProvider.notifier)
                      .setStatusFilter('ACTIVE'),
                ),
                _Chip(
                  label: 'Ngưng',
                  selected: state.statusFilter == 'INACTIVE',
                  onTap: () => ref
                      .read(staffListViewModelProvider.notifier)
                      .setStatusFilter('INACTIVE'),
                ),
                _Chip(
                  label: 'Chỉ STAFF',
                  selected: state.roleFilter == 'STAFF',
                  onTap: () => ref
                      .read(staffListViewModelProvider.notifier)
                      .setRoleFilter(
                        state.roleFilter == 'STAFF' ? null : 'STAFF',
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(staffListViewModelProvider.notifier).loadStaff(),
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.staff.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('Chưa có nhân viên.')),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: state.staff.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final staff = state.staff[index];
                            return _StaffCard(
                              staff: staff,
                              onTap: () => _showDetail(context, staff),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFormDialog(
    BuildContext context, {
    StaffModel? staff,
  }) async {
    final isEdit = staff != null;
    final lastNameCtrl = TextEditingController(text: staff?.lastName ?? '');
    final firstNameCtrl = TextEditingController(text: staff?.firstName ?? '');
    final phoneCtrl = TextEditingController(text: staff?.phoneNumber ?? '');
    final emailCtrl = TextEditingController(text: staff?.email ?? '');
    final identificationCtrl =
        TextEditingController(text: staff?.identificationId ?? '');
    final taxCtrl = TextEditingController(text: staff?.taxNumber ?? '');
    final addressCtrl = TextEditingController(text: staff?.address ?? '');
    final leaveDaysCtrl = TextEditingController(
      text: staff?.annualLeaveDays?.toString() ?? '',
    );
    final passwordCtrl = TextEditingController();
    final rePasswordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? gender = staff?.gender;
    DateTime? hireDate = _parseDate(staff?.hireDate);
    DateTime? dob = _parseDate(staff?.dob);
    // Scope chi nhánh (BM): luôn khóa CN theo profile.
    final profile = ref.read(userProfileProvider).valueOrNull;
    final lockedBranchId = profile?.branchId?.trim();
    final lockedBranchLabel = staff?.branchName.isNotEmpty == true
        ? staff!.branchName
        : (lockedBranchId != null && lockedBranchId.isNotEmpty
            ? 'Chi nhánh gắn theo tài khoản quản lý'
            : null);
    if (!context.mounted) return;

    await showCenteredCardDialog<void>(
      context: context,
      maxWidth: 460,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final editor = StaffFormFieldsEditor(
              formKey: formKey,
              lastNameCtrl: lastNameCtrl,
              firstNameCtrl: firstNameCtrl,
              phoneCtrl: phoneCtrl,
              emailCtrl: emailCtrl,
              identificationCtrl: identificationCtrl,
              taxCtrl: taxCtrl,
              addressCtrl: addressCtrl,
              leaveDaysCtrl: leaveDaysCtrl,
              passwordCtrl: passwordCtrl,
              rePasswordCtrl: rePasswordCtrl,
              gender: gender,
              hireDate: hireDate,
              dob: dob,
              onGenderChanged: (v) => setLocal(() => gender = v),
              onHireDateChanged: (v) => setLocal(() => hireDate = v),
              onDobChanged: (v) => setLocal(() => dob = v),
              isEdit: isEdit,
              showPassword: !isEdit,
              showLeaveDays: !isEdit,
              lockedBranchLabel: lockedBranchLabel,
            );

            return CenteredDetailCard(
              title: isEdit ? 'Sửa nhân viên' : 'Thêm nhân viên',
              actions: [
                DetailActionButton(
                  label: isEdit ? 'Lưu thay đổi' : 'Tạo nhân viên',
                  icon: Icons.save_outlined,
                  filled: true,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final dobErr = validateOptionalDob(dob);
                    final hireErr =
                        validateOptionalHireDate(hireDate, dob: dob);
                    if (dobErr != null || hireErr != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(dobErr ?? hireErr!)),
                      );
                      return;
                    }
                    final fields = editor.buildFields(
                      branchId: isEdit
                          ? (staff.branchId.isNotEmpty
                              ? staff.branchId
                              : lockedBranchId)
                          : lockedBranchId,
                    );
                    final ok = isEdit
                        ? await ref
                            .read(staffListViewModelProvider.notifier)
                            .updateStaff(staff.id, fields)
                        : await ref
                            .read(staffListViewModelProvider.notifier)
                            .createStaff(fields);
                    if (ctx.mounted && ok) Navigator.pop(ctx);
                  },
                ),
              ],
              children: [editor],
            );
          },
        );
      },
    );

    lastNameCtrl.dispose();
    firstNameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    identificationCtrl.dispose();
    taxCtrl.dispose();
    addressCtrl.dispose();
    leaveDaysCtrl.dispose();
    passwordCtrl.dispose();
    rePasswordCtrl.dispose();
  }

  Future<void> _showDetail(BuildContext context, StaffModel staff) async {
    await showCenteredCardDialog<void>(
      context: context,
      builder: (ctx) {
        final statusColor =
            staff.status == 'ACTIVE' ? Colors.green.shade800 : Colors.grey;
        return CenteredDetailCard(
          title: staff.fullName,
          statusLabel: '${staff.roleLabel} · ${staff.statusLabel}',
          statusColor: statusColor,
          actions: [
            if (staff.role == 'STAFF') ...[
              DetailActionButton(
                label: 'Sửa thông tin',
                icon: Icons.edit_outlined,
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _showFormDialog(context, staff: staff);
                },
              ),
              DetailActionButton(
                label: staff.hasLeaveBalance
                    ? 'Sửa phép năm'
                    : 'Tạo phép năm',
                icon: Icons.event_available_outlined,
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _showLeaveBalanceDialog(context, staff);
                },
              ),
              if (staff.status == 'INACTIVE')
                DetailActionButton(
                  label: 'Kích hoạt tài khoản',
                  icon: Icons.lock_open_rounded,
                  filled: true,
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _showPasswordDialog(context, staff, activate: true);
                  },
                ),
              if (staff.status == 'ACTIVE') ...[
                DetailActionButton(
                  label: 'Đổi mật khẩu',
                  icon: Icons.password_rounded,
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _showPasswordDialog(context, staff, activate: false);
                  },
                ),
                DetailActionButton(
                  label: 'Ngưng tài khoản',
                  icon: Icons.person_off_outlined,
                  destructive: true,
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _confirmDeactivateOrDelete(
                      context,
                      staff,
                      isDelete: false,
                    );
                  },
                ),
              ],
              DetailActionButton(
                label: 'Xóa nhân viên',
                icon: Icons.delete_outline,
                destructive: true,
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _confirmDeactivateOrDelete(
                    context,
                    staff,
                    isDelete: true,
                  );
                },
              ),
            ],
          ],
          children: [
            Text('SĐT: ${staff.phoneNumber}'),
            if (staff.email != null && staff.email!.isNotEmpty)
              Text('Email: ${staff.email}'),
            Text('Giới tính: ${staff.genderLabel}'),
            if (staff.hireDate != null && staff.hireDate!.isNotEmpty)
              Text('Ngày vào làm: ${staff.hireDate}'),
            if (staff.dob != null && staff.dob!.isNotEmpty)
              Text('Ngày sinh: ${staff.dob}'),
            if (staff.identificationId != null &&
                staff.identificationId!.isNotEmpty)
              Text('CCCD: ${staff.identificationId}'),
            if (staff.taxNumber != null && staff.taxNumber!.isNotEmpty)
              Text('MST: ${staff.taxNumber}'),
            if (staff.address != null && staff.address!.isNotEmpty)
              Text('Địa chỉ: ${staff.address}'),
            if (staff.remainingLeaveDays != null)
              Text(
                'Phép còn: ${staff.remainingLeaveDays}/${staff.annualLeaveDays ?? '-'} ngày',
              ),
            if (staff.branchName.isNotEmpty && staff.branchName != '—')
              Text('Chi nhánh: ${staff.branchName}'),
            if (staff.accountNote != null && staff.accountNote!.isNotEmpty)
              Text('Ghi chú: ${staff.accountNote}'),
          ],
        );
      },
    );
  }

  Future<void> _showLeaveBalanceDialog(
    BuildContext context,
    StaffModel staff,
  ) async {
    final ctrl = TextEditingController(
      text: staff.annualLeaveDays?.toString() ?? '12',
    );
    final formKey = GlobalKey<FormState>();

    await showCenteredCardDialog<void>(
      context: context,
      builder: (ctx) {
        return CenteredDetailCard(
          title: 'Phép năm',
          actions: [
            DetailActionButton(
              label: 'Lưu',
              icon: Icons.save_outlined,
              filled: true,
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final days = int.parse(ctrl.text);
                final ok = await ref
                    .read(staffListViewModelProvider.notifier)
                    .upsertLeaveBalance(
                      staff.id,
                      days,
                      exists: staff.hasLeaveBalance,
                    );
                if (ctx.mounted && ok) Navigator.pop(ctx);
              },
            ),
          ],
          children: [
            Text(staff.fullName),
            if (staff.remainingLeaveDays != null)
              Text(
                'Hiện còn: ${staff.remainingLeaveDays}/${staff.annualLeaveDays} ngày',
              ),
            Form(
              key: formKey,
              child: TextFormField(
                controller: ctrl,
                decoration:
                    const InputDecoration(labelText: 'Số ngày phép năm'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 0) return 'Số không hợp lệ';
                  return null;
                },
              ),
            ),
          ],
        );
      },
    );
    ctrl.dispose();
  }

  Future<void> _showPasswordDialog(
    BuildContext context,
    StaffModel staff, {
    required bool activate,
  }) async {
    final passCtrl = TextEditingController();
    final reCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showCenteredCardDialog<void>(
      context: context,
      builder: (ctx) {
        return CenteredDetailCard(
          title: activate ? 'Kích hoạt tài khoản' : 'Đổi mật khẩu',
          actions: [
            DetailActionButton(
              label: activate ? 'Kích hoạt' : 'Đổi mật khẩu',
              icon: Icons.check_rounded,
              filled: true,
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final input = StaffPasswordInput(
                  newPassword: passCtrl.text,
                  reEnterPassword: reCtrl.text,
                );
                final ok = activate
                    ? await ref
                        .read(staffListViewModelProvider.notifier)
                        .activateStaff(staff.id, input)
                    : await ref
                        .read(staffListViewModelProvider.notifier)
                        .resetPassword(staff.id, input);
                if (ctx.mounted && ok) Navigator.pop(ctx);
              },
            ),
          ],
          children: [
            Text(staff.fullName),
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Mật khẩu mới'),
                    validator: (v) =>
                        (v == null || v.length < 6) ? 'Tối thiểu 6 ký tự' : null,
                  ),
                  TextFormField(
                    controller: reCtrl,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Nhập lại mật khẩu'),
                    validator: (v) =>
                        v != passCtrl.text ? 'Mật khẩu không khớp' : null,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
    passCtrl.dispose();
    reCtrl.dispose();
  }

  /// BM chi nhánh: chỉ khóa/xóa STAFF trong CN — không flow thay thế QL (TO).
  Future<void> _confirmDeactivateOrDelete(
    BuildContext context,
    StaffModel staff, {
    required bool isDelete,
  }) async {
    if (staff.role != 'STAFF') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Quản lý chi nhánh chỉ khóa/xóa nhân viên STAFF trong chi nhánh.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(isDelete ? 'Xóa nhân viên' : 'Khóa tài khoản'),
        content: Text(
          isDelete
              ? 'Xóa ${staff.fullName}? Thao tác không hoàn tác.'
              : 'Ngưng tài khoản của ${staff.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text(isDelete ? 'Xóa' : 'Khóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    final vm = ref.read(staffListViewModelProvider.notifier);
    if (isDelete) {
      await vm.deleteStaff(staff.id);
    } else {
      await vm.deactivateStaff(staff.id);
    }
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value.length >= 10 ? value.substring(0, 10) : value);
  }
}

class _StaffCard extends StatelessWidget {
  final StaffModel staff;
  final VoidCallback onTap;

  const _StaffCard({required this.staff, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                child: Text(
                  staff.fullName.isNotEmpty
                      ? staff.fullName.characters.first.toUpperCase()
                      : '?',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${staff.roleLabel} · ${staff.phoneNumber}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: staff.status == 'ACTIVE'
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  staff.statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: staff.status == 'ACTIVE'
                        ? Colors.green.shade800
                        : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/date_time_utils.dart';
import '../../../data/models/shift_template_model.dart';
import '../../../data/models/working_schedule_admin_model.dart';
import '../../auth/viewmodels/user_profile_provider.dart';
import '../../shared/widgets/centered_detail_dialog.dart';
import '../viewmodels/shift_management_view_model.dart';

class ShiftManagementView extends ConsumerWidget {
  const ShiftManagementView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shiftManagementViewModelProvider);
    final theme = Theme.of(context);

    ref.listen(shiftManagementViewModelProvider, (prev, next) {
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý ca làm'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Lịch phân ca'),
              Tab(text: 'Ca mẫu'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Phân ca mới',
              onPressed: state.isSubmitting
                  ? null
                  : () => _showCreateScheduleDialog(context, ref, state),
              icon: const Icon(Icons.event_available_rounded),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _SchedulesTab(state: state),
            _TemplatesTab(state: state),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateScheduleDialog(
    BuildContext context,
    WidgetRef ref,
    ShiftManagementState state,
  ) async {
    if (state.templates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy tạo ca mẫu trước.')),
      );
      return;
    }
    if (state.staffOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có nhân viên ACTIVE để phân ca.')),
      );
      return;
    }

    final selectedStaff = <String>{};
    String? templateId = state.templates.first.id;
    DateTime? selectedDate;
    var isOvertime = false;

    await showCenteredCardDialog<void>(
      context: context,
      maxWidth: 460,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return CenteredDetailCard(
              title: 'Phân ca mới',
              children: [
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: templateId,
                  decoration: const InputDecoration(labelText: 'Ca mẫu'),
                  items: state.templates
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.id,
                          child: Text('${t.name} (${t.timeRange})'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setLocal(() => templateId = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ca tăng ca (OVERTIME)'),
                  value: isOvertime,
                  onChanged: (v) => setLocal(() => isOvertime = v),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    selectedDate == null
                        ? 'Chọn ngày làm'
                        : DateTimeUtils.formatApiDate(selectedDate!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setLocal(() => selectedDate = picked);
                    }
                  },
                ),
                const Text('Chọn nhân viên'),
                ...state.staffOptions.map((staff) {
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: selectedStaff.contains(staff.id),
                    title: Text(staff.fullName),
                    subtitle: Text(staff.phoneNumber),
                    onChanged: (checked) {
                      setLocal(() {
                        if (checked == true) {
                          selectedStaff.add(staff.id);
                        } else {
                          selectedStaff.remove(staff.id);
                        }
                      });
                    },
                  );
                }),
              ],
              actions: [
                DetailActionButton(
                  label: 'Lưu phân ca',
                  icon: Icons.save_outlined,
                  filled: true,
                  onPressed: () async {
                    if (templateId == null || templateId!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chọn ca mẫu.')),
                      );
                      return;
                    }
                    if (selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chọn ngày làm việc.')),
                      );
                      return;
                    }
                    if (selectedStaff.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chọn ít nhất một nhân viên.'),
                        ),
                      );
                      return;
                    }
                    final success = await ref
                        .read(shiftManagementViewModelProvider.notifier)
                        .createSchedule(
                          userIds: selectedStaff.toList(),
                          shiftTemplateId: templateId!,
                          workDates: [
                            DateTimeUtils.formatApiDate(selectedDate!),
                          ],
                          scheduleType: isOvertime ? 'OVERTIME' : 'NORMAL',
                        );
                    if (ctx.mounted && success) Navigator.pop(ctx);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SchedulesTab extends ConsumerWidget {
  final ShiftManagementState state;

  const _SchedulesTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthLabel = DateFormat('MM/yyyy').format(state.month);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final myId = profile?.id;
    final myRole = profile?.role;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  final prev =
                      DateTime(state.month.year, state.month.month - 1);
                  ref
                      .read(shiftManagementViewModelProvider.notifier)
                      .changeMonth(prev);
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Tháng $monthLabel',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  final next =
                      DateTime(state.month.year, state.month.month + 1);
                  ref
                      .read(shiftManagementViewModelProvider.notifier)
                      .changeMonth(next);
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        if (state.staffOptions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: DropdownButtonFormField<String?>(
              // ignore: deprecated_member_use
              value: state.staffFilterId,
              decoration: const InputDecoration(
                labelText: 'Lọc theo nhân viên',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Tất cả nhân viên'),
                ),
                ...state.staffOptions.map(
                  (s) => DropdownMenuItem<String?>(
                    value: s.id,
                    child: Text(s.fullName),
                  ),
                ),
              ],
              onChanged: (v) => ref
                  .read(shiftManagementViewModelProvider.notifier)
                  .setStaffFilter(v),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(shiftManagementViewModelProvider.notifier).load(),
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.visibleSchedules.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(child: Text('Chưa có lịch phân ca.')),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: state.visibleSchedules.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = state.visibleSchedules[index];
                          // FE schedule-permissions: chỉ BM không sửa/xóa ca của chính mình.
                          final isBmOwn = myRole == 'BRANCH_MANAGER' &&
                              myId != null &&
                              item.assignees.any((a) => a.userId == myId);
                          return _ScheduleCard(
                            schedule: item,
                            canDelete: !isBmOwn,
                            onTap: () => _showScheduleDetail(
                              context,
                              ref,
                              item,
                              canDelete: !isBmOwn,
                            ),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }

  Future<void> _showScheduleDetail(
    BuildContext context,
    WidgetRef ref,
    WorkingScheduleAdminModel item, {
    required bool canDelete,
  }) async {
    await showCenteredCardDialog<void>(
      context: context,
      builder: (ctx) {
        return CenteredDetailCard(
          title: item.shiftName,
          statusLabel: item.statusLabel,
          children: [
            Text('Ngày: ${item.workDate}'),
            Text('Giờ: ${item.timeRange}'),
            Text(
              'Loại: ${item.scheduleType == 'OVERTIME' ? 'Tăng ca' : 'Bình thường'}',
            ),
            const SizedBox(height: 8),
            Text('Nhân viên: ${item.staffNames}'),
          ],
          actions: [
            if (canDelete) ...[
              DetailActionButton(
                label: 'Sửa lịch làm',
                icon: Icons.edit_outlined,
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _showEditScheduleDialog(context, ref, item);
                },
              ),
              DetailActionButton(
                label: 'Xóa lịch làm',
                icon: Icons.delete_outline,
                destructive: true,
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: ctx,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('Xóa lịch làm?'),
                      content: Text(
                        'Xóa ca ${item.shiftName} ngày ${item.workDate}?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, false),
                          child: const Text('Huỷ'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dCtx, true),
                          child: const Text('Xóa'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final ok = await ref
                        .read(shiftManagementViewModelProvider.notifier)
                        .deleteSchedule(item.id);
                    if (ok && ctx.mounted) Navigator.pop(ctx);
                  }
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _showEditScheduleDialog(
    BuildContext context,
    WidgetRef ref,
    WorkingScheduleAdminModel item,
  ) async {
    final state = ref.read(shiftManagementViewModelProvider);
    if (state.templates.isEmpty || state.staffOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thiếu ca mẫu hoặc nhân viên để sửa.')),
      );
      return;
    }

    final selectedStaff = item.assignees.map((a) => a.userId).toSet();
    var templateId = item.shiftTemplateId.isNotEmpty
        ? item.shiftTemplateId
        : state.templates.first.id;
    if (!state.templates.any((t) => t.id == templateId)) {
      templateId = state.templates.first.id;
    }
    var workDate = DateTime.tryParse(item.workDate) ?? DateTime.now();
    var isOvertime = item.scheduleType == 'OVERTIME';

    await showCenteredCardDialog<void>(
      context: context,
      maxWidth: 460,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return CenteredDetailCard(
              title: 'Sửa lịch làm',
              actions: [
                DetailActionButton(
                  label: 'Lưu thay đổi',
                  icon: Icons.save_outlined,
                  filled: true,
                  onPressed: () async {
                    final ok = await ref
                        .read(shiftManagementViewModelProvider.notifier)
                        .editSchedule(
                          scheduleId: item.id,
                          userIds: selectedStaff.toList(),
                          shiftTemplateId: templateId,
                          workDate: DateTimeUtils.formatApiDate(workDate),
                          scheduleType: isOvertime ? 'OVERTIME' : 'NORMAL',
                        );
                    if (ctx.mounted && ok) Navigator.pop(ctx);
                  },
                ),
              ],
              children: [
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: templateId,
                  decoration: const InputDecoration(labelText: 'Ca mẫu'),
                  items: state.templates
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.id,
                          child: Text('${t.name} (${t.timeRange})'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setLocal(() => templateId = v);
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ca tăng ca (OVERTIME)'),
                  value: isOvertime,
                  onChanged: (v) => setLocal(() => isOvertime = v),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(DateTimeUtils.formatApiDate(workDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: workDate,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setLocal(() => workDate = picked);
                  },
                ),
                const Text('Nhân viên'),
                ...state.staffOptions.map((staff) {
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: selectedStaff.contains(staff.id),
                    title: Text(staff.fullName),
                    onChanged: (checked) {
                      setLocal(() {
                        if (checked == true) {
                          selectedStaff.add(staff.id);
                        } else {
                          selectedStaff.remove(staff.id);
                        }
                      });
                    },
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}

class _TemplatesTab extends ConsumerWidget {
  final ShiftManagementState state;

  const _TemplatesTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () =>
              ref.read(shiftManagementViewModelProvider.notifier).load(),
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.templates.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('Chưa có ca mẫu.')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                      itemCount: state.templates.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final template = state.templates[index];
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          title: Text(template.name),
                          subtitle: Text(template.timeRange),
                          onTap: () => _showTemplateDialog(
                            context,
                            ref,
                            template: template,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Xóa ca mẫu?'),
                                  content: Text('Xóa "${template.name}"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Huỷ'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: const Text('Xóa'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref
                                    .read(
                                      shiftManagementViewModelProvider
                                          .notifier,
                                    )
                                    .deleteTemplate(template.id);
                              }
                            },
                          ),
                        );
                      },
                    ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: state.isSubmitting
                ? null
                : () => _showTemplateDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Thêm ca mẫu'),
          ),
        ),
      ],
    );
  }

  Future<void> _showTemplateDialog(
    BuildContext context,
    WidgetRef ref, {
    ShiftTemplateModel? template,
  }) async {
    final nameCtrl = TextEditingController(text: template?.name ?? '');
    var start = _parseTime(template?.startTime) ??
        const TimeOfDay(hour: 8, minute: 0);
    var end =
        _parseTime(template?.endTime) ?? const TimeOfDay(hour: 17, minute: 0);
    final formKey = GlobalKey<FormState>();
    final isEdit = template != null;

    await showCenteredCardDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            String fmt(TimeOfDay t) =>
                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

            return CenteredDetailCard(
              title: isEdit ? 'Sửa ca mẫu' : 'Tạo ca mẫu',
              children: [
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Tên ca'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Bắt buộc'
                            : null,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Giờ bắt đầu: ${fmt(start)}'),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: start,
                          );
                          if (picked != null) setLocal(() => start = picked);
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Giờ kết thúc: ${fmt(end)}'),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: end,
                          );
                          if (picked != null) setLocal(() => end = picked);
                        },
                      ),
                    ],
                  ),
                ),
              ],
              actions: [
                DetailActionButton(
                  label: isEdit ? 'Lưu' : 'Tạo',
                  icon: Icons.check_rounded,
                  filled: true,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final input = CreateShiftTemplateInput(
                      name: nameCtrl.text,
                      startTime: fmt(start),
                      endTime: fmt(end),
                    );
                    final ok = isEdit
                        ? await ref
                            .read(shiftManagementViewModelProvider.notifier)
                            .updateTemplate(template.id, input)
                        : await ref
                            .read(shiftManagementViewModelProvider.notifier)
                            .createTemplate(input);
                    if (ctx.mounted && ok) Navigator.pop(ctx);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    nameCtrl.dispose();
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }
}

class _ScheduleCard extends StatelessWidget {
  final WorkingScheduleAdminModel schedule;
  final bool canDelete;
  final VoidCallback onTap;

  const _ScheduleCard({
    required this.schedule,
    required this.canDelete,
    required this.onTap,
  });

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${schedule.workDate} · ${schedule.shiftName}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(schedule.timeRange),
                    Text(
                      schedule.staffNames,
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${schedule.statusLabel}'
                      '${schedule.scheduleType == 'OVERTIME' ? ' · Tăng ca' : ''}'
                      '${canDelete ? '' : ' · (ca của bạn)'}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

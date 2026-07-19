import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_time_utils.dart';
import '../../../data/models/leave_request_model.dart';
import '../../shared/widgets/centered_detail_dialog.dart';
import '../viewmodels/leave_approval_view_model.dart';

class LeaveApprovalView extends ConsumerStatefulWidget {
  const LeaveApprovalView({super.key});

  @override
  ConsumerState<LeaveApprovalView> createState() => _LeaveApprovalViewState();
}

class _LeaveApprovalViewState extends ConsumerState<LeaveApprovalView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaveApprovalViewModelProvider);
    final theme = Theme.of(context);
    final vm = ref.read(leaveApprovalViewModelProvider.notifier);

    ref.listen(leaveApprovalViewModelProvider, (prev, next) {
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
        title: const Text('Duyệt nghỉ phép'),
        actions: [
          if (vm.canCreatePersonalLeave)
            IconButton(
              tooltip: 'Xin nghỉ phép',
              onPressed: state.isSubmitting
                  ? null
                  : () => _showPersonalDialog(context, state),
              icon: const Icon(Icons.beach_access_outlined),
            ),
          IconButton(
            tooltip: 'Tạo đơn khẩn',
            onPressed: state.isSubmitting
                ? null
                : () => _showEmergencyDialog(context, state),
            icon: const Icon(Icons.add_alert_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.remainingLeaveDays != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Phép còn của bạn: ${state.remainingLeaveDays} ngày',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên / lý do...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                ref.read(leaveApprovalViewModelProvider.notifier).search(value);
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final entry in const [
                  (null, 'Tất cả'),
                  ('PENDING', 'Chờ duyệt'),
                  ('APPROVED', 'Đã duyệt'),
                  ('REJECTED', 'Từ chối'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(entry.$2),
                      selected: state.statusFilter == entry.$1,
                      onSelected: (_) {
                        ref
                            .read(leaveApprovalViewModelProvider.notifier)
                            .setStatusFilter(entry.$1);
                      },
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2024),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                        initialDateRange: state.filterStart != null &&
                                state.filterEnd != null
                            ? DateTimeRange(
                                start: state.filterStart!,
                                end: state.filterEnd!,
                              )
                            : null,
                      );
                      if (picked != null) {
                        await ref
                            .read(leaveApprovalViewModelProvider.notifier)
                            .setDateFilter(
                              start: picked.start,
                              end: picked.end,
                            );
                      }
                    },
                    icon: const Icon(Icons.date_range, size: 18),
                    label: Text(
                      state.filterStart == null
                          ? 'Lọc theo ngày'
                          : '${DateTimeUtils.formatShortDate(state.filterStart!)} - ${DateTimeUtils.formatShortDate(state.filterEnd!)}',
                    ),
                  ),
                ),
                if (state.filterStart != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Xóa lọc ngày',
                    onPressed: () => ref
                        .read(leaveApprovalViewModelProvider.notifier)
                        .setDateFilter(),
                    icon: const Icon(Icons.clear),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(leaveApprovalViewModelProvider.notifier).load(),
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.requests.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('Không có đơn nghỉ phép.')),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: state.requests.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = state.requests[index];
                            return _LeaveCard(
                              request: item,
                              onTap: () =>
                                  _showDetail(context, item, vm.currentUserId),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange.shade800;
      case 'APPROVED':
        return Colors.green.shade800;
      case 'REJECTED':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade700;
    }
  }

  Future<void> _showDetail(
    BuildContext context,
    LeaveRequestModel request,
    String? currentUserId,
  ) async {
    final reviewerRole =
        ref.read(leaveApprovalViewModelProvider.notifier).currentUserRole;
    final canReview = request.canReviewAs(
      currentUserId,
      reviewerRole: reviewerRole,
    );
    final canCancel = request.canCancelAs(currentUserId) &&
        ref.read(leaveApprovalViewModelProvider.notifier).canCreatePersonalLeave;

    await showCenteredCardDialog<void>(
      context: context,
      builder: (ctx) {
        return CenteredDetailCard(
          title: request.staffName,
          statusLabel: request.statusLabel,
          statusColor: _statusColor(request.status),
          actions: [
            if (canReview) ...[
              DetailActionButton(
                label: 'Duyệt',
                icon: Icons.check_circle_outline,
                filled: true,
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _showApproveDialog(context, request);
                },
              ),
              DetailActionButton(
                label: 'Từ chối',
                icon: Icons.cancel_outlined,
                destructive: true,
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _showRejectDialog(context, request);
                },
              ),
            ],
            if (canCancel)
              DetailActionButton(
                label: 'Hủy đơn của tôi',
                icon: Icons.undo_rounded,
                destructive: true,
                onPressed: () async {
                  final ok = await ref
                      .read(leaveApprovalViewModelProvider.notifier)
                      .cancel(request.id);
                  if (ok && ctx.mounted) Navigator.pop(ctx);
                },
              ),
          ],
          children: [
            Text(
              '${_fmtDate(request.startDate)} → ${_fmtDate(request.endDate)}'
              ' (${request.totalDays} ngày)',
            ),
            const SizedBox(height: 8),
            Text('Lý do: ${request.reason}'),
            if (request.reviewNote != null &&
                request.reviewNote!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Ghi chú duyệt: ${request.reviewNote}'),
            ],
          ],
        );
      },
    );
  }

  Future<void> _showApproveDialog(
    BuildContext context,
    LeaveRequestModel request,
  ) async {
    final paidCtrl = TextEditingController(text: '${request.totalDays}');
    final unpaidCtrl = TextEditingController(text: '0');
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showCenteredCardDialog<void>(
      context: context,
      builder: (ctx) {
        return CenteredDetailCard(
          title: 'Duyệt nghỉ phép',
          actions: [
            DetailActionButton(
              label: 'Xác nhận duyệt',
              icon: Icons.check_rounded,
              filled: true,
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final ok = await ref
                    .read(leaveApprovalViewModelProvider.notifier)
                    .approve(
                      request,
                      ApproveLeaveInput(
                        paidLeaveDays: int.parse(paidCtrl.text),
                        unpaidLeaveDays: int.parse(unpaidCtrl.text),
                        reviewNote: noteCtrl.text,
                      ),
                    );
                if (ctx.mounted && ok) Navigator.pop(ctx);
              },
            ),
          ],
          children: [
            Text('Nhân viên: ${request.staffName}'),
            Text('Số ngày: ${request.totalDays}'),
            const SizedBox(height: 8),
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: paidCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Ngày phép có lương'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Số không hợp lệ';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: unpaidCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ngày phép không lương',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Số không hợp lệ';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: noteCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Ghi chú (tuỳ chọn)'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    paidCtrl.dispose();
    unpaidCtrl.dispose();
    noteCtrl.dispose();
  }

  Future<void> _showRejectDialog(
    BuildContext context,
    LeaveRequestModel request,
  ) async {
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showCenteredCardDialog<void>(
      context: context,
      builder: (ctx) {
        return CenteredDetailCard(
          title: 'Từ chối đơn nghỉ',
          actions: [
            DetailActionButton(
              label: 'Từ chối',
              icon: Icons.cancel_outlined,
              filled: true,
              destructive: true,
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final ok = await ref
                    .read(leaveApprovalViewModelProvider.notifier)
                    .reject(request.id, noteCtrl.text);
                if (ctx.mounted && ok) Navigator.pop(ctx);
              },
            ),
          ],
          children: [
            Form(
              key: formKey,
              child: TextFormField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Lý do từ chối'),
                maxLines: 3,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Bắt buộc' : null,
              ),
            ),
          ],
        );
      },
    );

    noteCtrl.dispose();
  }

  Future<void> _showPersonalDialog(
    BuildContext context,
    LeaveApprovalState state,
  ) async {
    // BM chi nhánh: luôn bắt buộc handover (FE).
    DateTime? start;
    DateTime? end;
    String? handoverId =
        state.staffOptions.isNotEmpty ? state.staffOptions.first.id : null;
    String? previewHint;
    var previewLoading = false;
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Future<void> refreshPreview(void Function(void Function()) setLocal) async {
      if (start == null || end == null) return;
      setLocal(() => previewLoading = true);
      final preview =
          await ref.read(leaveApprovalViewModelProvider.notifier).previewHandover(
                startDate: DateTimeUtils.formatApiDate(start!),
                endDate: DateTimeUtils.formatApiDate(end!),
              );
      setLocal(() {
        previewLoading = false;
        if (preview?.message != null && preview!.message!.isNotEmpty) {
          previewHint = preview.message;
        } else if (preview != null && preview.count > 0) {
          previewHint = 'Có ${preview.count} ca cần bàn giao trong khoảng ngày.';
        } else {
          previewHint = null;
        }
      });
    }

    await showCenteredCardDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return CenteredDetailCard(
              title: 'Xin nghỉ phép',
              actions: [
                DetailActionButton(
                  label: 'Gửi đơn',
                  icon: Icons.send_rounded,
                  filled: true,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    if (start == null || end == null) return;
                    if (state.staffOptions.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Cần có nhân viên trong chi nhánh để bàn giao.',
                          ),
                        ),
                      );
                      return;
                    }
                    final ok = await ref
                        .read(leaveApprovalViewModelProvider.notifier)
                        .createPersonal(
                          CreatePersonalLeaveInput(
                            startDate: DateTimeUtils.formatApiDate(start!),
                            endDate: DateTimeUtils.formatApiDate(end!),
                            reason: reasonCtrl.text,
                            handoverToUserId: handoverId,
                          ),
                        );
                    if (ctx.mounted && ok) Navigator.pop(ctx);
                  },
                ),
              ],
              children: [
                if (state.remainingLeaveDays != null)
                  Text('Phép còn: ${state.remainingLeaveDays} ngày'),
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          start == null
                              ? 'Ngày bắt đầu'
                              : DateTimeUtils.formatApiDate(start!),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setLocal(() => start = picked);
                            await refreshPreview(setLocal);
                          }
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          end == null
                              ? 'Ngày kết thúc'
                              : DateTimeUtils.formatApiDate(end!),
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: start ?? DateTime.now(),
                            firstDate: start ?? DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setLocal(() => end = picked);
                            await refreshPreview(setLocal);
                          }
                        },
                      ),
                      if (previewLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: LinearProgressIndicator(),
                        ),
                      if (previewHint != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            previewHint!,
                            style: Theme.of(ctx).textTheme.bodySmall,
                          ),
                        ),
                      DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: handoverId,
                        decoration: const InputDecoration(
                          labelText: 'Người bàn giao *',
                        ),
                        items: state.staffOptions
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.fullName),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setLocal(() => handoverId = v),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Bắt buộc chọn người bàn giao'
                            : null,
                      ),
                      TextFormField(
                        controller: reasonCtrl,
                        decoration: const InputDecoration(labelText: 'Lý do'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Bắt buộc'
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    reasonCtrl.dispose();
  }

  Future<void> _showEmergencyDialog(
    BuildContext context,
    LeaveApprovalState state,
  ) async {
    if (state.staffOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có nhân viên để tạo đơn khẩn.')),
      );
      return;
    }

    String? userId = state.staffOptions.first.id;
    DateTime? start;
    DateTime? end;
    var approveNow = true;
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showCenteredCardDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return CenteredDetailCard(
              title: 'Tạo đơn nghỉ khẩn',
              actions: [
                DetailActionButton(
                  label: approveNow ? 'Tạo & duyệt ngay' : 'Chỉ tạo đơn',
                  icon: Icons.add_alert_outlined,
                  filled: true,
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    if (userId == null || start == null || end == null) return;
                    final ok = await ref
                        .read(leaveApprovalViewModelProvider.notifier)
                        .createEmergency(
                          CreateEmergencyLeaveInput(
                            userId: userId!,
                            startDate: DateTimeUtils.formatApiDate(start!),
                            endDate: DateTimeUtils.formatApiDate(end!),
                            reason: reasonCtrl.text,
                          ),
                          approveImmediately: approveNow,
                        );
                    if (ctx.mounted && ok) Navigator.pop(ctx);
                  },
                ),
              ],
              children: [
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        // ignore: deprecated_member_use
                        value: userId,
                        decoration:
                            const InputDecoration(labelText: 'Nhân viên'),
                        items: state.staffOptions
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.fullName),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setLocal(() => userId = v),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          start == null
                              ? 'Ngày bắt đầu'
                              : DateTimeUtils.formatApiDate(start!),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 1)),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setLocal(() => start = picked);
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          end == null
                              ? 'Ngày kết thúc'
                              : DateTimeUtils.formatApiDate(end!),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: start ?? DateTime.now(),
                            firstDate: start ?? DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setLocal(() => end = picked);
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Tạo & duyệt ngay'),
                        value: approveNow,
                        onChanged: (v) => setLocal(() => approveNow = v),
                      ),
                      TextFormField(
                        controller: reasonCtrl,
                        decoration: const InputDecoration(labelText: 'Lý do'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Bắt buộc'
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    reasonCtrl.dispose();
  }

  String _fmtDate(String value) {
    if (value.length >= 10) {
      final d = DateTime.tryParse(value.substring(0, 10));
      if (d != null) return DateTimeUtils.formatShortDate(d);
    }
    return value;
  }
}

class _LeaveCard extends StatelessWidget {
  final LeaveRequestModel request;
  final VoidCallback onTap;

  const _LeaveCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color statusColor;
    switch (request.status) {
      case 'PENDING':
        statusColor = Colors.orange.shade800;
        break;
      case 'APPROVED':
        statusColor = Colors.green.shade800;
        break;
      case 'REJECTED':
        statusColor = Colors.red.shade800;
        break;
      default:
        statusColor = Colors.grey.shade700;
    }

    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.staffName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    request.statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${request.startDate.length >= 10 ? request.startDate.substring(0, 10) : request.startDate}'
                ' → '
                '${request.endDate.length >= 10 ? request.endDate.substring(0, 10) : request.endDate}'
                ' · ${request.totalDays} ngày',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                request.reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

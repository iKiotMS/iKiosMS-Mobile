import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_exception.dart';
import '../../data/leave_data.dart';

class LeaveState {
  final bool loading;
  final bool submitting;
  final List<LeaveRequestModel> requests;
  final LeaveBalance? balance;
  final String? error;

  const LeaveState({
    this.loading = false,
    this.submitting = false,
    this.requests = const [],
    this.balance,
    this.error,
  });

  LeaveState copyWith({
    bool? loading,
    bool? submitting,
    List<LeaveRequestModel>? requests,
    LeaveBalance? balance,
    String? error,
  }) {
    return LeaveState(
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      requests: requests ?? this.requests,
      balance: balance ?? this.balance,
      error: error,
    );
  }
}

class LeaveNotifier extends StateNotifier<LeaveState> {
  final LeaveApi api;

  LeaveNotifier(this.api) : super(const LeaveState(loading: true)) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final results = await Future.wait([
        api.getMyRequests(),
        api.getBalance(),
      ]);
      state = state.copyWith(
        loading: false,
        requests: results[0] as List<LeaveRequestModel>,
        balance: results[1] as LeaveBalance,
      );
    } catch (error) {
      state = state.copyWith(loading: false, error: readableApiError(error));
    }
  }

  Future<String?> create(
    DateTime startDate,
    DateTime endDate,
    String reason,
  ) async {
    state = state.copyWith(submitting: true, error: null);
    try {
      await api.createRequest(
        startDate: startDate,
        endDate: endDate,
        reason: reason,
      );
      state = state.copyWith(submitting: false);
      await load();
      return null;
    } catch (error) {
      final message = readableApiError(error);
      state = state.copyWith(submitting: false, error: message);
      return message;
    }
  }

  Future<String?> cancel(String id) async {
    try {
      await api.cancelRequest(id);
      await load();
      return null;
    } catch (error) {
      return readableApiError(error);
    }
  }
}

final leaveProvider = StateNotifierProvider<LeaveNotifier, LeaveState>((ref) {
  return LeaveNotifier(ref.watch(leaveApiProvider));
});

class LeaveView extends ConsumerWidget {
  const LeaveView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leaveProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Nghỉ phép của tôi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.submitting
            ? null
            : () => _openCreateForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Tạo đơn'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(leaveProvider.notifier).load(),
        child: state.loading
            ? const Center(child: CircularProgressIndicator())
            : state.error != null && state.requests.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 180),
                  Center(child: Text(state.error!)),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  _balanceCard(state.balance),
                  const SizedBox(height: 20),
                  Text(
                    'Đơn nghỉ phép',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (state.requests.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Center(
                        child: Text('Bạn chưa có đơn nghỉ phép nào.'),
                      ),
                    ),
                  ...state.requests.map(
                    (request) => _requestCard(context, ref, request),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _balanceCard(LeaveBalance? balance) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _number('Tổng phép', balance?.annualLeaveDays ?? 0),
            _number('Đã dùng', balance?.usedDays ?? 0),
            _number('Còn lại', balance?.remainingDays ?? 0),
          ],
        ),
      ),
    );
  }

  Widget _number(String label, double value) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(label),
      ],
    );
  }

  Widget _requestCard(
    BuildContext context,
    WidgetRef ref,
    LeaveRequestModel request,
  ) {
    final color = _statusColor(request.status);
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_date(request.startDate)} - ${_date(request.endDate)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text(_statusText(request.status)),
                  backgroundColor: color.withValues(alpha: 0.12),
                  side: BorderSide.none,
                  labelStyle: TextStyle(color: color),
                ),
              ],
            ),
            Text(request.reason),
            if (request.reviewNote?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Text('Ghi chú: ${request.reviewNote}'),
            ],
            if (request.status == 'PENDING')
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _cancel(context, ref, request),
                  child: const Text('Hủy đơn'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateForm(BuildContext context, WidgetRef ref) async {
    DateTime start = DateTime.now().add(const Duration(days: 1));
    DateTime end = start;
    final reasonController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tạo đơn nghỉ phép'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Từ ngày'),
                  subtitle: Text(_date(start)),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final picked = await _pickDate(context, start);
                    if (picked != null) setState(() => start = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Đến ngày'),
                  subtitle: Text(_date(end)),
                  trailing: const Icon(Icons.calendar_month),
                  onTap: () async {
                    final picked = await _pickDate(context, end);
                    if (picked != null) setState(() => end = picked);
                  },
                ),
                TextField(
                  controller: reasonController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Lý do',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
            FilledButton(
              onPressed: () async {
                if (reasonController.text.trim().isEmpty ||
                    end.isBefore(start)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kiểm tra ngày nghỉ và lý do.'),
                    ),
                  );
                  return;
                }
                final startTime = DateTime(
                  start.year,
                  start.month,
                  start.day,
                  8,
                );
                final endTime = DateTime(end.year, end.month, end.day, 17);
                final error = await ref
                    .read(leaveProvider.notifier)
                    .create(startTime, endTime, reasonController.text);
                if (!dialogContext.mounted) return;
                if (error == null) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã gửi đơn nghỉ phép.')),
                  );
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error)));
                }
              },
              child: const Text('Gửi đơn'),
            ),
          ],
        ),
      ),
    );
    reasonController.dispose();
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime current) {
    return showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
  }

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    LeaveRequestModel request,
  ) async {
    final error = await ref.read(leaveProvider.notifier).cancel(request.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? 'Đã hủy đơn nghỉ phép.')));
  }

  String _date(DateTime date) =>
      DateFormat('dd/MM/yyyy').format(date.toLocal());

  String _statusText(String status) => switch (status) {
    'PENDING' => 'Chờ duyệt',
    'APPROVED' => 'Đã duyệt',
    'REJECTED' => 'Từ chối',
    'CANCELLED' => 'Đã hủy',
    _ => status,
  };

  Color _statusColor(String status) => switch (status) {
    'APPROVED' => Colors.green,
    'REJECTED' => Colors.red,
    'CANCELLED' => Colors.grey,
    _ => Colors.orange,
  };
}

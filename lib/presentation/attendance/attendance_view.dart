import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/attendance_data.dart';

class AttendanceView extends ConsumerWidget {
  const AttendanceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(attendanceProvider);
    final attendance = state.openAttendance;

    return Scaffold(
      appBar: AppBar(title: const Text('Chấm công')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(attendanceProvider.notifier).load(),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 40),
            Icon(
              attendance == null ? Icons.login_rounded : Icons.logout_rounded,
              size: 90,
              color: attendance == null ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 20),
            Text(
              attendance == null ? 'Bạn chưa check-in' : 'Bạn đang trong ca',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (attendance?.checkedInAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Giờ vào: ${DateFormat('HH:mm - dd/MM/yyyy').format(attendance!.checkedInAt!.toLocal())}',
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 36),
            FilledButton.icon(
              onPressed: state.loading || state.submitting
                  ? null
                  : () => _submit(context, ref, attendance == null),
              icon: state.submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      attendance == null
                          ? Icons.login_rounded
                          : Icons.logout_rounded,
                    ),
              label: Text(
                state.submitting
                    ? 'Đang xử lý...'
                    : attendance == null
                    ? 'Check-in'
                    : 'Check-out',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: attendance == null
                    ? Colors.green
                    : Colors.orange.shade700,
              ),
            ),
            if (state.loading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 20),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Ứng dụng sẽ gửi thời gian hiện tại và vị trí GPS. Máy chủ tự tìm ca làm phù hợp.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    bool isCheckIn,
  ) async {
    final error = await ref.read(attendanceProvider.notifier).submit();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? (isCheckIn ? 'Check-in thành công' : 'Check-out thành công'),
        ),
        backgroundColor: error == null ? Colors.green : Colors.red,
      ),
    );
  }
}

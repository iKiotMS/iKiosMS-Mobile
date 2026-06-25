import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_time_utils.dart';
import '../../../data/models/shift_model.dart';
import '../viewmodels/shift_detail_view_model.dart';
import '../viewmodels/schedule_view_model.dart';
import '../widgets/shift_status_badge.dart';

/// Shows full information about a single shift and allows check-in.
///
/// Opened by tapping a shift card in ScheduleView.
/// Uses [ShiftDetailViewModel] (family, keyed by shiftId).
class ShiftDetailView extends ConsumerWidget {
  const ShiftDetailView({super.key, required this.shiftId});

  final String shiftId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(shiftDetailViewModelProvider(shiftId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết ca làm'),
        centerTitle: true,
      ),
      body: _buildBody(context, ref, detailState),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ShiftDetailState detailState,
  ) {
    // Loading state
    if (detailState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (detailState.shift == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                detailState.errorMessage ?? 'Không thể tải thông tin ca làm.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(shiftDetailViewModelProvider(shiftId).notifier)
                        .loadShift(shiftId),
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final shift = detailState.shift!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status card at the top
          _StatusCard(shift: shift),
          const SizedBox(height: 12),

          // Shift info card
          _InfoCard(shift: shift, detailState: detailState),
          const SizedBox(height: 20),

          // Check-in button (only shown when eligible)
          _CheckInSection(
            shiftId: shiftId,
            shift: shift,
            isCheckingIn: detailState.isCheckingIn,
            onCheckIn: () => _handleCheckIn(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckIn(BuildContext context, WidgetRef ref) async {
    final errorMsg = await ref
        .read(shiftDetailViewModelProvider(shiftId).notifier)
        .checkIn();

    if (!context.mounted) return;

    if (errorMsg == null) {
      // Refresh the schedule list so the status updates there too.
      ref.read(scheduleViewModelProvider.notifier).loadShifts();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Chấm công thành công'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

/// Card showing the shift status prominently at the top.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.shift});
  final ShiftModel shift;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: shift.statusColor.withValues(alpha: 0.3),
        ),
      ),
      color: shift.statusColor.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateTimeUtils.formatShiftDate(shift.date),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateTimeUtils.formatTimeRange(
                        shift.startTime, shift.endTime),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ShiftStatusBadge(shift: shift),
                const SizedBox(height: 6),
                AttendanceStatusBadge(shift: shift),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Card showing role, location, check-in time details.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.shift, required this.detailState});
  final ShiftModel shift;
  final ShiftDetailState detailState;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'Vị trí',
            value: shift.role,
          ),
          _Divider(),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Địa điểm',
            value: shift.location,
          ),
          _Divider(),
          _InfoRow(
            icon: Icons.access_time_rounded,
            label: 'Thời gian',
            value:
                DateTimeUtils.formatTimeRange(shift.startTime, shift.endTime),
          ),
          if (shift.checkedInAt != null) ...[
            _Divider(),
            _InfoRow(
              icon: Icons.login_rounded,
              label: 'Giờ vào',
              value: _formatDateTime(shift.checkedInAt!),
              valueColor: Colors.green.shade700,
            ),
          ],
          if (shift.checkedOutAt != null) ...[
            _Divider(),
            _InfoRow(
              icon: Icons.logout_rounded,
              label: 'Giờ ra',
              value: _formatDateTime(shift.checkedOutAt!),
            ),
          ],
          if (detailState.currentLatitude != null && detailState.currentLongitude != null) ...[
            _Divider(),
            _InfoRow(
              icon: Icons.gps_fixed_rounded,
              label: 'GPS hiện tại',
              value: '${detailState.currentLatitude!.toStringAsFixed(6)}, ${detailState.currentLongitude!.toStringAsFixed(6)}',
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m — ${DateTimeUtils.formatShiftDate(dt)}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 48,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

/// Section at the bottom of the screen handling check-in.
class _CheckInSection extends StatelessWidget {
  const _CheckInSection({
    required this.shiftId,
    required this.shift,
    required this.isCheckingIn,
    required this.onCheckIn,
  });

  final String shiftId;
  final ShiftModel shift;
  final bool isCheckingIn;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    // Already checked in
    if (shift.isAlreadyCheckedIn) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded,
              color: Colors.green.shade600, size: 20),
          const SizedBox(width: 8),
          Text(
            'Đã chấm công',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      );
    }

    // Not eligible (completed, missed, or scheduled future shift)
    if (!shift.isCheckInEligible) {
      return const SizedBox.shrink();
    }

    // Eligible — show the check-in button
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: isCheckingIn ? null : onCheckIn,
        icon: isCheckingIn
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.login_rounded),
        label: Text(
          isCheckingIn ? 'Đang xử lý...' : 'Chấm công vào ca',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_time_utils.dart';
import '../viewmodels/schedule_view_model.dart';
import 'pressable_scale.dart';

/// A compact bar that shows the selected week range and opens a date picker
/// when tapped so the employee can jump to any week.
class WeekSelectorBar extends ConsumerWidget {
  const WeekSelectorBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleState = ref.watch(scheduleViewModelProvider);
    final weekStart = scheduleState.selectedWeekStart;
    final weekEnd = scheduleState.selectedWeekEnd;
    final label = DateTimeUtils.formatWeekRangeLabel(weekStart, weekEnd);

    // Check if today falls in the selected week to show a small indicator.
    final today = DateTime.now();
    final todayInWeek =
        !today.isBefore(weekStart) &&
        !today.isAfter(weekEnd.add(const Duration(hours: 23, minutes: 59)));

    return PressableScale(
      onTap: () => _openDatePicker(context, ref, weekStart),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (todayInWeek) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Tuần hiện tại',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 22,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDatePicker(
    BuildContext context,
    WidgetRef ref,
    DateTime currentWeekStart,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentWeekStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Chọn tuần',
      cancelText: 'Huỷ',
      confirmText: 'Chọn',
    );
    if (picked != null) {
      // Tell the ViewModel to switch to the week containing the picked date.
      await ref.read(scheduleViewModelProvider.notifier).selectDate(picked);
    }
  }
}

import 'package:flutter/material.dart';

import '../../../core/utils/date_time_utils.dart';
import '../../../data/models/shift_model.dart';
import 'pressable_scale.dart';
import 'shift_status_badge.dart';

/// A compact card showing a single shift in the weekly list.
///
/// Tapping navigates to the shift detail screen.
class ShiftCard extends StatelessWidget {
  const ShiftCard({super.key, required this.shift, required this.onTap});

  final ShiftModel shift;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isToday = DateTimeUtils.isSameDay(shift.date, DateTime.now());
    final colorScheme = Theme.of(context).colorScheme;

    return PressableScale(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isToday
                ? colorScheme.primary.withValues(alpha: 0.4)
                : colorScheme.outlineVariant,
            width: isToday ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: date block
              _DateBlock(date: shift.date, isToday: isToday),
              const SizedBox(width: 14),
              // Right: shift details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time + status badge row
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateTimeUtils.formatTimeRange(
                            shift.startTime,
                            shift.endTime,
                          ),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ShiftStatusBadge(shift: shift, small: true),
                            const SizedBox(height: 4),
                            AttendanceStatusBadge(shift: shift, small: true),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Role
                    Text(
                      shift.role,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            shift.location,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Checked-in indicator
                    if (shift.isAlreadyCheckedIn) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 13,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Đã chấm công',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: Colors.green.shade600),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small date block shown on the left side of the shift card.
class _DateBlock extends StatelessWidget {
  const _DateBlock({required this.date, required this.isToday});

  final DateTime date;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = isToday
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest;
    final fg = isToday ? colorScheme.onPrimary : colorScheme.onSurface;
    final fgSub = isToday
        ? colorScheme.onPrimary.withValues(alpha: 0.8)
        : colorScheme.onSurfaceVariant;

    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateTimeUtils.viWeekdayShort(date),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: fgSub,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            date.day.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: fg,
              height: 1.1,
            ),
          ),
          Text(
            'Th.${date.month}',
            style: TextStyle(fontSize: 10, color: fgSub),
          ),
        ],
      ),
    );
  }
}

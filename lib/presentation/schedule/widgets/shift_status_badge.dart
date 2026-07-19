import 'package:flutter/material.dart';

import '../../../data/models/shift_model.dart';

/// A small colored pill that displays the shift status in Vietnamese.
///
/// Colors match the shift status:
///   active  → green
///   upcoming/scheduled → blue
///   completed → grey
///   missed → red
class ShiftStatusBadge extends StatelessWidget {
  const ShiftStatusBadge({super.key, required this.shift, this.small = false});

  final ShiftModel shift;

  /// If true, uses slightly smaller text and padding (for compact cards).
  final bool small;

  @override
  Widget build(BuildContext context) {
    final color = shift.statusColor;
    final bgColor = color.withValues(alpha: 0.12);
    final textColor = color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dot indicator
          Container(
            width: small ? 6 : 7,
            height: small ? 6 : 7,
            decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            shift.statusLabel,
            style: TextStyle(
              color: textColor,
              fontSize: small ? 11 : 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// A badge that displays the current attendance status.
class AttendanceStatusBadge extends StatelessWidget {
  const AttendanceStatusBadge({
    super.key,
    required this.shift,
    this.small = false,
  });

  final ShiftModel shift;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final color = shift.attendanceStatusColor;
    final bgColor = color.withValues(alpha: 0.12);
    final textColor = color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            shift.checkedInAt != null
                ? Icons.verified_rounded
                : Icons.pending_actions_rounded,
            size: small ? 11 : 13,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            shift.attendanceStatusLabel,
            style: TextStyle(
              color: textColor,
              fontSize: small ? 11 : 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

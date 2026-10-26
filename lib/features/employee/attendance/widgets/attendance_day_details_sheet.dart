// lib/features/employee/attendance/widgets/attendance_day_details_sheet.dart

import 'package:flutter/material.dart';

import '../utils/attendance_resolver.dart';
import '../utils/attendance_theme.dart';

/// Bottom sheet shown when a day in the calendar is tapped.
Future<void> showAttendanceDayDetails(
    BuildContext context, {
      required AttendanceDayInfo info,
    }) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _DaySheet(info: info),
  );
}

class _DaySheet extends StatelessWidget {
  final AttendanceDayInfo info;
  const _DaySheet({required this.info});

  @override
  Widget build(BuildContext context) {
    final r = info.record;
    final style = info.hasStatus ? AttendanceStatuses.of(info.status) : null;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AttendanceColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Text(
                    AttendanceFormatters.fullDate(
                      info.day,
                      info.date.month,
                      info.date.year,
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AttendanceColors.textDark,
                    ),
                  ),
                ),
                if (style != null)
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: style.bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(style.icon, size: 14, color: style.fg),
                        const SizedBox(width: 5),
                        Text(
                          info.label,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: style.fg,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (r == null)
              _emptyState()
            else ...[
              _row(
                Icons.login_rounded,
                'First check-in',
                AttendanceFormatters.timeAmPm(r.checkInTime),
              ),
              _row(
                Icons.logout_rounded,
                'Last check-out',
                AttendanceFormatters.timeAmPm(r.checkOutTime),
              ),
              _row(
                Icons.timer_outlined,
                'Hours worked',
                AttendanceFormatters.duration(r.totalWorkSeconds),
              ),
              if (info.isHalfDay)
                _row(
                  Icons.timelapse_rounded,
                  'Day type',
                  'Half day',
                  valueColor: AttendanceColors.halfDay,
                ),
              if (r.isLate)
                _row(
                  Icons.schedule_rounded,
                  'Late by',
                  '${r.lateByMinutes} min',
                  valueColor: AttendanceColors.late,
                ),
              if (r.hasPunches)
                _row(
                  Icons.location_on_outlined,
                  'Location',
                  r.punches.every((p) => p.withinRadius)
                      ? 'Verified (inside office radius)'
                      : 'Outside office radius',
                  valueColor: r.punches.every((p) => p.withinRadius)
                      ? AttendanceColors.present
                      : AttendanceColors.absent,
                ),
              if (r.markedByAdmin)
                _row(
                  Icons.verified_user_outlined,
                  'Marked by',
                  'Admin',
                  valueColor: AttendanceColors.primary,
                ),
            ],

            const SizedBox(height: 14),
            SizedBox(
              height: 46,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AttendanceColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    String message;
    IconData icon = Icons.event_busy_outlined;

    switch (info.status) {
      case 'absent':
        message = 'No check-in was recorded for this day.';
        break;
      case 'week_off':
        message = 'Weekly off.';
        icon = Icons.weekend_outlined;
        break;
      default:
        message = info.isFuture
            ? 'This day has not happened yet.'
            : 'No attendance record for this day.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 26),
      decoration: BoxDecoration(
        color: AttendanceColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: AttendanceColors.textLight),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              color: AttendanceColors.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
      IconData icon,
      String label,
      String value, {
        Color valueColor = AttendanceColors.textDark,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AttendanceColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AttendanceColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AttendanceColors.primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AttendanceColors.textMedium,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
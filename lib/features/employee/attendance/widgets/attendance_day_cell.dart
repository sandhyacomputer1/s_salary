// lib/features/employee/attendance/widgets/attendance_day_cell.dart

import 'package:flutter/material.dart';

import '../models/attendance_day_model.dart';
import '../utils/attendance_theme.dart';

class AttendanceDayCell extends StatelessWidget {
  final int? day;             // null = blank leading cell
  final String isoDate;       // "" when day is null
  final AttendanceDayModel? record;
  final bool isToday;

  const AttendanceDayCell({
    super.key,
    required this.day,
    required this.isoDate,
    required this.record,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    if (day == null) return const SizedBox.shrink();

    final pill = _pillFor(record);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AttendanceColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isToday ? AttendanceColors.primary : AttendanceColors.border,
          width: isToday ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$day',
            style: AttendanceText.dayNumber,
          ),
          const SizedBox(height: 8),
          if (pill != null)
            _Pill(label: pill.label, fg: pill.fg, bg: pill.bg)
          else
            const SizedBox(height: 18),
        ],
      ),
    );
  }

  _PillData? _pillFor(AttendanceDayModel? r) {
    if (r == null) return null;
    final label = r.shortLabel;
    if (label.isEmpty) return null;

    switch (r.status) {
      case 'present':
        return _PillData(label, AttendanceColors.present, AttendanceColors.presentBg);
      case 'late':
        return _PillData(label, AttendanceColors.late, AttendanceColors.lateBg);
      case 'absent':
        return _PillData(label, AttendanceColors.absent, AttendanceColors.absentBg);
      case 'half_day':
        return _PillData(label, AttendanceColors.late, AttendanceColors.lateBg);
      case 'on_leave':
        return _PillData(label, AttendanceColors.leave, AttendanceColors.leaveBg);
      case 'holiday':
        return _PillData(label, AttendanceColors.holiday, AttendanceColors.holidayBg);
      case 'week_off':
        return _PillData(label, AttendanceColors.off, AttendanceColors.offBg);
      default:
        return _PillData(label, AttendanceColors.off, AttendanceColors.offBg);
    }
  }
}

class _PillData {
  final String label;
  final Color fg;
  final Color bg;
  const _PillData(this.label, this.fg, this.bg);
}

class _Pill extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;

  const _Pill({required this.label, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AttendanceText.pill.copyWith(color: fg),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
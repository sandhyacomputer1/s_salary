import 'package:flutter/material.dart';

import '../models/admin_employee_profile_models.dart';
import 'admin_employee_theme.dart';
import 'admin_profile_common.dart';

/// One cell of the month grid.
class AdminAttendanceDay {
  final DateTime date; // UTC midnight
  final String key; // yyyy-MM-dd
  final bool inMonth;
  final bool isToday;

  /// present | late | half_day | absent | on_leave | holiday | off | none
  final String kind;
  final String? timeLabel; // "11:46 AM" (real check-in only)
  final bool byAdmin;
  final String holidayName;

  const AdminAttendanceDay({
    required this.date,
    required this.key,
    required this.inMonth,
    required this.isToday,
    required this.kind,
    this.timeLabel,
    this.byAdmin = false,
    this.holidayName = '',
  });

  /// A day the employee is expected to work (can be bulk-selected).
  bool get isWorkingDay => inMonth && kind != 'off' && kind != 'holiday';
}

class AdminAttendanceStyle {
  final Color fg;
  final Color bg;
  final String label;
  const AdminAttendanceStyle(this.fg, this.bg, this.label);
}

AdminAttendanceStyle adminAttendanceStyle(String kind) {
  switch (kind) {
    case 'present':
      return const AdminAttendanceStyle(Color(0xFF15803D), Color(0xFFDCFCE7), 'Present');
    case 'late':
      return const AdminAttendanceStyle(Color(0xFFB45309), Color(0xFFFEF3C7), 'Late');
    case 'half_day':
      return const AdminAttendanceStyle(Color(0xFF1D4ED8), Color(0xFFDBEAFE), 'Half Day');
    case 'absent':
      return const AdminAttendanceStyle(Color(0xFFC62828), Color(0xFFFDE2E2), 'Absent');
    case 'on_leave':
      return const AdminAttendanceStyle(Color(0xFF6D28D9), Color(0xFFEDE9FE), 'On Leave');
    case 'holiday':
      return const AdminAttendanceStyle(Color(0xFF1D4ED8), Color(0xFFDBEAFE), 'Holiday');
    case 'off':
      return const AdminAttendanceStyle(Color(0xFF6B7280), Color(0xFFF1F2F4), 'Off');
    default:
      return const AdminAttendanceStyle(Color(0xFF9CA3AF), Colors.transparent, '—');
  }
}

/// Builds the grid data: attendance records + company calendar + "absent" for
/// past working days that have no record (same rule as the web).
class AdminAttendanceCalendarData {
  AdminAttendanceCalendarData._();

  static String keyOf(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  static String _kindOf(AdminAttendanceLog l) {
    switch (l.status.toLowerCase()) {
      case 'present':
        return l.isLate ? 'late' : 'present';
      case 'late':
        return 'late';
      case 'half_day':
        return 'half_day';
      case 'absent':
        return 'absent';
      case 'leave':
      case 'on_leave':
        return 'on_leave';
      case 'holiday':
        return 'holiday';
      case 'week_off':
        return 'off';
      default:
        return 'present';
    }
  }

  static List<AdminAttendanceDay> build({
    required int month,
    required int year,
    required List<AdminAttendanceLog> logs,
    required List<AdminCalendarDay> calendar,
  }) {
    final first = DateTime.utc(year, month, 1);
    final daysInMonth = DateTime.utc(year, month + 1, 0).day;
    final lead = first.weekday - 1; // Monday = 0
    final total = ((lead + daysInMonth + 6) ~/ 7) * 7;
    final start = first.subtract(Duration(days: lead));

    final byKey = {for (final l in logs) l.dateKey: l};
    final cal = {for (final c in calendar) c.dateKey: c};

    final monthPrefix = keyOf(first).substring(0, 7);
    final hasWeekOffData =
    calendar.any((c) => c.type == 'week_off' && c.dateKey.startsWith(monthPrefix));

    final now = DateTime.now();
    final todayKey = keyOf(DateTime(now.year, now.month, now.day));

    final days = <AdminAttendanceDay>[];
    for (var i = 0; i < total; i++) {
      final d = start.add(Duration(days: i));
      final key = keyOf(d);
      final inMonth = d.month == month;

      var kind = 'none';
      String? timeLabel;
      var byAdmin = false;
      var holidayName = '';

      if (inMonth) {
        final log = byKey[key];
        final c = cal[key];

        if (log != null) {
          kind = _kindOf(log);
          byAdmin = log.markedByAdmin;
          if (!byAdmin && log.checkIn != null && (kind == 'present' || kind == 'late')) {
            timeLabel = adminProfTime(log.checkIn);
          }
        } else if (c != null && c.type == 'holiday') {
          kind = 'holiday';
          holidayName = c.name;
        } else if (c != null && c.type == 'week_off') {
          kind = 'off';
        } else if (!hasWeekOffData && (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday)) {
          kind = 'off'; // fallback when the API sends no week-off data
        } else if (key.compareTo(todayKey) < 0) {
          kind = 'absent';
        }
      }

      days.add(AdminAttendanceDay(
        date: d,
        key: key,
        inMonth: inMonth,
        isToday: key == todayKey,
        kind: kind,
        timeLabel: timeLabel,
        byAdmin: byAdmin,
        holidayName: holidayName,
      ));
    }
    return days;
  }
}

/// MON..SUN header + the weeks of the month.
class AdminAttendanceCalendar extends StatelessWidget {
  final List<AdminAttendanceDay> days;
  final Set<String> selected;
  final void Function(String key) onToggle;
  final void Function(AdminAttendanceDay day) onTapDay;

  const AdminAttendanceCalendar({
    super.key,
    required this.days,
    required this.selected,
    required this.onToggle,
    required this.onTapDay,
  });

  static const List<String> _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 8.0;
        final cellW = (c.maxWidth - gap * 6) / 7;
        final compact = cellW < 84;
        final cellH = compact ? 64.0 : 98.0;

        final weeks = <List<AdminAttendanceDay>>[];
        for (var i = 0; i < days.length; i += 7) {
          weeks.add(days.sublist(i, i + 7));
        }

        return Column(
          children: [
            Row(
              children: [
                for (var i = 0; i < 7; i++) ...[
                  if (i != 0) const SizedBox(width: gap),
                  Expanded(
                    child: Center(
                      child: Text(
                        compact ? _weekdays[i].substring(0, 1) : _weekdays[i],
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AdminEmpColors.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            for (final week in weeks)
              Padding(
                padding: const EdgeInsets.only(bottom: gap),
                child: Row(
                  children: [
                    for (var i = 0; i < 7; i++) ...[
                      if (i != 0) const SizedBox(width: gap),
                      Expanded(
                        child: SizedBox(
                          height: cellH,
                          child: _cell(week[i], compact),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _cell(AdminAttendanceDay day, bool compact) {
    // days of the previous / next month: faded, not clickable
    if (!day.inMonth) {
      return Container(
        padding: EdgeInsets.all(compact ? 6 : 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(
            '${day.date.day}',
            style: TextStyle(
              fontSize: compact ? 12 : 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFD1D5DB),
            ),
          ),
        ),
      );
    }

    final isSelected = selected.contains(day.key);
    final borderColor = day.isToday || isSelected ? AdminEmpColors.primary : AdminEmpColors.border;

    return Material(
      color: isSelected ? AdminEmpColors.primarySoft : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onTapDay(day),
        onLongPress: () => onToggle(day.key),
        child: Ink(
          padding: EdgeInsets.all(compact ? 6 : 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: day.isToday ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${day.date.day}',
                    style: TextStyle(
                      fontSize: compact ? 12.5 : 15.5,
                      fontWeight: FontWeight.w700,
                      color: day.isToday ? AdminEmpColors.primary : AdminEmpColors.text,
                    ),
                  ),
                  const Spacer(),
                  if (!compact)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (_) => onToggle(day.key),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        activeColor: AdminEmpColors.primary,
                        side: const BorderSide(color: Color(0xFFC9CED6), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                ],
              ),
              SizedBox(height: compact ? 4 : 8),
              Flexible(child: _status(day, compact)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _status(AdminAttendanceDay day, bool compact) {
    if (day.kind == 'none') {
      return const Text('—', style: TextStyle(color: Color(0xFFB8BFCA), fontSize: 13));
    }

    final st = adminAttendanceStyle(day.kind);
    var label = st.label;
    if (day.timeLabel != null && !compact) label = '$label (${day.timeLabel})';
    if (day.kind == 'holiday' && day.holidayName.isNotEmpty && !compact) label = day.holidayName;

    final pill = Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 9, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(color: st.bg, borderRadius: BorderRadius.circular(6)),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            fontSize: compact ? 10 : 12.5,
            fontWeight: FontWeight.w700,
            color: st.fg,
          ),
        ),
      ),
    );

    if (compact) return Align(alignment: Alignment.centerLeft, child: pill);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: pill),
        if (day.byAdmin) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFD9DEE7)),
            ),
            child: const Text(
              'Marked by Admin',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
            ),
          ),
        ],
      ],
    );
  }
}
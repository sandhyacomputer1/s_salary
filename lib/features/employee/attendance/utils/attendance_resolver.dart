// lib/features/employee/attendance/utils/attendance_resolver.dart

import '../models/attendance_day_model.dart';
import '../models/attendance_summary_model.dart';
import 'attendance_theme.dart';

/// The web calendar has no "Half Day" status - a half day is shown (and
/// counted) as Present. Set to false to show "Half Day" separately.
const bool kShowHalfDayAsPresent = true;

/// One calendar day after the rules below were applied (same as the web):
///  - a record from the server        -> its status
///  - no record + weekly off          -> "Off"
///  - no record + past working day    -> "Absent"
///  - no record + today / future      -> nothing ("—")
class AttendanceDayInfo {
  final int day;
  final DateTime date;
  final String status; // present | late | half_day | absent | on_leave | holiday | week_off | ''
  final AttendanceDayModel? record;
  final bool derived; // status was worked out, not sent by the server
  final bool isToday;
  final bool isFuture;

  const AttendanceDayInfo({
    required this.day,
    required this.date,
    required this.status,
    required this.record,
    required this.derived,
    required this.isToday,
    required this.isFuture,
  });

  bool get hasStatus => status.isNotEmpty;
  bool get markedByAdmin => record?.markedByAdmin ?? false;

  /// The server marked this day as a half day (even if shown as Present).
  bool get isHalfDay => record?.displayStatus == 'half_day';

  /// Label used on the day pill (web wording).
  String get label {
    switch (status) {
      case 'present':
        return 'Present';
      case 'late':
        return 'Late';
      case 'half_day':
        return 'Half Day';
      case 'absent':
        return 'Absent';
      case 'on_leave':
        return 'Leave';
      case 'holiday':
        return 'Holiday';
      case 'week_off':
        return 'Off';
      default:
        return '';
    }
  }

  /// "10:07 AM" when the employee really checked in that day.
  String? get checkInLabel {
    final t = record?.checkInTime;
    if (t == null) return null;
    if (status != 'present' && status != 'late' && status != 'half_day') {
      return null;
    }
    final text = AttendanceFormatters.timeAmPm(t);
    return text == '—' ? null : text;
  }
}

List<AttendanceDayInfo> resolveMonth({
  required int month,
  required int year,
  required List<AttendanceDayModel> records,
  required Set<int> weeklyOffs,
}) {
  final byDate = <String, AttendanceDayModel>{
    for (final r in records) r.date: r,
  };

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Absent is only worked out from the first record of the month onwards,
  // so days before the employee joined are not shown as absent.
  DateTime? firstRecord;
  for (final r in records) {
    final d = DateTime.tryParse(r.date);
    if (d != null && (firstRecord == null || d.isBefore(firstRecord))) {
      firstRecord = DateTime(d.year, d.month, d.day);
    }
  }

  final count = AttendanceFormatters.daysInMonth(month, year);
  final result = <AttendanceDayInfo>[];

  for (var day = 1; day <= count; day++) {
    final date = DateTime(year, month, day);
    final record = byDate[AttendanceFormatters.isoDate(day, month, year)];

    var status = '';
    var derived = false;

    if (record != null &&
        AttendanceStatuses.of(record.displayStatus) != null) {
      status = record.displayStatus;
      if (kShowHalfDayAsPresent && status == 'half_day') status = 'present';
    } else if (weeklyOffs.contains(date.weekday)) {
      status = 'week_off';
      derived = true;
    } else if (date.isBefore(today) &&
        firstRecord != null &&
        !date.isBefore(firstRecord)) {
      status = 'absent';
      derived = true;
    }

    result.add(
      AttendanceDayInfo(
        day: day,
        date: date,
        status: status,
        record: record,
        derived: derived,
        isToday: date == today,
        isFuture: date.isAfter(today),
      ),
    );
  }

  return result;
}

/// Same counting as the web chips:
/// Present = present + late + half day, Holidays = real holidays only.
AttendanceSummaryModel summarize(List<AttendanceDayInfo> days) {
  int present = 0, late = 0, half = 0, absent = 0;
  int leave = 0, holiday = 0, off = 0;
  int seconds = 0;

  for (final d in days) {
    seconds += d.record?.totalWorkSeconds ?? 0;

    switch (d.status) {
      case 'present':
        present++;
        break;
      case 'late':
        late++;
        present++;
        break;
      case 'half_day':
        half++;
        present++;
        break;
      case 'absent':
        absent++;
        break;
      case 'on_leave':
        leave++;
        break;
      case 'holiday':
        holiday++;
        break;
      case 'week_off':
        off++;
        break;
    }
  }

  return AttendanceSummaryModel(
    present: present,
    late: late,
    halfDay: half,
    absent: absent,
    onLeave: leave,
    holiday: holiday,
    weekOff: off,
    hours: seconds / 3600,
  );
}
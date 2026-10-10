// lib/features/employee/attendance/models/attendance_summary_model.dart

/// `GET /attendance/employee/:employeeId/summary?month=&year=`
///
/// Live response (verified): { present, late, half_day, absent, on_leave,
/// holiday, week_off, hours }. There is no `totalHours`, `avgHours` or `days`.
class AttendanceSummaryModel {
  final int present;
  final int late;
  final int halfDay;
  final int absent;
  final int onLeave;
  final int holiday;
  final int weekOff;
  final double hours;

  const AttendanceSummaryModel({
    required this.present,
    required this.late,
    required this.halfDay,
    required this.absent,
    required this.onLeave,
    required this.holiday,
    required this.weekOff,
    required this.hours,
  });

  static const AttendanceSummaryModel empty = AttendanceSummaryModel(
    present: 0,
    late: 0,
    halfDay: 0,
    absent: 0,
    onLeave: 0,
    holiday: 0,
    weekOff: 0,
    hours: 0,
  );

  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> j) {
    return AttendanceSummaryModel(
      present: _toInt(j['present']),
      late: _toInt(j['late']),
      halfDay: _toInt(j['half_day']),
      absent: _toInt(j['absent']),
      onLeave: _toInt(j['on_leave']),
      holiday: _toInt(j['holiday']),
      weekOff: _toInt(j['week_off']),
      hours: _toDouble(j['hours']),
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
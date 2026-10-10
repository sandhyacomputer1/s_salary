// lib/features/employee/attendance/models/attendance_day_model.dart

/// One day from `GET /attendance/my-history?month=&year=`.
class AttendanceDayModel {
  final String id;
  final String date;       // "YYYY-MM-DD"
  final String status;     // present | absent | half_day | late | on_leave | holiday | week_off
  final bool isLate;
  final int lateByMinutes;
  final int totalWorkSeconds;

  const AttendanceDayModel({
    required this.id,
    required this.date,
    required this.status,
    required this.isLate,
    required this.lateByMinutes,
    required this.totalWorkSeconds,
  });

  factory AttendanceDayModel.fromJson(Map<String, dynamic> j) {
    return AttendanceDayModel(
      id: (j['_id'] ?? '').toString(),
      date: (j['date'] ?? '').toString(),
      status: (j['status'] ?? '').toString().toLowerCase(),
      isLate: j['isLate'] == true,
      lateByMinutes: _toInt(j['lateByMinutes']),
      totalWorkSeconds: _toInt(j['totalWorkSeconds']),
    );
  }

  /// Short pill label rendered on the calendar cell.
  String get shortLabel {
    switch (status) {
      case 'present':
        return 'Present';
      case 'absent':
        return 'Absent';
      case 'half_day':
        return 'Half Day';
      case 'late':
        return 'Late';
      case 'on_leave':
        return 'Leave';
      case 'holiday':
        return 'Holiday';
      case 'week_off':
        return 'Off';
      default:
        return status.isEmpty ? '' : status;
    }
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
// lib/features/employee/attendance/models/attendance_day_model.dart

class AttendancePunch {
  final String? type;
  final String? time;
  final bool withinRadius;

  const AttendancePunch({
    required this.type,
    required this.time,
    required this.withinRadius,
  });

  factory AttendancePunch.fromJson(Map<String, dynamic> j) {
    return AttendancePunch(
      type: j['type']?.toString(),
      time: j['time']?.toString(),
      withinRadius: j['isWithinRadius'] == true,
    );
  }
}

/// One day of attendance.
///
/// Real response (confirmed via Postman):
/// { "date": "2026-10-06", "checkIn": {"isWithinRadius": true},
///   "checkOut": {...}, "status": "on_leave", "totalWorkSeconds": 0,
///   "isLate": false, "lateByMinutes": 0, "punches": [] }
class AttendanceDayModel {
  final String id;
  final String date; // "YYYY-MM-DD"
  final String status; // present | absent | half_day | late | on_leave | holiday | week_off
  final bool isLate;
  final int lateByMinutes;
  final int totalWorkSeconds;
  final List<AttendancePunch> punches;

  /// true when an admin / HR marked this day (shown as "Marked by Admin").
  final bool markedByAdmin;

  const AttendanceDayModel({
    required this.id,
    required this.date,
    required this.status,
    required this.isLate,
    required this.lateByMinutes,
    required this.totalWorkSeconds,
    this.punches = const [],
    this.markedByAdmin = false,
  });

  factory AttendanceDayModel.fromJson(Map<String, dynamic> j) {
    final punchesJson = j['punches'];

    return AttendanceDayModel(
      id: (j['_id'] ?? '').toString(),
      date: _normalizeDate(j['date']),
      status: (j['status'] ?? '').toString().toLowerCase(),
      isLate: j['isLate'] == true,
      lateByMinutes: _toInt(j['lateByMinutes']),
      totalWorkSeconds: _toInt(j['totalWorkSeconds']),
      punches: punchesJson is List
          ? punchesJson
          .whereType<Map>()
          .map((p) => AttendancePunch.fromJson(Map<String, dynamic>.from(p)))
          .toList()
          : const [],
      markedByAdmin: _detectAdmin(j),
    );
  }

  /// The backend field name is not fixed, so several common names are
  /// checked. Send me one real record if "Marked by Admin" does not show.
  static bool _detectAdmin(Map<String, dynamic> j) {
    bool truthy(dynamic v) =>
        v == true || v?.toString().toLowerCase() == 'true';

    const flags = [
      'markedByAdmin', 'isMarkedByAdmin', 'adminMarked', 'isAdminMarked',
      'isManual', 'manual', 'manualEntry', 'isManualEntry', 'manuallyMarked',
    ];
    for (final k in flags) {
      if (truthy(j[k])) return true;
    }

    final word = RegExp(r'(^|[^a-z])(admin|manual|hr)([^a-z]|$)');
    const texts = [
      'source', 'markType', 'markedVia', 'entryType', 'markedFrom',
      'method', 'type', 'updatedByRole', 'modifiedByRole', 'createdByRole',
      'markedByRole',
    ];
    for (final k in texts) {
      final v = j[k];
      if (v == null) continue;
      final text = (v is Map ? v.values.join(' ') : v.toString()).toLowerCase();
      if (word.hasMatch(text)) return true;
    }

    // "markedBy": <admin user id / object>  -> admin marked it
    for (final k in const ['markedBy', 'marked_by']) {
      final v = j[k];
      if (v == null) continue;
      if (v is Map) {
        if (v.isNotEmpty) return true;
      } else {
        final t = v.toString().trim().toLowerCase();
        if (t.isNotEmpty &&
            !const ['system', 'self', 'employee', 'auto', 'null'].contains(t)) {
          return true;
        }
      }
    }

    return false;
  }

  /// "2026-10-06" stays as is, a full date-time is converted to the
  /// local calendar day.
  static String _normalizeDate(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return '';
    if (raw.length == 10 && !raw.contains('T')) return raw;

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw.length >= 10 ? raw.substring(0, 10) : raw;

    final d = parsed.toLocal();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// A present day that was late is shown as "late".
  String get displayStatus =>
      (status == 'present' && isLate) ? 'late' : status;

  String? get checkInTime => punches.isNotEmpty ? punches.first.time : null;
  String? get checkOutTime => punches.length > 1 ? punches.last.time : null;

  bool get hasPunches => punches.isNotEmpty;

  /// Short label ("Present", "Leave" ...).
  String get shortLabel {
    switch (displayStatus) {
      case 'present':
        return 'Present';
      case 'absent':
        return 'Absent';
      case 'half_day':
      case 'half-day':
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
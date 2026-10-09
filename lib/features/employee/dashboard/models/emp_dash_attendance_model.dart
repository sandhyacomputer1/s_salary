class EmpDashAttendancePunch {
  final String? type;
  final String? time;
  final bool isWithinRadius;

  const EmpDashAttendancePunch({
    required this.type,
    required this.time,
    required this.isWithinRadius,
  });

  factory EmpDashAttendancePunch.fromJson(Map<String, dynamic> json) {
    return EmpDashAttendancePunch(
      type: json['type']?.toString(),
      time: json['time']?.toString(),
      isWithinRadius: json['isWithinRadius'] == true,
    );
  }
}

class EmpDashAttendanceRecord {
  final DateTime? date;
  final bool checkInWithinRadius;
  final bool checkOutWithinRadius;
  final String status;
  final double totalHours;
  final bool isLate;
  final int lateByMinutes;
  final List<EmpDashAttendancePunch> punches;

  const EmpDashAttendanceRecord({
    required this.date,
    required this.checkInWithinRadius,
    required this.checkOutWithinRadius,
    required this.status,
    required this.totalHours,
    required this.isLate,
    required this.lateByMinutes,
    required this.punches,
  });

  /// Real response shape confirmed via Postman:
  /// {
  ///   "date": "2026-10-06",
  ///   "checkIn": { "isWithinRadius": true },
  ///   "checkOut": { "isWithinRadius": true },
  ///   "status": "on_leave",
  ///   "totalWorkSeconds": 0,
  ///   "isLate": false,
  ///   "lateByMinutes": 0,
  ///   "punches": []
  /// }
  ///
  /// NOTE: no record seen so far has actual check-in/check-out TIMES —
  /// only isWithinRadius. Real punch times are expected to live inside
  /// "punches" once a populated example is available; until then,
  /// checkInTime/checkOutTime below fall back to the first/last punch
  /// if present, else null.
  factory EmpDashAttendanceRecord.fromJson(Map<String, dynamic> json) {
    final checkInJson = json['checkIn'];
    final checkOutJson = json['checkOut'];
    final punchesJson = json['punches'];

    final punches = punchesJson is List
        ? punchesJson
        .whereType<Map>()
        .map((p) => EmpDashAttendancePunch.fromJson(
      Map<String, dynamic>.from(p),
    ))
        .toList()
        : <EmpDashAttendancePunch>[];

    return EmpDashAttendanceRecord(
      date: _parseDate(json['date']),
      checkInWithinRadius: checkInJson is Map &&
          checkInJson['isWithinRadius'] == true,
      checkOutWithinRadius: checkOutJson is Map &&
          checkOutJson['isWithinRadius'] == true,
      status: json['status']?.toString().toLowerCase() ?? '',
      // Spec said "totalHours"; real response uses "totalWorkSeconds".
      totalHours: _secondsToHours(json['totalWorkSeconds']),
      isLate: json['isLate'] == true,
      lateByMinutes: _toInt(json['lateByMinutes']),
      punches: punches,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static double _secondsToHours(dynamic value) {
    if (value == null) return 0;
    final seconds = value is num
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 0;
    return seconds / 3600;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  /// First check-in time, if any punch data is present. Null when the
  /// day has no real punches (e.g. on_leave days).
  String? get checkInTime => punches.isNotEmpty ? punches.first.time : null;

  /// Last check-out time, if any punch data is present.
  String? get checkOutTime => punches.length > 1 ? punches.last.time : null;

  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';
  bool get isHalfDay => status == 'half_day' || status == 'half-day';
  bool get isOnLeave => status == 'on_leave';
}

/// Computed summary derived entirely from a list of
/// EmpDashAttendanceRecord — never fetched directly from any API.
class EmpDashAttendanceSummary {
  final int presentDays;
  final int lateArrivals;
  final int halfDays;
  final int absences;
  final int onLeaveDays;
  final int totalRecords;

  const EmpDashAttendanceSummary({
    required this.presentDays,
    required this.lateArrivals,
    required this.halfDays,
    required this.absences,
    required this.onLeaveDays,
    required this.totalRecords,
  });

  factory EmpDashAttendanceSummary.fromRecords(
      List<EmpDashAttendanceRecord> records,
      ) {
    int present = 0;
    int late = 0;
    int half = 0;
    int absent = 0;
    int onLeave = 0;

    for (final record in records) {
      if (record.isPresent) present++;
      if (record.isLate) late++;
      if (record.isHalfDay) half++;
      if (record.isAbsent) absent++;
      if (record.isOnLeave) onLeave++;
    }

    return EmpDashAttendanceSummary(
      presentDays: present,
      lateArrivals: late,
      halfDays: half,
      absences: absent,
      onLeaveDays: onLeave,
      totalRecords: records.length,
    );
  }

  bool get isEmpty => totalRecords == 0;
}
class AdminAttendanceModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String date;
  final String status;
  final bool isLate;
  final int lateByMinutes;

  final String? checkInTime;
  final String? checkOutTime;

  // Rich Data Fields (from JSON)
  final String? department;
  final String? checkInPhotoUrl;
  final String? checkOutPhotoUrl;
  final double? distanceMeters;
  final bool? withinGeofence;
  final double? workedHours;

  const AdminAttendanceModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.date,
    required this.status,
    required this.isLate,
    required this.lateByMinutes,
    this.checkInTime,
    this.checkOutTime,
    this.department,
    this.checkInPhotoUrl,
    this.checkOutPhotoUrl,
    this.distanceMeters,
    this.withinGeofence,
    this.workedHours,
  });

  factory AdminAttendanceModel.fromJson(Map<String, dynamic> j) {
    String name = 'Unknown Employee';
    String code = '';
    String eId = '';
    String? dept;

    // 1. Parse Employee Object (matches your screenshot)
    final empRaw = j['employeeId'];
    if (empRaw is Map) {
      eId = (empRaw['_id'] ?? '').toString();
      code = (empRaw['employeeCode'] ?? '').toString();
      dept = empRaw['department']?.toString();

      // Name is nested inside 'userID'
      final userRaw = empRaw['userID'];
      if (userRaw is Map) {
        name = (userRaw['name'] ?? 'Unknown').toString();
      } else {
        // Fallback if userID is flat
        name = (empRaw['name'] ?? 'Unknown').toString();
      }
    } else {
      eId = (empRaw ?? '').toString();
    }

    name = (j['employeeName'] ?? name).toString();
    code = (j['employeeCode'] ?? code).toString();
    dept = (j['department'] ?? dept)?.toString();

    // 2. Parse Check In / Out & Punches
    String? cIn;
    String? inPhoto;
    String? cOut;
    String? outPhoto;
    double? dist;
    bool? inRadius;

    // Look at root checkIn/checkOut first
    if (j['checkIn'] is Map) {
      final m = j['checkIn'] as Map;
      final t = m['time'];
      if (t != null && t.toString().isNotEmpty) cIn = t.toString();
      inPhoto = m['photoUrl']?.toString();
      dist = (m['distanceFromOffice'] as num?)?.toDouble();
      inRadius = m['isWithinRadius'] is bool ? m['isWithinRadius'] as bool : null;
    }

    if (j['checkOut'] is Map) {
      final m = j['checkOut'] as Map;
      final t = m['time'];
      if (t != null && t.toString().isNotEmpty) cOut = t.toString();
      outPhoto = m['photoUrl']?.toString();
      dist ??= (m['distanceFromOffice'] as num?)?.toDouble();
      inRadius ??= m['isWithinRadius'] is bool ? m['isWithinRadius'] as bool : null;
    }

    // Fallback to 'punches' array if root checkIn/out is empty
    if (j['punches'] is List) {
      for (final p in (j['punches'] as List)) {
        if (p is Map) {
          final type = p['type']?.toString();
          final t = p['time']?.toString();
          final photo = p['photoUrl']?.toString();

          if (type == 'in' && cIn == null) {
            cIn = t;
            inPhoto = photo;
            dist ??= (p['distanceFromOffice'] as num?)?.toDouble();
            inRadius ??= p['isWithinRadius'] is bool ? p['isWithinRadius'] as bool : null;
          } else if (type == 'out' && cOut == null) {
            cOut = t;
            outPhoto = photo;
            dist ??= (p['distanceFromOffice'] as num?)?.toDouble();
            inRadius ??= p['isWithinRadius'] is bool ? p['isWithinRadius'] as bool : null;
          }
        }
      }
    }

    return AdminAttendanceModel(
      id: (j['_id'] ?? '').toString(),
      employeeId: eId,
      employeeName: name,
      employeeCode: code,
      date: (j['date'] ?? '').toString(),
      status: (j['status'] ?? '').toString().toLowerCase(),
      isLate: j['isLate'] == true,
      lateByMinutes: (j['lateByMinutes'] as num?)?.toInt() ?? 0,
      checkInTime: cIn,
      checkOutTime: cOut,
      department: dept,
      checkInPhotoUrl: inPhoto,
      checkOutPhotoUrl: outPhoto,
      distanceMeters: dist,
      withinGeofence: inRadius,
      // Read totalHours directly from JSON
      workedHours: (j['totalHours'] as num?)?.toDouble(),
    );
  }

  bool get hasCheckedIn  => checkInTime  != null && checkInTime!.isNotEmpty;
  bool get hasCheckedOut => checkOutTime != null && checkOutTime!.isNotEmpty;

  bool get isCurrentlyInOffice =>
      hasCheckedIn &&
          !hasCheckedOut &&
          status != 'absent' &&
          status != 'on_leave' &&
          status != 'week_off' &&
          status != 'holiday';
}

enum AttendanceEventKind { checkIn, checkOut }

class AttendanceEvent {
  final AttendanceEventKind kind;
  final AdminAttendanceModel record;
  final DateTime? timestamp;

  const AttendanceEvent({
    required this.kind,
    required this.record,
    required this.timestamp,
  });

  String? get photoUrl => kind == AttendanceEventKind.checkIn
      ? record.checkInPhotoUrl
      : record.checkOutPhotoUrl;

  static List<AttendanceEvent> fromRecords(List<AdminAttendanceModel> records) {
    final events = <AttendanceEvent>[];
    for (final r in records) {
      if (r.hasCheckedIn) {
        events.add(AttendanceEvent(
          kind: AttendanceEventKind.checkIn,
          record: r,
          timestamp: DateTime.tryParse(r.checkInTime!)?.toLocal(),
        ));
      }
      if (r.hasCheckedOut) {
        events.add(AttendanceEvent(
          kind: AttendanceEventKind.checkOut,
          record: r,
          timestamp: DateTime.tryParse(r.checkOutTime!)?.toLocal(),
        ));
      }
    }
    events.sort((a, b) {
      final ta = a.timestamp, tb = b.timestamp;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });
    return events;
  }
}
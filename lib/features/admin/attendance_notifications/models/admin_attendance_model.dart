// lib/features/admin/attendance_notifications/models/admin_attendance_model.dart

class AdminAttendanceModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String date;
  final String status;
  final bool isLate;
  final int lateByMinutes;

  // Check In / Out
  final String? checkInTime;
  final String? checkOutTime;

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
  });

  factory AdminAttendanceModel.fromJson(Map<String, dynamic> j) {
    // Handle populated employeeId object or raw string
    String name = 'Unknown Employee';
    String code = '';
    String eId = '';

    final empRaw = j['employeeId'];
    if (empRaw is Map) {
      eId = (empRaw['_id'] ?? '').toString();
      name = (empRaw['name'] ?? 'Unknown').toString();
      code = (empRaw['employeeCode'] ?? '').toString();
    } else {
      eId = (empRaw ?? '').toString();
    }

    // Sometimes the backend flattens these fields at the root
    name = (j['employeeName'] ?? name).toString();
    code = (j['employeeCode'] ?? code).toString();

    // Safely parse times - only set if a valid string is present
    String? cIn;
    if (j['checkIn'] is Map) {
      final timeVal = j['checkIn']['time'];
      if (timeVal != null && timeVal.toString().isNotEmpty) {
        cIn = timeVal.toString();
      }
    }

    String? cOut;
    if (j['checkOut'] is Map) {
      final timeVal = j['checkOut']['time'];
      if (timeVal != null && timeVal.toString().isNotEmpty) {
        cOut = timeVal.toString();
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
    );
  }

  // Only true if the timestamp exists
  bool get hasCheckedIn => checkInTime != null && checkInTime!.isNotEmpty;

  // Only true if the timestamp exists
  bool get hasCheckedOut => checkOutTime != null && checkOutTime!.isNotEmpty;

  bool get isCurrentlyInOffice =>
      hasCheckedIn &&
          !hasCheckedOut &&
          status != 'absent' &&
          status != 'on_leave' &&
          status != 'week_off' &&
          status != 'holiday';
}
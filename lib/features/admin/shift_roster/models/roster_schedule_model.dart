// =================================================================
// ROSTER SCHEDULE MODEL
//
// Represents one employee's assigned shift schedule window.
//
// API RESPONSE:
//
// {
//   "_id": "...",
//   "companyId": "...",
//   "employeeId": {
//      "_id": "...",
//      "employeeCode": "EMP-0011",
//      "department": "Accounts",
//      "name": "sai",
//      "email": "sai@gmail.com"
//   },
//   "shiftId": {
//      "_id": "...",
//      "name": "Morning",
//      "code": "1212",
//      "startTime": "11:00",
//      "endTime": "18:00",
//      "graceMinutes": 15
//   },
//   "startDate": "2026-09-24",
//   "endDate": "2026-09-30",
//   "assignedBy": "...",
//   "notes": ""
// }
//
// The API returns employeeId and shiftId as populated objects.
// This model supports both:
//   1. Populated object
//   2. Simple ID string
// =================================================================

class RosterScheduleModel {
  final String id;

  // Employee
  final String employeeId;
  final String? employeeName;
  final String? employeeCode;
  final String? employeeEmail;
  final String? departmentId;
  final String? departmentName;

  // Shift
  final String shiftId;
  final String? shiftName;
  final String? shiftCode;
  final String? startTime;
  final String? endTime;
  final int? graceMinutes;

  // Schedule
  final DateTime? startDate;
  final DateTime? endDate;

  // Other
  final String? status;
  final String? notes;
  final String? companyId;
  final String? assignedBy;

  const RosterScheduleModel({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.employeeCode,
    this.employeeEmail,
    this.departmentId,
    this.departmentName,
    required this.shiftId,
    this.shiftName,
    this.shiftCode,
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.graceMinutes,
    this.status,
    this.notes,
    this.companyId,
    this.assignedBy,
  });

  // ============================================================
  // FROM JSON
  // ============================================================

  factory RosterScheduleModel.fromJson(
      Map<String, dynamic> json,
      ) {
    // ------------------------------------------------------------
    // EMPLOYEE
    // ------------------------------------------------------------

    final dynamic employeeData = json['employeeId'];

    String employeeId = '';
    String? employeeName;
    String? employeeCode;
    String? employeeEmail;
    String? departmentId;
    String? departmentName;

    if (employeeData is Map) {
      final employee = Map<String, dynamic>.from(employeeData);

      employeeId = (
          employee['_id'] ??
              employee['id'] ??
              ''
      ).toString();

      employeeName = employee['name']?.toString();
      employeeCode = employee['employeeCode']?.toString();
      employeeEmail = employee['email']?.toString();

      departmentId = employee['departmentId']?.toString();

      // IMPORTANT:
      // Actual API returns:
      // "department": "Accounts"
      departmentName =
          employee['departmentName']?.toString() ??
              employee['department']?.toString();
    } else {
      // In case backend sends only employee ID
      employeeId = (employeeData ?? '').toString();

      // Fallback for APIs which might return
      // employee information at root level.
      employeeName = json['employeeName']?.toString();
      employeeCode = json['employeeCode']?.toString();
      employeeEmail = json['employeeEmail']?.toString();
      departmentId = json['departmentId']?.toString();
      departmentName = json['departmentName']?.toString();
    }

    // ------------------------------------------------------------
    // SHIFT
    // ------------------------------------------------------------

    final dynamic shiftData = json['shiftId'];

    String shiftId = '';
    String? shiftName;
    String? shiftCode;
    String? startTime;
    String? endTime;
    int? graceMinutes;

    if (shiftData is Map) {
      final shift = Map<String, dynamic>.from(shiftData);

      shiftId = (
          shift['_id'] ??
              shift['id'] ??
              ''
      ).toString();

      shiftName =
          shift['name']?.toString() ??
              shift['shiftName']?.toString();

      shiftCode =
          shift['code']?.toString() ??
              shift['shiftCode']?.toString();

      startTime = shift['startTime']?.toString();

      endTime = shift['endTime']?.toString();

      graceMinutes = _toInt(
        shift['graceMinutes'] ??
            shift['gracePeriodMinutes'],
      );
    } else {
      // In case backend sends only shift ID
      shiftId = (shiftData ?? '').toString();

      // Fallback for APIs which might return shift
      // information at root level.
      shiftName =
          json['shiftName']?.toString();

      shiftCode =
          json['shiftCode']?.toString();

      startTime =
          json['startTime']?.toString();

      endTime =
          json['endTime']?.toString();

      graceMinutes = _toInt(
        json['graceMinutes'] ??
            json['gracePeriodMinutes'],
      );
    }

    // ------------------------------------------------------------
    // RETURN MODEL
    // ------------------------------------------------------------

    return RosterScheduleModel(
      id: (
          json['id'] ??
              json['_id'] ??
              ''
      ).toString(),

      employeeId: employeeId,

      employeeName: employeeName,
      employeeCode: employeeCode,
      employeeEmail: employeeEmail,

      departmentId: departmentId,
      departmentName: departmentName,

      shiftId: shiftId,

      shiftName: shiftName,
      shiftCode: shiftCode,

      startDate: DateTime.tryParse(
        json['startDate']?.toString() ?? '',
      ),

      endDate: DateTime.tryParse(
        json['endDate']?.toString() ?? '',
      ),

      startTime: startTime,
      endTime: endTime,

      graceMinutes: graceMinutes,

      status: json['status']?.toString(),

      notes: json['notes']?.toString(),

      companyId: json['companyId']?.toString(),

      assignedBy: json['assignedBy']?.toString(),
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'shiftId': shiftId,

      if (startDate != null)
        'startDate':
        startDate!.toIso8601String().split('T').first,

      if (endDate != null)
        'endDate':
        endDate!.toIso8601String().split('T').first,

      if (status != null)
        'status': status,

      if (notes != null)
        'notes': notes,
    };
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  // ============================================================
  // DISPLAY HELPERS
  // ============================================================

  String get employeeDisplayName {
    if (employeeName != null &&
        employeeName!.trim().isNotEmpty) {
      return employeeName!;
    }

    if (employeeCode != null &&
        employeeCode!.trim().isNotEmpty) {
      return employeeCode!;
    }

    return '—';
  }

  String get departmentDisplayName {
    if (departmentName != null &&
        departmentName!.trim().isNotEmpty) {
      return departmentName!;
    }

    return '—';
  }

  String get shiftDisplayName {
    if (shiftName != null &&
        shiftName!.trim().isNotEmpty) {
      if (shiftCode != null &&
          shiftCode!.trim().isNotEmpty) {
        return '$shiftName ($shiftCode)';
      }

      return shiftName!;
    }

    return '—';
  }

  String get scheduleWindow {
    if (startDate == null || endDate == null) {
      return '—';
    }

    return '${_formatDate(startDate!)} to ${_formatDate(endDate!)}';
  }

  String get timingDisplay {
    if (startTime == null || endTime == null) {
      return '—';
    }

    final grace = graceMinutes ?? 0;

    return '$startTime – $endTime (${grace}m grace)';
  }

  String get statusDisplay {
    if (status != null &&
        status!.trim().isNotEmpty) {
      return status!;
    }

    // Your API response does not currently contain
    // a status field. Since these records are returned
    // as active roster schedules, use Active Schedule
    // as the UI fallback.
    return 'active';
  }

  static String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
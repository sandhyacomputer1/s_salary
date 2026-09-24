// =================================================================
// ROSTER SCHEDULE MODEL
//
// Represents one employee's assigned shift schedule window.
// =================================================================

class RosterScheduleModel {
  final String id;
  final String employeeId;
  final String? employeeName;
  final String? employeeCode;
  final String? employeeEmail;
  final String? departmentId;
  final String? departmentName;
  final String shiftId;
  final String? shiftName;
  final String? shiftCode;
  final DateTime? startDate;
  final DateTime? endDate;

  /// 24h "HH:mm" strings, copied from the shift at assignment time
  /// so the schedule keeps its own record even if the shift later
  /// changes.
  final String? startTime;
  final String? endTime;
  final int? graceMinutes;
  final String? status;

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
  });

  factory RosterScheduleModel.fromJson(Map<String, dynamic> json) {
    return RosterScheduleModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      employeeId: (json['employeeId'] ?? '').toString(),
      employeeName: json['employeeName']?.toString(),
      employeeCode: json['employeeCode']?.toString(),
      employeeEmail: json['employeeEmail']?.toString(),
      departmentId: json['departmentId']?.toString(),
      departmentName: json['departmentName']?.toString(),
      shiftId: (json['shiftId'] ?? '').toString(),
      shiftName: json['shiftName']?.toString(),
      shiftCode: json['shiftCode']?.toString(),
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? ''),
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? ''),
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
      graceMinutes: json['graceMinutes'] == null
          ? null
          : (json['graceMinutes'] is num
          ? (json['graceMinutes'] as num).toInt()
          : int.tryParse(json['graceMinutes'].toString())),
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'shiftId': shiftId,
      if (startDate != null)
        'startDate': startDate!.toIso8601String().split('T').first,
      if (endDate != null)
        'endDate': endDate!.toIso8601String().split('T').first,
      if (status != null) 'status': status,
    };
  }
}
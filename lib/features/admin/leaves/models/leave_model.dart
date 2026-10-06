class LeaveEmployeeModel {
  final String id;
  final String employeeCode;
  final String name;

  const LeaveEmployeeModel({
    required this.id,
    required this.employeeCode,
    required this.name,
  });

  factory LeaveEmployeeModel.fromJson(Map<String, dynamic> json) {
    return LeaveEmployeeModel(
      id: json['_id']?.toString() ?? '',
      employeeCode: json['employeeCode']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class LeaveBalanceModel {
  final String id;
  final String employeeId;
  final int year;
  final String leaveType;
  final double allotted;
  final double used;
  final double remaining;

  const LeaveBalanceModel({
    required this.id,
    required this.employeeId,
    required this.year,
    required this.leaveType,
    required this.allotted,
    required this.used,
    required this.remaining,
  });

  factory LeaveBalanceModel.fromJson(Map<String, dynamic> json) {
    return LeaveBalanceModel(
      id: json['_id']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      year: _toInt(json['year']),
      leaveType: json['leaveType']?.toString() ?? '',
      allotted: _toDouble(json['allotted']),
      used: _toDouble(json['used']),
      remaining: _toDouble(json['remaining']),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

class LeaveModel {
  final String id;
  final LeaveEmployeeModel? employee;
  final String employeeIdRaw;
  final String companyId;
  final String leaveType;
  final bool isPaid;
  final DateTime? startDate;
  final DateTime? endDate;
  final double totalDays;
  final bool isHalfDay;
  final String reason;
  final String status;
  final String approvedBy;
  final DateTime? appliedAt;
  final DateTime? actionedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Resolved separately from GET /employees, since the leaves API's
  // employeeId object does not include a name field. Not part of the
  // parsed JSON — set externally after fetching the employee list.
  final String? resolvedEmployeeName;

  const LeaveModel({
    required this.id,
    required this.employee,
    required this.employeeIdRaw,
    required this.companyId,
    required this.leaveType,
    required this.isPaid,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.isHalfDay,
    required this.reason,
    required this.status,
    required this.approvedBy,
    required this.appliedAt,
    required this.actionedAt,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedEmployeeName,
  });

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    final employeeJson = json['employeeId'];

    return LeaveModel(
      id: json['_id']?.toString() ?? '',

      // employeeId may arrive as a populated object
      // ({_id, employeeCode} — and, per the docs, sometimes name —
      // but in practice name is not present) or as a plain id string
      // (seen in GET /leaves/employee/:id, and in the approve/reject
      // action responses).
      employee: employeeJson is Map
          ? LeaveEmployeeModel.fromJson(
        Map<String, dynamic>.from(employeeJson),
      )
          : null,

      employeeIdRaw: employeeJson is Map
          ? (employeeJson['_id']?.toString() ?? '')
          : (employeeJson?.toString() ?? ''),

      companyId: json['companyId']?.toString() ?? '',

      leaveType: json['leaveType']?.toString() ?? '',

      isPaid: json['isPaid'] == true,

      startDate: _parseDate(json['startDate']),

      endDate: _parseDate(json['endDate']),

      totalDays: _toDouble(json['totalDays']),

      isHalfDay: json['isHalfDay'] == true,

      reason: json['reason']?.toString() ?? '',

      status: json['status']?.toString().toLowerCase() ?? 'pending',

      approvedBy: json['approvedBy']?.toString() ?? '',

      appliedAt: _parseDate(json['appliedAt']),

      actionedAt: _parseDate(json['actionedAt']),

      createdAt: _parseDate(json['createdAt']),

      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  /// Returns a copy of this leave with a resolved employee name attached
  /// (looked up separately from GET /employees).
  LeaveModel copyWithResolvedName(String? name) {
    return LeaveModel(
      id: id,
      employee: employee,
      employeeIdRaw: employeeIdRaw,
      companyId: companyId,
      leaveType: leaveType,
      isPaid: isPaid,
      startDate: startDate,
      endDate: endDate,
      totalDays: totalDays,
      isHalfDay: isHalfDay,
      reason: reason,
      status: status,
      approvedBy: approvedBy,
      appliedAt: appliedAt,
      actionedAt: actionedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      resolvedEmployeeName: name,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String get employeeCode {
    if (employee == null || employee!.employeeCode.trim().isEmpty) {
      return '—';
    }

    return employee!.employeeCode;
  }

  String get employeeName {
    if (resolvedEmployeeName != null &&
        resolvedEmployeeName!.trim().isNotEmpty) {
      return resolvedEmployeeName!;
    }

    if (employee == null || employee!.name.trim().isEmpty) {
      return '—';
    }

    return employee!.name;
  }

  /// Best available display label for the employee:
  /// prefers the resolved name (from GET /employees), then the
  /// employeeId object's own name field (if ever present), then
  /// falls back to the employee code.
  String get employeeDisplayLabel {
    if (resolvedEmployeeName != null &&
        resolvedEmployeeName!.trim().isNotEmpty) {
      return resolvedEmployeeName!;
    }

    if (employee != null && employee!.name.trim().isNotEmpty) {
      return employee!.name;
    }

    return employeeCode;
  }

  bool get isPending => status == 'pending';

  bool get isApproved => status == 'approved';

  bool get isRejected => status == 'rejected';

  bool get isCancelled => status == 'cancelled';
}
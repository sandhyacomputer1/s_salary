class EmpLeaveModel {
  final String id;
  final String employeeId;
  final String companyId;
  final String leaveType;
  final bool isPaid;
  final DateTime? startDate;
  final DateTime? endDate;
  final double totalDays;
  final bool isHalfDay;
  final String reason;
  final String status;
  final DateTime? appliedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? actionedAt;
  final String? approvedBy;

  const EmpLeaveModel({
    required this.id,
    required this.employeeId,
    required this.companyId,
    required this.leaveType,
    required this.isPaid,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.isHalfDay,
    required this.reason,
    required this.status,
    required this.appliedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.actionedAt,
    required this.approvedBy,
  });

  factory EmpLeaveModel.fromJson(Map<String, dynamic> json) {
    return EmpLeaveModel(
      id: json['_id']?.toString() ?? '',
      employeeId: _idOf(json['employeeId']),
      companyId: _idOf(json['companyId']),
      leaveType: json['leaveType']?.toString() ?? '',
      isPaid: json['isPaid'] == true,
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      totalDays: _toDouble(json['totalDays']),
      isHalfDay: json['isHalfDay'] == true,
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString().toLowerCase() ?? '',
      appliedAt: _parseDate(json['appliedAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      actionedAt: _parseDate(json['actionedAt']),
      approvedBy: json['approvedBy']?.toString(),
    );
  }

  static String _idOf(dynamic value) {
    if (value is Map) return value['_id']?.toString() ?? '';
    return value?.toString() ?? '';
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

  /// "Applied on" falls back to createdAt if appliedAt is missing.
  DateTime? get appliedOn => appliedAt ?? createdAt;
}

/// The request the form hands to the service.
class EmpLeaveRequest {
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final bool isHalfDay;

  const EmpLeaveRequest({
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.isHalfDay,
  });

  /// Documented payload: { leaveType, startDate, endDate, reason }.
  /// "isHalfDay" is only added for half-day requests (field name taken from
  /// the leave history records — not confirmed for the apply endpoint).
  Map<String, dynamic> toJson() {
    return {
      'leaveType': leaveType,
      'startDate': EmpLeaveFormat.api(startDate),
      'endDate': EmpLeaveFormat.api(endDate),
      'reason': reason,
      if (isHalfDay) 'isHalfDay': true,
    };
  }
}

/// Date formatting for the leave module.
class EmpLeaveFormat {
  EmpLeaveFormat._();

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// Leave period dates arrive as UTC-midnight ISO strings. Read the UTC
  /// fields so the calendar day never shifts with the device time zone.
  static String period(DateTime? date) {
    if (date == null) return '—';
    final d = date.toUtc();
    return '${_two(d.day)} ${_months[d.month - 1]} ${d.year}';
  }

  static bool samePeriodDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    final x = a.toUtc();
    final y = b.toUtc();
    return x.year == y.year && x.month == y.month && x.day == y.day;
  }

  /// "Applied on" is a real timestamp, so convert it to local time.
  static String appliedOn(DateTime? date) {
    if (date == null) return '—';
    final d = date.toLocal();
    return '${_two(d.day)} ${_months[d.month - 1]} ${d.year}';
  }

  /// Form display format: DD-MM-YYYY.
  static String input(DateTime date) =>
      '${_two(date.day)}-${_two(date.month)}-${date.year}';

  /// API date-only format: YYYY-MM-DD.
  static String api(DateTime date) =>
      '${date.year}-${_two(date.month)}-${_two(date.day)}';
}
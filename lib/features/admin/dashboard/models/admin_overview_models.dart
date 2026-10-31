String _s(dynamic v) => v == null ? '' : v.toString();
double _d(dynamic v) => double.tryParse('$v') ?? 0;
DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

/// Id of an employee reference that may be a plain id or a populated object.
String _refId(dynamic ref) {
  if (ref is Map) return _s(ref['_id']);
  return _s(ref);
}

/// Name of a populated employee reference (employee.name or employee.userId.name).
String _refName(dynamic ref) {
  if (ref is! Map) return '';
  final user = ref['userId'];
  if (user is Map && _s(user['name']).isNotEmpty) return _s(user['name']);
  return _s(ref['name'] ?? ref['employeeName']);
}

/// One pending leave request (GET /leaves?status=pending).
class AdminPendingLeave {
  final String id;
  final String employeeId;
  final String employeeName; // may be empty -> look it up in the employee list
  final String leaveType;
  final DateTime? startDate;
  final DateTime? endDate;
  final double totalDays;

  const AdminPendingLeave({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.leaveType,
    this.startDate,
    this.endDate,
    required this.totalDays,
  });

  factory AdminPendingLeave.fromJson(Map<String, dynamic> j) => AdminPendingLeave(
    id: _s(j['_id']),
    employeeId: _refId(j['employeeId']),
    employeeName: _refName(j['employeeId']).isNotEmpty
        ? _refName(j['employeeId'])
        : _s(j['employeeName']),
    leaveType: _s(j['leaveType']),
    startDate: _dt(j['startDate']),
    endDate: _dt(j['endDate']),
    totalDays: _d(j['totalDays']),
  );
}

/// One pending expense claim (GET /expenses?status=pending).
class AdminPendingExpense {
  final String id;
  final String employeeId;
  final String employeeName;
  final String category;
  final double amount;
  final DateTime? expenseDate;

  const AdminPendingExpense({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.category,
    required this.amount,
    this.expenseDate,
  });

  factory AdminPendingExpense.fromJson(Map<String, dynamic> j) => AdminPendingExpense(
    id: _s(j['_id']),
    employeeId: _refId(j['employeeId']),
    employeeName: _refName(j['employeeId']).isNotEmpty
        ? _refName(j['employeeId'])
        : _s(j['employeeName']),
    category: _s(j['category']),
    amount: _d(j['amount']),
    expenseDate: _dt(j['expenseDate']),
  );
}

DateTime? _timeOf(dynamic v) {
  if (v is Map) return _dt(v['time']);
  return _dt(v);
}

/// One employee's attendance for a day
/// (GET /attendance/company/:companyId/today?date=YYYY-MM-DD).
class AdminDailyAttendance {
  final String employeeId;
  final String employeeName;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String status;
  final bool isLate;
  final double? totalHours;

  const AdminDailyAttendance({
    required this.employeeId,
    required this.employeeName,
    this.checkIn,
    this.checkOut,
    this.status = '',
    this.isLate = false,
    this.totalHours,
  });

  /// Accepts a flat attendance document (employeeId populated or not) or
  /// a wrapper like { employee: {...}, attendance: {...} }.
  factory AdminDailyAttendance.fromJson(Map<String, dynamic> j) {
    final att = j['attendance'] is Map ? Map<String, dynamic>.from(j['attendance'] as Map) : j;
    final emp = j['employee'] ?? att['employeeId'] ?? j['employeeId'];

    return AdminDailyAttendance(
      employeeId: _refId(emp),
      employeeName: _refName(emp).isNotEmpty ? _refName(emp) : _s(j['name']),
      checkIn: _timeOf(att['checkIn']),
      checkOut: _timeOf(att['checkOut']),
      status: _s(att['status']),
      isLate: att['isLate'] == true,
      totalHours: att['totalHours'] == null ? null : _d(att['totalHours']),
    );
  }
}
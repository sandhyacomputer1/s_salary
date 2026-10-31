// Models used by the Employee Profile screen tabs.

double _d(dynamic v) => double.tryParse('$v') ?? 0;
int _i(dynamic v) => v is num ? v.toInt() : (int.tryParse('$v') ?? 0);
String _s(dynamic v) => v == null ? '' : v.toString();
DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());
/// "2026-10-01" (or an ISO string) -> UTC midnight of that calendar day.
/// Avoids the one-day shift a local-time parse causes in IST.
DateTime? _dateOnly(dynamic v) {
  final s = _s(v);
  if (s.length < 10) return _dt(v);
  final y = int.tryParse(s.substring(0, 4));
  final m = int.tryParse(s.substring(5, 7));
  final d = int.tryParse(s.substring(8, 10));
  if (y == null || m == null || d == null) return _dt(v);
  return DateTime.utc(y, m, d);
}

Map<String, dynamic> _m(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

/// Company name / timezone / last login shown in "Account & Company Info".
class AdminProfileExtra {
  final String companyName;
  final String timezone;
  final DateTime? lastLogin;

  const AdminProfileExtra({
    this.companyName = '',
    this.timezone = '',
    this.lastLogin,
  });

  AdminProfileExtra copyWith({String? companyName, String? timezone, DateTime? lastLogin}) =>
      AdminProfileExtra(
        companyName: companyName ?? this.companyName,
        timezone: timezone ?? this.timezone,
        lastLogin: lastLogin ?? this.lastLogin,
      );
}

/// GET /attendance/employee/:id/summary
class AdminAttendanceSummary {
  final int present;
  final int absent;
  final int halfDay;
  final int late;
  final int onLeave;
  final double totalHours;
  final double avgHours;

  const AdminAttendanceSummary({
    this.present = 0,
    this.absent = 0,
    this.halfDay = 0,
    this.late = 0,
    this.onLeave = 0,
    this.totalHours = 0,
    this.avgHours = 0,
  });

  factory AdminAttendanceSummary.fromJson(dynamic json) {
    final j = _m(json);
    return AdminAttendanceSummary(
      present: _i(j['present']),
      absent: _i(j['absent']),
      halfDay: _i(j['half_day'] ?? j['halfDay']),
      late: _i(j['late']),
      onLeave: _i(j['on_leave'] ?? j['onLeave']),
      totalHours: _d(j['totalHours']),
      avgHours: _d(j['avgHours']),
    );
  }

  /// "late" is a flag on a present day, so it is not added again.
  /// Nothing recorded yet -> 100% (same as the web).
  double get attendanceRate {
    final total = present + halfDay + absent;
    if (total == 0) return 100;
    return (present + halfDay * 0.5) * 100 / total;
  }
}

/// One day of GET /attendance/employee/:id
class AdminAttendanceLog {
  /// "2026-10-01"
  final String dateKey;
  final DateTime? date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String status;
  final bool isLate;
  final int lateByMinutes;
  final double? totalHours;

  /// true when an admin marked the day by hand (no real check-in).
  final bool markedByAdmin;

  const AdminAttendanceLog({
    this.dateKey = '',
    this.date,
    this.checkIn,
    this.checkOut,
    this.status = '',
    this.isLate = false,
    this.lateByMinutes = 0,
    this.totalHours,
    this.markedByAdmin = false,
  });

  factory AdminAttendanceLog.fromJson(Map<String, dynamic> j) {
    final inMap = _m(j['checkIn']);
    final outMap = _m(j['checkOut']);
    final raw = _s(j['date']);
    final status = _s(j['status']).toLowerCase();
    final inTime = _dt(inMap['time']);

    final explicit = j['markedByAdmin'] == true ||
        j['isManual'] == true ||
        j['manual'] == true ||
        j['isManuallyMarked'] == true ||
        j['markedBy'] != null;

    // no real check-in on a present / late / half-day record = marked by hand
    final inferred =
        inTime == null && (status == 'present' || status == 'late' || status == 'half_day');

    return AdminAttendanceLog(
      dateKey: raw.length >= 10 ? raw.substring(0, 10) : raw,
      date: _dateOnly(raw),
      checkIn: inTime,
      checkOut: _dt(outMap['time']),
      status: _s(j['status']),
      isLate: j['isLate'] == true,
      lateByMinutes: _i(j['lateByMinutes']),
      totalHours: j['totalHours'] == null ? null : _d(j['totalHours']),
      markedByAdmin: explicit || inferred,
    );
  }
}

/// A holiday or week-off from the company calendar.
class AdminCalendarDay {
  final String dateKey; // yyyy-MM-dd
  final String type; // holiday | week_off
  final String name;

  const AdminCalendarDay({required this.dateKey, required this.type, required this.name});

  factory AdminCalendarDay.fromJson(Map<String, dynamic> j) {
    final raw = _s(j['date']);
    return AdminCalendarDay(
      dateKey: raw.length >= 10 ? raw.substring(0, 10) : raw,
      type: _s(j['type']).isEmpty ? 'holiday' : _s(j['type']),
      name: _s(j['name'] ?? j['title'] ?? j['description']),
    );
  }
}

class AdminLeaveBalance {
  final String leaveType;
  final double allotted;
  final double used;
  final double remaining;

  const AdminLeaveBalance({
    required this.leaveType,
    required this.allotted,
    required this.used,
    required this.remaining,
  });

  factory AdminLeaveBalance.fromJson(Map<String, dynamic> j) => AdminLeaveBalance(
    leaveType: _s(j['leaveType']),
    allotted: _d(j['allotted']),
    used: _d(j['used']),
    remaining: _d(j['remaining']),
  );
}

class AdminLeaveRequest {
  final String id;
  final String leaveType;
  final DateTime? startDate;
  final DateTime? endDate;
  final double totalDays;
  final bool isHalfDay;
  final String status;
  final String reason;

  const AdminLeaveRequest({
    required this.id,
    required this.leaveType,
    this.startDate,
    this.endDate,
    required this.totalDays,
    required this.isHalfDay,
    required this.status,
    required this.reason,
  });

  bool get isPending => status.toLowerCase() == 'pending';

  factory AdminLeaveRequest.fromJson(Map<String, dynamic> j) => AdminLeaveRequest(
    id: _s(j['_id']),
    leaveType: _s(j['leaveType']),
    startDate: _dt(j['startDate']),
    endDate: _dt(j['endDate']),
    totalDays: _d(j['totalDays']),
    isHalfDay: j['isHalfDay'] == true,
    status: _s(j['status']),
    reason: _s(j['reason']),
  );
}

class AdminSalarySlip {
  final int month;
  final int year;
  final double baseSalary;
  final double grossSalary;
  final double netSalary;
  final int presentDays;
  final String status;

  const AdminSalarySlip({
    required this.month,
    required this.year,
    required this.baseSalary,
    required this.grossSalary,
    required this.netSalary,
    required this.presentDays,
    required this.status,
  });

  factory AdminSalarySlip.fromJson(Map<String, dynamic> j) => AdminSalarySlip(
    month: _i(j['month']),
    year: _i(j['year']),
    baseSalary: _d(j['baseSalary']),
    grossSalary: _d(j['grossSalary']),
    netSalary: _d(j['netSalary']),
    presentDays: _i(j['presentDays']),
    status: _s(j['status']),
  );
}

class AdminExpenseItem {
  final String id;
  final String category;
  final double amount;
  final DateTime? expenseDate;
  final String description;
  final String status;

  const AdminExpenseItem({
    required this.id,
    required this.category,
    required this.amount,
    this.expenseDate,
    required this.description,
    required this.status,
  });

  bool get isPending => status.toLowerCase() == 'pending';

  factory AdminExpenseItem.fromJson(Map<String, dynamic> j) => AdminExpenseItem(
    id: _s(j['_id']),
    category: _s(j['category']),
    amount: _d(j['amount']),
    expenseDate: _dt(j['expenseDate']),
    description: _s(j['description']),
    status: _s(j['status']),
  );
}
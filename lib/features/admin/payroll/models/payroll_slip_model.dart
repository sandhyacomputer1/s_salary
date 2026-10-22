double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

String _text(dynamic v) => v?.toString().trim() ?? '';

/// A plain value, or the "name" of a populated object (e.g. a department).
String _label(dynamic v) {
  if (v is Map) return _text(v['name'] ?? v['title']);
  return _text(v);
}

String _first(List<dynamic> values) {
  for (final value in values) {
    final text = _label(value);
    if (text.isNotEmpty) return text;
  }
  return '';
}

Map<String, dynamic> _asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

/// Payroll status flow (documented): draft -> generated -> approved -> paid.
class PayrollStatus {
  PayrollStatus._();

  static const String draft = 'draft';
  static const String generated = 'generated';
  static const String approved = 'approved';
  static const String paid = 'paid';

  static String label(String status) {
    switch (status.trim().toLowerCase()) {
      case draft:
        return 'Draft';
      case generated:
        return 'Generated';
      case approved:
        return 'Approved';
      case paid:
        return 'Paid';
      default:
        return status.isEmpty ? '-' : status;
    }
  }
}

/// One entry of Payroll.deductions[] (salary-rule deductions).
class PayrollDeduction {
  final String ruleName;
  final double amount;
  final String reason;

  const PayrollDeduction({
    required this.ruleName,
    required this.amount,
    required this.reason,
  });

  factory PayrollDeduction.fromJson(Map<String, dynamic> json) =>
      PayrollDeduction(
        ruleName: _text(json['ruleName']),
        amount: _toDouble(json['amount']),
        reason: _text(json['reason']),
      );
}

/// One payslip. Documented fields (ANDROID_API_REFERENCE, "Payroll object"):
/// month, year, daysInMonth, workingDays, presentDays, absentDays, halfDays,
/// lateDays, leaveDays, paidLeaveDays, unpaidLeaveDays, unpaidLeaveCount,
/// payableDays, holidays, weekOffs, baseSalary, allowancesTotal,
/// expenseReimbursement, absenceDeductionAmount, lateDeductionAmount,
/// ptDeduction, pfDeduction, deductions[], grossSalary, netSalary, status,
/// emailSentStatus.
///
/// NOT documented: how the payroll list identifies the employee. The id, name,
/// code, department and designation are read from every likely place (a
/// populated employeeId object, its user, or flat keys). When the response
/// does not carry them, the screen fills them in with [withIdentity].
class PayrollSlip {
  final String id;
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String department;
  final String designation;

  final int month;
  final int year;

  final int daysInMonth;
  final int workingDays;
  final int presentDays;
  final int absentDays;
  final int halfDays;
  final int lateDays;
  final int leaveDays;
  final int paidLeaveDays;
  final int unpaidLeaveDays;
  final int payableDays;
  final int holidays;
  final int weekOffs;

  final double baseSalary;
  final double allowancesTotal;
  final double expenseReimbursement;

  final double absenceDeduction;
  final double lateDeduction;
  final double ptDeduction;
  final double pfDeduction;
  final List<PayrollDeduction> ruleDeductions;

  final double grossSalary;
  final double netSalary;

  final String status;
  final String emailStatus; // pending | sent | failed

  const PayrollSlip({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.department,
    required this.designation,
    required this.month,
    required this.year,
    required this.daysInMonth,
    required this.workingDays,
    required this.presentDays,
    required this.absentDays,
    required this.halfDays,
    required this.lateDays,
    required this.leaveDays,
    required this.paidLeaveDays,
    required this.unpaidLeaveDays,
    required this.payableDays,
    required this.holidays,
    required this.weekOffs,
    required this.baseSalary,
    required this.allowancesTotal,
    required this.expenseReimbursement,
    required this.absenceDeduction,
    required this.lateDeduction,
    required this.ptDeduction,
    required this.pfDeduction,
    required this.ruleDeductions,
    required this.grossSalary,
    required this.netSalary,
    required this.status,
    required this.emailStatus,
  });

  bool get isPaid => status.trim().toLowerCase() == PayrollStatus.paid;

  /// Sum of the salary-rule deductions (the 5th component).
  double get ruleDeductionsTotal =>
      ruleDeductions.fold<double>(0, (sum, d) => sum + d.amount);

  /// All five deduction components, as the API reference requires.
  double get totalDeductions =>
      absenceDeduction +
      lateDeduction +
      ptDeduction +
      pfDeduction +
      ruleDeductionsTotal;

  /// Documented formula: gross - deductions, clamped at 0.
  double get computedNet {
    final value = grossSalary - totalDeductions;
    return value < 0 ? 0 : value;
  }

  /// True when the server's net pay equals the documented formula (within
  /// half a rupee). When false the UI can warn instead of hiding it.
  bool get netReconciles => (computedNet - netSalary).abs() < 0.5;

  String get initials {
    final clean = employeeName.trim();
    if (clean.isEmpty) return '?';

    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();

    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// A copy with the employee's name / code / department / designation filled
  /// in. Empty or null values keep what the slip already has.
  PayrollSlip withIdentity({
    String? name,
    String? code,
    String? department,
    String? designation,
  }) {
    String pick(String? incoming, String current) =>
        (incoming != null && incoming.trim().isNotEmpty)
        ? incoming.trim()
        : current;

    return PayrollSlip(
      id: id,
      employeeId: employeeId,
      employeeName: pick(name, employeeName),
      employeeCode: pick(code, employeeCode),
      department: pick(department, this.department),
      designation: pick(designation, this.designation),
      month: month,
      year: year,
      daysInMonth: daysInMonth,
      workingDays: workingDays,
      presentDays: presentDays,
      absentDays: absentDays,
      halfDays: halfDays,
      lateDays: lateDays,
      leaveDays: leaveDays,
      paidLeaveDays: paidLeaveDays,
      unpaidLeaveDays: unpaidLeaveDays,
      payableDays: payableDays,
      holidays: holidays,
      weekOffs: weekOffs,
      baseSalary: baseSalary,
      allowancesTotal: allowancesTotal,
      expenseReimbursement: expenseReimbursement,
      absenceDeduction: absenceDeduction,
      lateDeduction: lateDeduction,
      ptDeduction: ptDeduction,
      pfDeduction: pfDeduction,
      ruleDeductions: ruleDeductions,
      grossSalary: grossSalary,
      netSalary: netSalary,
      status: status,
      emailStatus: emailStatus,
    );
  }

  factory PayrollSlip.fromJson(Map<String, dynamic> json) {
    final rawEmployee = json['employeeId'];
    final employee = _asMap(rawEmployee);
    final user = _asMap(
      employee['userId'] ?? employee['user'] ?? json['user'] ?? json['userId'],
    );

    final deductions = json['deductions'] is List
        ? (json['deductions'] as List)
              .whereType<Map>()
              .map(
                (e) => PayrollDeduction.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : <PayrollDeduction>[];

    return PayrollSlip(
      id: _text(json['_id'] ?? json['id']),
      employeeId: _text(
        employee['_id'] ?? (rawEmployee is String ? rawEmployee : null),
      ),
      employeeName: _first([
        json['employeeName'],
        employee['name'],
        employee['fullName'],
        user['name'],
        json['name'],
      ]),
      employeeCode: _first([employee['employeeCode'], json['employeeCode']]),
      department: _first([employee['department'], json['department']]),
      designation: _first([employee['designation'], json['designation']]),
      month: _toInt(json['month']),
      year: _toInt(json['year']),
      daysInMonth: _toInt(json['daysInMonth']),
      workingDays: _toInt(json['workingDays']),
      presentDays: _toInt(json['presentDays']),
      absentDays: _toInt(json['absentDays']),
      halfDays: _toInt(json['halfDays']),
      lateDays: _toInt(json['lateDays']),
      leaveDays: _toInt(json['leaveDays']),
      paidLeaveDays: _toInt(json['paidLeaveDays']),
      unpaidLeaveDays: _toInt(json['unpaidLeaveDays']),
      payableDays: _toInt(json['payableDays']),
      holidays: _toInt(json['holidays']),
      weekOffs: _toInt(json['weekOffs']),
      baseSalary: _toDouble(json['baseSalary']),
      allowancesTotal: _toDouble(json['allowancesTotal']),
      expenseReimbursement: _toDouble(json['expenseReimbursement']),
      absenceDeduction: _toDouble(json['absenceDeductionAmount']),
      lateDeduction: _toDouble(json['lateDeductionAmount']),
      ptDeduction: _toDouble(json['ptDeduction']),
      pfDeduction: _toDouble(json['pfDeduction']),
      ruleDeductions: deductions,
      grossSalary: _toDouble(json['grossSalary']),
      netSalary: _toDouble(json['netSalary']),
      status: _text(json['status']),
      emailStatus: _text(json['emailSentStatus']),
    );
  }

  /// A bare array (documented for POST /salary/generate), or an object that
  /// holds the array (the company payroll list shape is not documented).
  static List<PayrollSlip> listFromResponse(dynamic body) {
    dynamic list = body;

    if (body is Map) {
      list = body['payrolls'] ?? body['slips'] ?? body['data'];
    }

    if (list is! List) return const [];

    return list
        .whereType<Map>()
        .map((e) => PayrollSlip.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

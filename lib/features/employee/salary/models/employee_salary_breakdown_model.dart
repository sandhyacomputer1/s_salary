// lib/features/employee/salary/models/employee_salary_breakdown_model.dart

class EmployeeSalaryBreakdownModel {
  final String id;
  final int month;
  final int year;
  final String status;

  // Attendance
  final int presentDays;
  final int absentDays;
  final int halfDays;
  final int lateDays;
  final int leaveDays;
  final int paidLeaveDays;
  final int unpaidLeaveDays;
  final int unpaidLeaveCount;
  final int payableDays;
  final int workingDays;
  final int daysInMonth;
  final int holidays;
  final int weekOffs;

  // Earnings
  final double baseSalary;
  final double allowancesTotal;
  final double expenseReimbursement;
  final double grossSalary;

  // Deductions
  final double absenceDeductionAmount;
  final double lateDeductionAmount;
  final double ptDeduction;
  final double pfDeduction;
  final List<SalaryDeductionLine> deductions;

  // Net
  final double netSalary;

  const EmployeeSalaryBreakdownModel({
    required this.id,
    required this.month,
    required this.year,
    required this.status,
    required this.presentDays,
    required this.absentDays,
    required this.halfDays,
    required this.lateDays,
    required this.leaveDays,
    required this.paidLeaveDays,
    required this.unpaidLeaveDays,
    required this.unpaidLeaveCount,
    required this.payableDays,
    required this.workingDays,
    required this.daysInMonth,
    required this.holidays,
    required this.weekOffs,
    required this.baseSalary,
    required this.allowancesTotal,
    required this.expenseReimbursement,
    required this.grossSalary,
    required this.absenceDeductionAmount,
    required this.lateDeductionAmount,
    required this.ptDeduction,
    required this.pfDeduction,
    required this.deductions,
    required this.netSalary,
  });

  /// Matches the documented formula:
  /// net = gross - (absence + late + pt + pf + Σ deductions[].amount)
  double get totalDeductions =>
      absenceDeductionAmount +
      lateDeductionAmount +
      ptDeduction +
      pfDeduction +
      deductions.fold<double>(0, (s, d) => s + d.amount);

  factory EmployeeSalaryBreakdownModel.fromJson(Map<String, dynamic> j) {
    final rawDeductions = j['deductions'];
    final list = <SalaryDeductionLine>[];
    if (rawDeductions is List) {
      for (final d in rawDeductions) {
        if (d is Map) {
          list.add(SalaryDeductionLine.fromJson(Map<String, dynamic>.from(d)));
        }
      }
    }

    return EmployeeSalaryBreakdownModel(
      id: (j['_id'] ?? '').toString(),
      month: _toInt(j['month']),
      year: _toInt(j['year']),
      status: (j['status'] ?? '').toString().toLowerCase(),
      presentDays: _toInt(j['presentDays']),
      absentDays: _toInt(j['absentDays']),
      halfDays: _toInt(j['halfDays']),
      lateDays: _toInt(j['lateDays']),
      leaveDays: _toInt(j['leaveDays']),
      paidLeaveDays: _toInt(j['paidLeaveDays']),
      unpaidLeaveDays: _toInt(j['unpaidLeaveDays']),
      unpaidLeaveCount: _toInt(j['unpaidLeaveCount']),
      payableDays: _toInt(j['payableDays']),
      workingDays: _toInt(j['workingDays']),
      daysInMonth: _toInt(j['daysInMonth']),
      holidays: _toInt(j['holidays']),
      weekOffs: _toInt(j['weekOffs']),
      baseSalary: _toDouble(j['baseSalary']),
      allowancesTotal: _toDouble(j['allowancesTotal']),
      expenseReimbursement: _toDouble(j['expenseReimbursement']),
      grossSalary: _toDouble(j['grossSalary']),
      absenceDeductionAmount: _toDouble(j['absenceDeductionAmount']),
      lateDeductionAmount: _toDouble(j['lateDeductionAmount']),
      ptDeduction: _toDouble(j['ptDeduction']),
      pfDeduction: _toDouble(j['pfDeduction']),
      deductions: list,
      netSalary: _toDouble(j['netSalary']),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

class SalaryDeductionLine {
  final String ruleName;
  final double amount;
  final String reason;

  const SalaryDeductionLine({
    required this.ruleName,
    required this.amount,
    required this.reason,
  });

  factory SalaryDeductionLine.fromJson(Map<String, dynamic> j) {
    return SalaryDeductionLine(
      ruleName: (j['ruleName'] ?? '').toString(),
      amount: EmployeeSalaryBreakdownModel._toDouble(j['amount']),
      reason: (j['reason'] ?? '').toString(),
    );
  }
}

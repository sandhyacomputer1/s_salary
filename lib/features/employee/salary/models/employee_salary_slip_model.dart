// lib/features/employee/salary/models/employee_salary_slip_model.dart

class EmployeeSalarySlipModel {
  final String id;
  final int month; // 1-12
  final int year;
  final String status; // draft | generated | approved | paid

  final double grossSalary;
  final double totalDeductions;
  final double netSalary;

  const EmployeeSalarySlipModel({
    required this.id,
    required this.month,
    required this.year,
    required this.status,
    required this.grossSalary,
    required this.totalDeductions,
    required this.netSalary,
  });

  factory EmployeeSalarySlipModel.fromJson(Map<String, dynamic> j) {
    final gross = _toDouble(j['grossSalary']);
    final net = _toDouble(j['netSalary']);

    final explicitTotal =
        _toDoubleOrNull(j['totalDeductions']) ??
        _toDoubleOrNull(j['totalDeductionAmount']);

    final summed =
        _toDouble(j['absenceDeductionAmount']) +
        _toDouble(j['lateDeductionAmount']) +
        _toDouble(j['ptDeduction']) +
        _toDouble(j['pfDeduction']) +
        _sumDeductionsArray(j['deductions']);

    final total = explicitTotal ?? summed;

    return EmployeeSalarySlipModel(
      id: (j['_id'] ?? '').toString(),
      month: _toInt(j['month']),
      year: _toInt(j['year']),
      status: (j['status'] ?? '').toString().toLowerCase(),
      grossSalary: gross,
      totalDeductions: total,
      netSalary: net,
    );
  }

  static double _sumDeductionsArray(dynamic raw) {
    if (raw is! List) return 0;
    double sum = 0;
    for (final d in raw) {
      if (d is Map) sum += _toDouble(d['amount']);
    }
    return sum;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}

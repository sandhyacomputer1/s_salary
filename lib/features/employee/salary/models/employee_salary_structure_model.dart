// lib/features/employee/salary/models/employee_salary_structure_model.dart

class EmployeeSalaryStructureModel {
  final double baseSalary;
  final String effectiveFrom; // "YYYY-MM-DD" or ISO
  final List<SalaryAllowance> allowances;

  const EmployeeSalaryStructureModel({
    required this.baseSalary,
    required this.effectiveFrom,
    required this.allowances,
  });

  factory EmployeeSalaryStructureModel.fromJson(Map<String, dynamic> j) {
    final rawAllowances = j['allowances'];
    final list = <SalaryAllowance>[];
    if (rawAllowances is List) {
      for (final a in rawAllowances) {
        if (a is Map) {
          list.add(SalaryAllowance.fromJson(Map<String, dynamic>.from(a)));
        }
      }
    }

    return EmployeeSalaryStructureModel(
      baseSalary: _toDouble(j['baseSalary']),
      effectiveFrom: (j['effectiveFrom'] ?? '').toString(),
      allowances: list,
    );
  }

  double get allowancesTotal =>
      allowances.fold<double>(0, (sum, a) => sum + a.amount);

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class SalaryAllowance {
  final String name;
  final double amount;

  const SalaryAllowance({required this.name, required this.amount});

  factory SalaryAllowance.fromJson(Map<String, dynamic> j) {
    return SalaryAllowance(
      name: (j['name'] ?? '').toString(),
      amount: EmployeeSalaryStructureModel._toDouble(j['amount']),
    );
  }
}

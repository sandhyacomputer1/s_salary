/// One allowance line (e.g. HRA = 5000).
class AdminAllowance {
  final String name;
  final double amount;
  const AdminAllowance({required this.name, required this.amount});

  factory AdminAllowance.fromJson(Map<String, dynamic> j) => AdminAllowance(
    name: j['name']?.toString() ?? '',
    amount: double.tryParse('${j['amount']}') ?? 0,
  );

  Map<String, dynamic> toJson() => {'name': name.trim(), 'amount': amount};
}

/// Salary structure of one employee (GET / POST /salary/structure/:employeeId).
class AdminSalaryStructure {
  final double baseSalary;
  final DateTime effectiveFrom;
  final List<AdminAllowance> allowances;

  const AdminSalaryStructure({
    required this.baseSalary,
    required this.effectiveFrom,
    this.allowances = const [],
  });

  double get allowancesTotal =>
      allowances.fold<double>(0, (sum, a) => sum + a.amount);

  double get gross => baseSalary + allowancesTotal;

  /// Accepts the object itself or one wrapped in {structure|data: {...}}.
  static AdminSalaryStructure? fromResponse(dynamic res) {
    if (res is! Map) return null;
    var map = Map<String, dynamic>.from(res);
    for (final k in ['structure', 'data']) {
      if (map[k] is Map) {
        map = Map<String, dynamic>.from(map[k] as Map);
        break;
      }
    }

    final base = double.tryParse('${map['baseSalary']}');
    if (base == null) return null;

    final allowances = map['allowances'] is List
        ? (map['allowances'] as List)
        .whereType<Map>()
        .map((e) => AdminAllowance.fromJson(Map<String, dynamic>.from(e)))
        .toList()
        : <AdminAllowance>[];

    return AdminSalaryStructure(
      baseSalary: base,
      effectiveFrom: DateTime.tryParse('${map['effectiveFrom']}') ?? DateTime.now(),
      allowances: allowances,
    );
  }

  Map<String, dynamic> toJson() {
    String two(int n) => n.toString().padLeft(2, '0');
    final d = effectiveFrom;
    return {
      'baseSalary': baseSalary,
      'effectiveFrom': '${d.year}-${two(d.month)}-${two(d.day)}',
      'allowances': allowances.map((a) => a.toJson()).toList(),
    };
  }
}
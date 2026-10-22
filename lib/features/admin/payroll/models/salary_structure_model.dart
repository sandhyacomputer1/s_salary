double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

String _text(dynamic v) => v?.toString().trim() ?? '';

Map<String, dynamic> _asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

/// One allowance line of a salary structure ({ name, amount }).
class SalaryAllowance {
  SalaryAllowance({required this.name, required this.amount});

  String name;
  double amount;

  factory SalaryAllowance.fromJson(Map<String, dynamic> json) =>
      SalaryAllowance(
        name: _text(json['name']),
        amount: _toDouble(json['amount']),
      );

  SalaryAllowance copy() => SalaryAllowance(name: name, amount: amount);
}

/// An employee's salary structure.
///
/// Documented shape (GET /salary/structure/:employeeId):
///   { "baseSalary": 30000, "effectiveFrom": "2025-01-01T00:00:00.000Z",
///     "allowances": [ { "name": "HRA", "amount": 5000 } ] }
///
/// NOT documented: how GET /salary/structure/by-company/:companyId labels the
/// employee. The id is read from `employeeId` (string or populated object) or
/// `_id`; the name from a populated employee, if present.
class SalaryStructure {
  SalaryStructure({
    required this.employeeId,
    required this.employeeName,
    required this.baseSalary,
    required this.effectiveFrom,
    required this.allowances,
  });

  final String employeeId;
  final String employeeName;
  double baseSalary;
  DateTime? effectiveFrom;
  List<SalaryAllowance> allowances;

  double get allowancesTotal =>
      allowances.fold<double>(0, (sum, a) => sum + a.amount);

  /// "Estimated Gross / month" in the Set Salary dialog.
  double get estimatedGross => baseSalary + allowancesTotal;

  factory SalaryStructure.fromJson(Map<String, dynamic> json) {
    final rawEmployee = json['employeeId'];
    final employee = _asMap(rawEmployee);

    final allowances = json['allowances'] is List
        ? (json['allowances'] as List)
              .whereType<Map>()
              .map(
                (e) => SalaryAllowance.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : <SalaryAllowance>[];

    return SalaryStructure(
      employeeId: _text(
        employee['_id'] ??
            (rawEmployee is String ? rawEmployee : null) ??
            json['_id'],
      ),
      employeeName: _text(employee['name'] ?? json['employeeName']),
      baseSalary: _toDouble(json['baseSalary']),
      effectiveFrom: DateTime.tryParse(_text(json['effectiveFrom'])),
      allowances: allowances,
    );
  }

  SalaryStructure copy() => SalaryStructure(
    employeeId: employeeId,
    employeeName: employeeName,
    baseSalary: baseSalary,
    effectiveFrom: effectiveFrom,
    allowances: allowances.map((a) => a.copy()).toList(),
  );

  /// A bare array, or an object that holds one.
  static List<SalaryStructure> listFromResponse(dynamic body) {
    dynamic list = body;

    if (body is Map) {
      list = body['structures'] ?? body['salaryStructures'] ?? body['data'];
    }

    if (list is! List) return const [];

    return list
        .whereType<Map>()
        .map((e) => SalaryStructure.fromJson(Map<String, dynamic>.from(e)))
        .where((s) => s.employeeId.isNotEmpty)
        .toList();
  }
}

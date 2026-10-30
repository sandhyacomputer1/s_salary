import '../models/admin_employee_model.dart';

/// Builds the same CSV the web app exports:
/// UTF-8 with BOM, every value quoted, dates as dd/MM/yyyy.
class AdminEmployeeCsvService {
  AdminEmployeeCsvService._();

  static const String _bom = '\uFEFF';

  static const List<String> _headers = [
    'Employee Code',
    'Name',
    'Email',
    'Phone',
    'Department',
    'Designation',
    'Joining Date',
    'Status',
    'Base Salary (₹)',
  ];

  /// "Employee_Directory_2026-10-30.csv"
  static String fileName([DateTime? now]) {
    final d = now ?? DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'Employee_Directory_${d.year}-${two(d.month)}-${two(d.day)}.csv';
  }

  static String build(List<AdminEmployeeModel> employees) {
    final lines = <String>[_headers.join(',')];

    for (final e in employees) {
      lines.add([
        e.employeeCode,
        e.name,
        e.email,
        e.phone,
        e.department,
        e.designation,
        _date(e.dateOfJoining),
        e.status,
        _salary(e.baseSalary),
      ].map(_cell).join(','));
    }

    return _bom + lines.join('\n');
  }

  static String _cell(String v) => '"${v.replaceAll('"', '""')}"';

  static String _date(DateTime? d) {
    if (d == null) return '';
    final u = d.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(u.day)}/${two(u.month)}/${u.year}';
  }

  static String _salary(double? v) {
    if (v == null) return '';
    return v == v.roundToDouble() ? v.round().toString() : v.toString();
  }
}
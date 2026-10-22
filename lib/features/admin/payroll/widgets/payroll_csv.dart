import '../models/payroll_slip_model.dart';
import 'payroll_format.dart';

/// Builds the "Export CSV" text from the payroll rows on screen.
class PayrollCsv {
  PayrollCsv._();

  static const List<String> _header = [
    'Employee',
    'Code',
    'Month',
    'Year',
    'Days in month',
    'Present days',
    'Paid leave days',
    'Late count',
    'Base salary',
    'Late penalty',
    'PT deduction',
    'PF deduction',
    'Rule deductions',
    'Gross salary',
    'Net payable',
    'Status',
    'Email status',
  ];

  static String build(List<PayrollSlip> slips) {
    final lines = <String>[_header.map(_cell).join(',')];

    for (final s in slips) {
      lines.add(
        [
          s.employeeName,
          s.employeeCode,
          PayrollFormat.monthName(s.month),
          s.year,
          s.daysInMonth,
          s.presentDays,
          s.paidLeaveDays,
          s.lateDays,
          s.baseSalary.toStringAsFixed(2),
          s.lateDeduction.toStringAsFixed(2),
          s.ptDeduction.toStringAsFixed(2),
          s.pfDeduction.toStringAsFixed(2),
          s.ruleDeductionsTotal.toStringAsFixed(2),
          s.grossSalary.toStringAsFixed(2),
          s.netSalary.toStringAsFixed(2),
          s.status,
          s.emailStatus,
        ].map(_cell).join(','),
      );
    }

    return lines.join('\n');
  }

  /// Quotes values that need it, and neutralises text that a spreadsheet
  /// would run as a formula (a leading = + - @ in a text cell).
  static String _cell(Object? value) {
    var text = '${value ?? ''}';

    if (value is String && RegExp(r'^[=+\-@]').hasMatch(text)) {
      text = "'$text";
    }

    if (text.contains(',') || text.contains('"') || text.contains('\n')) {
      text = '"${text.replaceAll('"', '""')}"';
    }

    return text;
  }
}

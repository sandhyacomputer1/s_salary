// !!! PARTLY UNVERIFIED REQUEST BODIES !!!
// ANDROID_API_REFERENCE documents these paths but not their bodies:
//   POST /salary/structure/:employeeId   (Set Salary dialog)
//   POST /salary/send-emails             (Email All Payslips)
//   POST /salary/pf/refund               (Refund Full PF)
// The structure body mirrors the documented GET response
// ({baseSalary, effectiveFrom, allowances[{name, amount}]}), so it is a
// reasonable guess; the e-mail and refund bodies are pure guesses.
//
// POST /salary/generate takes only ?month=&year= (documented), no body.
//
// This is the ONLY file that builds these bodies. If the backend rejects a
// key, its message is shown on screen; fix it here.

import 'salary_structure_model.dart';

/// Body of POST /salary/structure/:employeeId
class SalaryStructureRequest {
  const SalaryStructureRequest(this.structure);

  final SalaryStructure structure;

  /// YYYY-MM-DD (GUESS: the API may expect a full ISO timestamp).
  static String _date(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static num _num(double value) =>
      value == value.roundToDouble() ? value.toInt() : value;

  Map<String, dynamic> toJson() => {
    'baseSalary': _num(structure.baseSalary),
    if (structure.effectiveFrom != null)
      'effectiveFrom': _date(structure.effectiveFrom!),
    'allowances': structure.allowances
        .map((a) => {'name': a.name.trim(), 'amount': _num(a.amount)})
        .toList(),
  };
}

/// Body of POST /salary/send-emails (GUESS: month and year).
class SendPayslipEmailsRequest {
  const SendPayslipEmailsRequest({required this.month, required this.year});

  final int month;
  final int year;

  Map<String, dynamic> toJson() => {'month': month, 'year': year};
}

/// Body of POST /salary/pf/refund (GUESS: the employee id only; "full" means
/// the server refunds the whole pending balance, so no amount is sent).
class PfRefundRequest {
  const PfRefundRequest({required this.employeeId});

  final String employeeId;

  Map<String, dynamic> toJson() => {'employeeId': employeeId};
}

/// Validation for the Set Salary dialog. Returns a message or null.
class PayrollValidator {
  PayrollValidator._();

  static String? structure(SalaryStructure s) {
    if (s.baseSalary <= 0) {
      return 'Base salary must be greater than 0.';
    }
    if (s.effectiveFrom == null) {
      return 'Choose the date this salary takes effect.';
    }

    final seen = <String>{};
    for (final a in s.allowances) {
      final name = a.name.trim();

      if (name.isEmpty) return 'Every allowance needs a name.';
      if (a.amount < 0) return '"$name": amount cannot be negative.';
      if (!seen.add(name.toLowerCase())) {
        return 'Allowance "$name" is listed twice.';
      }
    }

    return null;
  }
}

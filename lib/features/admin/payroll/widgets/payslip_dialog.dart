import 'package:flutter/material.dart';

import '../models/payroll_slip_model.dart';
import 'payroll_format.dart';
import 'payslip_pdf.dart';

const Color _kPrimary = Color(0xFFE96832);
const Color _kTextDark = Color(0xFF18212F);
const Color _kMuted = Color(0xFF7A8494);
const Color _kRed = Color(0xFFDC2626);
const Color _kGreen = Color(0xFF16A34A);
const Color _kBorder = Color(0xFFE5E7EB);

/// "Salary Slip - October 2026", laid out like the web slip: employee box,
/// four attendance tiles, Earnings | Deductions table, net-pay banner.
///
/// All amounts are the server's. The only thing computed here is a check that
/// the net pay equals gross minus deductions; a mismatch is shown, not hidden.
class PayslipDialog extends StatefulWidget {
  const PayslipDialog({super.key, required this.slip});

  final PayrollSlip slip;

  static Future<void> show(BuildContext context, PayrollSlip slip) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: PayslipDialog(slip: slip),
        ),
      ),
    );
  }

  @override
  State<PayslipDialog> createState() => _PayslipDialogState();
}

class _PayslipDialogState extends State<PayslipDialog> {
  bool _printing = false;

  PayrollSlip get _s => widget.slip;

  Future<void> _download() async {
    if (_printing) return;

    setState(() => _printing = true);

    try {
      await PayslipPdf.open(_s);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not create the payslip PDF. Please try again.'),
          backgroundColor: _kRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _employeeBox(),
                const SizedBox(height: 14),
                _tiles(),
                const SizedBox(height: 14),
                _table(),
                const SizedBox(height: 14),
                _netBanner(),
                if (!_s.netReconciles) ...[
                  const SizedBox(height: 10),
                  _mismatch(),
                ],
              ],
            ),
          ),
        ),
        _footer(),
      ],
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Salary Slip - ${PayrollFormat.monthName(_s.month)} ${_s.year}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _kTextDark,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEDEFF3))),
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 10,
        runSpacing: 10,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: _outline(Colors.grey.shade300, _kTextDark),
            child: const Text('Close'),
          ),
          OutlinedButton(
            onPressed: _printing ? null : _download,
            style: _outline(_kPrimary, _kTextDark),
            child: _printing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Download PDF / Print'),
          ),
          Tooltip(
            message:
                'Per-employee payslip email needs the web request '
                'details, so it is not available yet.',
            child: FilledButton(
              onPressed: null,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Email Payslip'),
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _outline(Color border, Color text) {
    return OutlinedButton.styleFrom(
      foregroundColor: text,
      side: BorderSide(color: border, width: 1.4),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
    );
  }

  // ==========================================================
  // EMPLOYEE BOX
  // ==========================================================

  String _show(String value) => value.trim().isEmpty ? '—' : value.trim();

  Widget _employeeBox() {
    final name = _s.employeeName.trim().isEmpty ? '—' : _s.employeeName.trim();
    final code = _s.employeeCode.trim();
    final who = code.isEmpty ? name : '$name ($code)';

    const label = TextStyle(fontSize: 12.5, color: _kMuted);
    const value = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: _kTextDark,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Employee:', style: label),
              const SizedBox(width: 12),
              Expanded(
                child: Text(who, textAlign: TextAlign.end, style: value),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Department: ${_show(_s.department)}',
                  style: label,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Designation: ${_show(_s.designation)}',
                  textAlign: TextAlign.end,
                  style: label,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FOUR TILES
  // ==========================================================

  Widget _tiles() {
    Widget tile(String number, String caption, Color background, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                number,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        tile(
          '${_s.daysInMonth}',
          'MONTH DAYS',
          const Color(0xFFF1F5F9),
          const Color(0xFF334155),
        ),
        const SizedBox(width: 8),
        tile(
          '${_s.presentDays}',
          'PRESENT',
          const Color(0xFFDCFCE7),
          const Color(0xFF15803D),
        ),
        const SizedBox(width: 8),
        tile(
          '${_s.lateDays}',
          'LATE COUNT',
          const Color(0xFFFEF9C3),
          const Color(0xFFA16207),
        ),
        const SizedBox(width: 8),
        tile(
          '${_s.absentDays}',
          'ABSENT DAYS',
          const Color(0xFFFEE2E2),
          const Color(0xFFB91C1C),
        ),
      ],
    );
  }

  // ==========================================================
  // EARNINGS | DEDUCTIONS TABLE
  // ==========================================================

  Widget _table() {
    final earnings = <_Entry>[
      _Entry('Basic Salary', _s.baseSalary),
      _Entry('Allowances', _s.allowancesTotal),
      _Entry(
        'Expense Claims / Reimbursements',
        _s.expenseReimbursement,
        color: _kGreen,
      ),
    ];

    final deductions = <_Entry>[
      _Entry('Unpaid Absence Cut', _s.absenceDeduction, negative: true),
      _Entry('Late Penalty Cut', _s.lateDeduction, negative: true),
      _Entry('Professional Tax (PT)', _s.ptDeduction, negative: true),
      _Entry('Provident Fund (PF 5%)', _s.pfDeduction, negative: true),
      for (final d in _s.ruleDeductions)
        _Entry(
          d.ruleName.isEmpty ? 'Rule deduction' : d.ruleName,
          d.amount,
          negative: true,
        ),
    ];

    final rows = earnings.length > deductions.length
        ? earnings.length
        : deductions.length;

    const head = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w800,
      color: _kTextDark,
    );

    Widget headRow() => Container(
      color: const Color(0xFFF3F4F6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: const Row(
        children: [
          Expanded(flex: 4, child: Text('Earnings', style: head)),
          Expanded(
            flex: 3,
            child: Text('Amount', style: head, textAlign: TextAlign.end),
          ),
          SizedBox(width: 10),
          Expanded(flex: 4, child: Text('Deductions', style: head)),
          Expanded(
            flex: 3,
            child: Text('Amount', style: head, textAlign: TextAlign.end),
          ),
        ],
      ),
    );

    Widget cells(_Entry? entry, int labelFlex, int amountFlex) {
      if (entry == null) {
        return Expanded(
          flex: labelFlex + amountFlex,
          child: const Row(
            children: [
              Expanded(
                child: Text('-', style: TextStyle(color: _kMuted)),
              ),
              Text('-', style: TextStyle(color: _kMuted)),
            ],
          ),
        );
      }

      final amountColor = entry.color ?? (entry.negative ? _kRed : _kTextDark);

      return Expanded(
        flex: labelFlex + amountFlex,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: labelFlex,
              child: Text(
                entry.label,
                style: const TextStyle(fontSize: 12.5, color: _kTextDark),
              ),
            ),
            Expanded(
              flex: amountFlex,
              child: Text(
                entry.negative
                    ? '-${PayrollFormat.rupees2(entry.amount)}'
                    : PayrollFormat.rupees2(entry.amount),
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 12.5, color: amountColor),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          headRow(),
          for (var i = 0; i < rows; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFEDEFF3))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  cells(i < earnings.length ? earnings[i] : null, 4, 3),
                  const SizedBox(width: 10),
                  cells(i < deductions.length ? deductions[i] : null, 4, 3),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // NET BANNER
  // ==========================================================

  Widget _netBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NET PAYABLE SALARY',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Payable Days: ${_s.payableDays}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          Text(
            PayrollFormat.rupees2(_s.netSalary),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mismatch() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF5DDA3)),
      ),
      child: Text(
        'The net pay on record (${PayrollFormat.rupees2(_s.netSalary)}) '
        'differs from gross salary minus the deductions '
        '(${PayrollFormat.rupees2(_s.computedNet)}). Check the payroll rules '
        'before paying this slip.',
        style: const TextStyle(fontSize: 12.5, color: Color(0xFF92400E)),
      ),
    );
  }
}

class _Entry {
  const _Entry(this.label, this.amount, {this.color, this.negative = false});

  final String label;
  final double amount;
  final Color? color;
  final bool negative;
}

import 'package:flutter/material.dart';

import '../models/payroll_slip_model.dart';
import 'payroll_format.dart';

const Color _kPrimary = Color(0xFFE96832);
const Color _kTextDark = Color(0xFF18212F);
const Color _kMuted = Color(0xFF7A8494);
const Color _kRed = Color(0xFFDC2626);
const Color _kGreen = Color(0xFF16A34A);
const Color _kAmber = Color(0xFFB45309);

/// "Monthly Payroll Batch" table.
///
/// Wide screens: the web table (scrolls sideways if narrower than
/// [_minWidth]). Phones: one card per employee.
class PayrollBatchTable extends StatelessWidget {
  const PayrollBatchTable({
    super.key,
    required this.slips,
    required this.isLoading,
    required this.onViewSlip,
    this.onRecalculate,
  });

  final List<PayrollSlip> slips;

  /// True during the first load (nothing to show yet) and while refreshing.
  final bool isLoading;

  final ValueChanged<PayrollSlip> onViewSlip;

  /// null disables the Recalculate button (see the tooltip text below).
  final ValueChanged<PayrollSlip>? onRecalculate;

  static const double _minWidth = 1180;
  static const double _cardBreakpoint = 720;

  // employee, days, present, late, base, late cut, pt, pf, net, email, actions
  static const List<int> _flex = [5, 2, 3, 2, 3, 3, 3, 3, 3, 3, 5];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final refreshing = isLoading && slips.isNotEmpty;

        final Widget content;

        if (constraints.maxWidth < _cardBreakpoint) {
          content = _cards();
        } else {
          final width = constraints.maxWidth < _minWidth
              ? _minWidth
              : constraints.maxWidth;

          content = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: width, child: _table()),
          );
        }

        return Stack(
          children: [
            Opacity(opacity: refreshing ? 0.5 : 1, child: content),
            if (refreshing)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: _kPrimary,
                  backgroundColor: Colors.transparent,
                ),
              ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // WIDE TABLE
  // ==========================================================

  Widget _table() {
    return Column(
      children: [
        _header(),
        if (slips.isEmpty)
          for (var i = 0; i < 6; i++) _skeletonRow()
        else
          for (var i = 0; i < slips.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: Color(0xFFEDEFF3)),
            _row(slips[i]),
          ],
      ],
    );
  }

  Widget _header() {
    const style = TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      height: 1.5,
      color: Color(0xFF7B8493),
    );

    Widget cell(String text, int flex, {bool center = true}) => Expanded(
      flex: flex,
      child: Text(
        text,
        style: style,
        textAlign: center ? TextAlign.center : TextAlign.start,
      ),
    );

    return Container(
      color: const Color(0xFFF3F4F6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          cell('EMPLOYEE', _flex[0], center: false),
          cell('DAYS IN\nMONTH', _flex[1]),
          cell('PRESENT / PAID\nLEAVE', _flex[2]),
          cell('LATE\nCOUNT', _flex[3]),
          cell('BASE\nSALARY', _flex[4]),
          cell('LATE PENALTY\nCUT', _flex[5]),
          cell('PT\nDEDUCTION', _flex[6]),
          cell('PF (5%)\nCUT', _flex[7]),
          cell('NET PAYABLE\nSALARY', _flex[8]),
          cell('EMAIL\nSTATUS', _flex[9]),
          cell('ACTIONS', _flex[10]),
        ],
      ),
    );
  }

  Widget _row(PayrollSlip s) {
    Widget cell(int index, Widget child) => Expanded(
      flex: _flex[index],
      child: Center(child: child),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: _flex[0],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.employeeName.isEmpty ? 'Unnamed Employee' : s.employeeName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kTextDark,
                  ),
                ),
                if (s.employeeCode.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    s.employeeCode,
                    style: const TextStyle(fontSize: 12.5, color: _kMuted),
                  ),
                ],
              ],
            ),
          ),
          cell(1, _plain('${s.daysInMonth}')),
          cell(2, _present(s)),
          cell(3, _plain('${s.lateDays}')),
          cell(4, _plain(PayrollFormat.rupees(s.baseSalary))),
          cell(5, _deduction(s.lateDeduction)),
          cell(6, _deduction(s.ptDeduction)),
          cell(7, _deduction(s.pfDeduction)),
          cell(8, _net(s)),
          cell(9, EmailStatusPill(status: s.emailStatus)),
          cell(10, _actions(s)),
        ],
      ),
    );
  }

  Widget _skeletonRow() {
    Widget block(double width) => Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEDEFF3))),
      ),
      child: Row(
        children: [
          Expanded(flex: _flex[0], child: block(150)),
          for (var i = 1; i < _flex.length; i++)
            Expanded(
              flex: _flex[i],
              child: Center(child: block(56)),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // SHARED CELL WIDGETS
  // ==========================================================

  Widget _plain(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: _kTextDark,
    ),
  );

  Widget _present(PayrollSlip s) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${s.presentDays}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _kGreen,
            ),
          ),
          if (s.paidLeaveDays > 0)
            TextSpan(
              text: ' (+${s.paidLeaveDays} Paid L)',
              style: const TextStyle(fontSize: 11, color: _kGreen),
            ),
        ],
      ),
    );
  }

  Widget _deduction(double amount) {
    return Text(
      PayrollFormat.deduction(amount),
      style: TextStyle(
        fontSize: 14,
        fontWeight: amount > 0 ? FontWeight.w500 : FontWeight.w400,
        color: amount > 0 ? _kRed : _kTextDark,
      ),
    );
  }

  Widget _net(PayrollSlip s) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          PayrollFormat.rupees(s.netSalary),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _kPrimary,
          ),
        ),
        if (!s.netReconciles) ...[
          const SizedBox(width: 4),
          Tooltip(
            message:
                'Net pay differs from gross minus all deductions '
                '(${PayrollFormat.rupeesExact(s.computedNet)} expected).',
            child: const Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: _kAmber,
            ),
          ),
        ],
      ],
    );
  }

  Widget _actions(PayrollSlip s) {
    const textStyle = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700);

    ButtonStyle style() => OutlinedButton.styleFrom(
      foregroundColor: _kTextDark,
      side: const BorderSide(color: Color(0xFFE5E7EB)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: textStyle,
    );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        OutlinedButton(
          onPressed: () => onViewSlip(s),
          style: style(),
          child: const Text('View Slip'),
        ),
        Tooltip(
          message: onRecalculate == null
              ? 'Per-employee recalculation is not available yet. Use '
                    '"Calculate & Generate Payroll" to recompute the month.'
              : 'Recalculate this payslip',
          child: OutlinedButton(
            onPressed: onRecalculate == null ? null : () => onRecalculate!(s),
            style: style(),
            child: const Text('Recalculate'),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // PHONE CARDS
  // ==========================================================

  Widget _cards() {
    if (slips.isEmpty) {
      return Column(children: [for (var i = 0; i < 4; i++) _skeletonCard()]);
    }

    return Column(
      children: [
        for (var i = 0; i < slips.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _card(slips[i]),
        ],
      ],
    );
  }

  Widget _skeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _card(PayrollSlip s) {
    Widget fact(String label, Widget value) => SizedBox(
      width: 104,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: _kMuted)),
          const SizedBox(height: 2),
          value,
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.employeeName.isEmpty
                          ? 'Unnamed Employee'
                          : s.employeeName,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: _kTextDark,
                      ),
                    ),
                    if (s.employeeCode.isNotEmpty)
                      Text(
                        s.employeeCode,
                        style: const TextStyle(fontSize: 12, color: _kMuted),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _net(s),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            runSpacing: 10,
            children: [
              fact('Days in month', _plain('${s.daysInMonth}')),
              fact('Present / paid leave', _present(s)),
              fact('Late count', _plain('${s.lateDays}')),
              fact('Base salary', _plain(PayrollFormat.rupees(s.baseSalary))),
              fact('Late penalty', _deduction(s.lateDeduction)),
              fact('PT', _deduction(s.ptDeduction)),
              fact('PF (5%)', _deduction(s.pfDeduction)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              EmailStatusPill(status: s.emailStatus),
              const Spacer(),
              _actions(s),
            ],
          ),
        ],
      ),
    );
  }
}

// =================================================================
// EMAIL STATUS PILL
// =================================================================

class EmailStatusPill extends StatelessWidget {
  const EmailStatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: PayrollFormat.emailBackground(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        PayrollFormat.emailLabel(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: PayrollFormat.emailColor(status),
        ),
      ),
    );
  }
}

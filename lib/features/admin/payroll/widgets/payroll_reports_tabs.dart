// lib/features/admin/payroll/widgets/payroll_reports_tabs.dart

import 'package:flutter/material.dart';

import '../../../../data/models/employee.dart';
import '../models/payroll_reports_model.dart';
import 'payroll_format.dart';

const Color _kPrimary = Color(0xFFE96832);
const Color _kTextDark = Color(0xFF18212F);
const Color _kMuted = Color(0xFF7A8494);
const Color _kBlue = Color(0xFF1D4ED8);

// =================================================================
// SHARED PIECES
// =================================================================

class _ScrollTable extends StatelessWidget {
  const _ScrollTable({required this.minWidth, required this.child});

  final double minWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < minWidth
            ? minWidth
            : constraints.maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: width, child: child),
        );
      },
    );
  }
}

Widget _tableHeader(List<(String, int, TextAlign)> columns) {
  const style = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
    color: Color(0xFF7B8493),
  );

  return Container(
    color: const Color(0xFFF3F4F6),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(
      children: [
        for (final (label, flex, align) in columns)
          Expanded(
            flex: flex,
            child: Text(label, style: style, textAlign: align),
          ),
      ],
    ),
  );
}

Widget _stateMessage({
  required String text,
  IconData? icon,
  Color? iconColor,
  Widget? action,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
    child: Column(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 34, color: iconColor ?? _kMuted),
          const SizedBox(height: 12),
        ],
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700),
        ),
        if (action != null) ...[const SizedBox(height: 14), action],
      ],
    ),
  );
}

Widget _loading() => const Padding(
  padding: EdgeInsets.symmetric(vertical: 60),
  child: Center(child: CircularProgressIndicator()),
);

Widget _retry(VoidCallback? onRetry) => onRetry == null
    ? const SizedBox.shrink()
    : FilledButton.icon(
  onPressed: onRetry,
  icon: const Icon(Icons.refresh_rounded),
  label: const Text('Try Again'),
  style: FilledButton.styleFrom(backgroundColor: _kPrimary),
);

Widget _staleBanner(String message) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E6),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFF5DDA3)),
    ),
    child: Text(
      '$message Showing the last loaded data.',
      style: const TextStyle(fontSize: 12.5, color: Color(0xFF92400E)),
    ),
  );
}

// =================================================================
// PT COMPLIANCE REPORT
// =================================================================

class PayrollPtTab extends StatelessWidget {
  const PayrollPtTab({
    super.key,
    required this.report,
    required this.loading,
    required this.error,
    required this.month,
    required this.year,
    required this.onRetry,
  });

  final PtReport? report;
  final bool loading;
  final String? error;
  final int month;
  final int year;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final data = report;

    if (data == null) {
      if (error != null && !loading) {
        return _stateMessage(
          text: error!,
          icon: Icons.error_outline_rounded,
          iconColor: const Color(0xFFDC2626),
          action: _retry(onRetry),
        );
      }
      return _loading();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Professional Tax (PT) Compliance Report',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kTextDark,
          ),
        ),
        const SizedBox(height: 14),

        // Blue Summary Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7FF), // Light blue background
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFBFDBFE)), // Light blue border
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tax Collection Period: Month $month / Year $year',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B), // Gray text
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total PT Collected: ${PayrollFormat.rupees(data.totalCollected)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1D4ED8), // Strong blue text
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (error != null) ...[
          _staleBanner(error!),
          const SizedBox(height: 12),
        ],

        if (data.rows.isEmpty)
          _stateMessage(text: 'No PT deductions found for this period.')
        else
          _ScrollTable(
            minWidth: 560,
            child: Column(
              children: [
                // Table Header
                Container(
                  color: const Color(0xFFF8F9FB), // Light gray header
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: const Row(
                    children: [
                      Expanded(flex: 5, child: _HeaderText('EMPLOYEE NAME')),
                      Expanded(flex: 3, child: _HeaderText('EMPLOYEE CODE')),
                      Expanded(flex: 3, child: _HeaderText('GROSS SALARY', textAlign: TextAlign.end)),
                      Expanded(flex: 3, child: _HeaderText('PT AMOUNT DEDUCTED', textAlign: TextAlign.end)),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),

                // Rows
                for (final row in data.rows) _ptRow(row),
              ],
            ),
          ),
      ],
    );
  }

  Widget _ptRow(PtReportRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEDEFF3))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              row.name.isEmpty ? '—' : row.name,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: _kTextDark),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.code.isEmpty ? '—' : row.code,
              style: const TextStyle(fontSize: 13, color: _kTextDark),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              PayrollFormat.rupees(row.gross),
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13.5, color: _kTextDark),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              PayrollFormat.rupees(row.pt),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D4ED8), // Blue text for PT amount
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  final TextAlign textAlign;
  const _HeaderText(this.text, {this.textAlign = TextAlign.start});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF7B8493), // Gray text for headers
        letterSpacing: 0.5,
      ),
    );
  }
}

// =================================================================
// PF (5%) ACCUMULATION & REFUND HISTORY
// =================================================================

class PayrollPfTab extends StatelessWidget {
  const PayrollPfTab({
    super.key,
    required this.report,
    required this.loading,
    required this.error,
    required this.busy,
    required this.onRetry,
    required this.onRefund,
    required this.employees,
  });

  final PfReport? report;
  final bool loading;
  final String? error;
  final bool busy;
  final VoidCallback onRetry;
  final ValueChanged<PfBalance> onRefund;
  final List<Employee> employees;

  @override
  Widget build(BuildContext context) {
    final data = report;

    if (data == null) {
      if (error != null && !loading) {
        return _stateMessage(
          text: error!,
          icon: Icons.error_outline_rounded,
          iconColor: const Color(0xFFDC2626),
          action: _retry(onRetry),
        );
      }
      return _loading();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- SUMMARY CARDS ---
        _summaryCards(data),
        const SizedBox(height: 22),

        // --- SECTION 1: BALANCES ---
        const Text(
          'Section 1: Employee Accumulated PF Balances & Refund at Leaving',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kTextDark),
        ),
        const SizedBox(height: 4),
        Text(
          'Shows 5% PF accumulated per employee across all months. Click "Refund Full PF Amount" when an employee leaves.',
          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 14),
        if (error != null) ...[
          _staleBanner(error!),
          const SizedBox(height: 12),
        ],
        if (data.balances.isEmpty)
          _stateMessage(text: 'No PF balances found.')
        else
          _ScrollTable(
            minWidth: 920,
            child: Column(
              children: [
                _tableHeader(const [
                  ('EMPLOYEE NAME', 4, TextAlign.start),
                  ('CODE', 2, TextAlign.start),
                  ('STATUS', 2, TextAlign.start),
                  ('TOTAL 5% PF ACCUMULATED', 3, TextAlign.end),
                  ('REFUNDED AMOUNT', 3, TextAlign.end),
                  ('PENDING REFUND BALANCE', 3, TextAlign.end),
                  ('REFUND ACTION', 4, TextAlign.center),
                ]),
                for (final b in data.balances) _balanceRow(b),
              ],
            ),
          ),

        const SizedBox(height: 32),

        // --- SECTION 2: HISTORY LOG ---
        const Text(
          'Section 2: Monthly 5% PF Deduction History Log',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kTextDark),
        ),
        const SizedBox(height: 4),
        Text(
          'Detailed month-by-month historical breakdown of 5% PF deductions saved per payroll generation.',
          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 14),
        if (data.history.isEmpty)
          _stateMessage(text: 'No deduction history found.')
        else
          _ScrollTable(
            minWidth: 920,
            child: Column(
              children: [
                _tableHeader(const [
                  ('MONTH / YEAR', 3, TextAlign.start),
                  ('EMPLOYEE NAME', 4, TextAlign.start),
                  ('EMPLOYEE CODE', 3, TextAlign.start),
                  ('BASE SALARY', 3, TextAlign.end),
                  ('5% PF DEDUCTION AMOUNT', 3, TextAlign.end),
                  ('ACCUMULATION STATUS', 3, TextAlign.end),
                ]),
                for (final h in data.history) _historyRow(h),
              ],
            ),
          ),
      ],
    );
  }

  Widget _summaryCards(PfReport data) {
    Widget card({
      required String title,
      required double value,
      required Color background,
      required Color border,
      required Color accent,
    }) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: accent,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              PayrollFormat.rupees(value),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ],
        ),
      );
    }

    final cards = [
      card(
        title: 'TOTAL 5% PF ACCUMULATED',
        value: data.totalAccumulated,
        background: const Color(0xFFF0FDF4),
        border: const Color(0xFFBBF7D0),
        accent: const Color(0xFF15803D),
      ),
      card(
        title: 'TOTAL PENDING BALANCE (FOR REFUND)',
        value: data.totalPending,
        background: const Color(0xFFFEFCE8),
        border: const Color(0xFFFDE68A),
        accent: const Color(0xFFB45309),
      ),
      card(
        title: 'TOTAL PF REFUNDED',
        value: data.totalRefunded,
        background: const Color(0xFFEFF6FF),
        border: const Color(0xFFBFDBFE),
        accent: _kBlue,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 640) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 14),
                  Expanded(child: cards[i]),
                ],
              ],
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              cards[i],
            ],
          ],
        );
      },
    );
  }

  Widget _balanceRow(PfBalance b) {
    final localEmp = employees.where((e) =>
    e.id == b.employeeId || e.employeeCode == b.code
    ).firstOrNull;

    final displayName = b.name.isNotEmpty
        ? b.name
        : (localEmp?.name ?? '-');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEDEFF3))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              displayName,
              style: const TextStyle(fontSize: 13.5, color: _kTextDark),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              b.code.isEmpty ? '-' : b.code,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _statusPill(b),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              PayrollFormat.rupees(b.accumulated),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: _kTextDark,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              PayrollFormat.rupees(b.refunded),
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF16A34A)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              PayrollFormat.rupees(b.pending),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: _kTextDark,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Center(
              child: b.canRefund
                  ? FilledButton(
                onPressed: busy ? null : () => onRefund(b),
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text('Refund Full PF (${PayrollFormat.rupees(b.pending)})'),
              )
                  : const Text('-', style: TextStyle(color: _kMuted)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(PfBalance b) {
    final active = b.isActive;
    final color = active ? const Color(0xFF15803D) : const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE9F8EF) : const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        b.status.isEmpty ? '—' : b.status.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _historyRow(PfHistoryRecord h) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final monthStr = (h.month >= 1 && h.month <= 12) ? months[h.month - 1] : '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEDEFF3))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('$monthStr ${h.year}', style: const TextStyle(fontSize: 13.5, color: _kTextDark)),
          ),
          Expanded(
            flex: 4,
            child: Text(h.name.isEmpty ? '-' : h.name, style: const TextStyle(fontSize: 13.5, color: _kTextDark)),
          ),
          Expanded(
            flex: 3,
            child: Text(h.code.isEmpty ? '-' : h.code, style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
          ),
          Expanded(
            flex: 3,
            child: Text(PayrollFormat.rupees(h.baseSalary), textAlign: TextAlign.end, style: const TextStyle(fontSize: 13.5, color: _kTextDark)),
          ),
          Expanded(
            flex: 3,
            child: Text(PayrollFormat.rupees(h.pfAmount), textAlign: TextAlign.end, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _kPrimary)),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7), // Light amber background
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  h.status.toUpperCase(),
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
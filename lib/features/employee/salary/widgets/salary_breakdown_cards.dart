// lib/features/employee/salary/widgets/salary_breakdown_cards.dart

import 'package:flutter/material.dart';

import '../models/employee_salary_breakdown_model.dart';
import '../utils/salary_theme.dart';

class SalaryEarningsCard extends StatelessWidget {
  final EmployeeSalaryBreakdownModel b;
  const SalaryEarningsCard({super.key, required this.b});

  @override
  Widget build(BuildContext context) {
    return _BreakdownCard(
      title: 'Earnings Breakdown',
      titleColor: const Color(0xFF166534),
      bg: SalaryColors.earningsBg,
      borderColor: const Color(0xFFCDEBD6),
      rows: [
        _Row('Base Salary', SalaryFormatters.rupees(b.baseSalary)),
        _Row('Allowances Total', SalaryFormatters.rupees(b.allowancesTotal)),
        _Row(
          'Expense Claims / Reimbursements',
          SalaryFormatters.earning(b.expenseReimbursement),
          valueColor: SalaryColors.earnings,
        ),
        _Row(
          'Gross Earnings',
          SalaryFormatters.rupees(b.grossSalary),
          bold: true,
        ),
      ],
    );
  }
}

class SalaryDeductionsCard extends StatelessWidget {
  final EmployeeSalaryBreakdownModel b;
  const SalaryDeductionsCard({super.key, required this.b});

  @override
  Widget build(BuildContext context) {
    final rows = <_Row>[
      _Row(
        'Absence Cuts (${b.absentDays} days)',
        SalaryFormatters.deduction(b.absenceDeductionAmount),
      ),
      _Row(
        'Late Arrival Penalty Cuts (${b.lateDays} lates)',
        SalaryFormatters.deduction(b.lateDeductionAmount),
      ),
      _Row(
        'Professional Tax (PT Tax)',
        SalaryFormatters.deduction(b.ptDeduction),
      ),
      _Row('Provident Fund (PF 5%)', SalaryFormatters.deduction(b.pfDeduction)),
      for (final d in b.deductions)
        _Row(
          d.ruleName.isEmpty ? 'Other Deduction' : d.ruleName,
          SalaryFormatters.deduction(d.amount),
        ),
      _Row(
        'Total Deductions',
        SalaryFormatters.deduction(b.totalDeductions),
        bold: true,
      ),
    ];

    return _BreakdownCard(
      title: 'Deductions Breakdown',
      titleColor: const Color(0xFF991B1B),
      bg: SalaryColors.deductionsBg,
      borderColor: const Color(0xFFF5C6C2),
      rows: rows,
      defaultValueColor: SalaryColors.deductions,
    );
  }
}

// ---------------------------------------------------------------------------
// Shared internals for both cards
// ---------------------------------------------------------------------------

class _Row {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;
  const _Row(this.label, this.value, {this.valueColor, this.bold = false});
}

class _BreakdownCard extends StatelessWidget {
  final String title;
  final Color titleColor;
  final Color bg;
  final Color borderColor;
  final List<_Row> rows;
  final Color? defaultValueColor;

  const _BreakdownCard({
    required this.title,
    required this.titleColor,
    required this.bg,
    required this.borderColor,
    required this.rows,
    this.defaultValueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 12),
          for (var i = 0; i < rows.length; i++) ...[
            if (rows[i].bold && i > 0) ...[
              const SizedBox(height: 4),
              Divider(height: 1, color: borderColor),
              const SizedBox(height: 8),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rows[i].label,
                      style: SalaryText.rowLabel.copyWith(
                        fontWeight: rows[i].bold
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: rows[i].bold
                            ? SalaryColors.textDark
                            : SalaryColors.textMedium,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    rows[i].value,
                    style: SalaryText.rowAmount.copyWith(
                      color:
                          rows[i].valueColor ??
                          defaultValueColor ??
                          SalaryColors.textDark,
                      fontWeight: rows[i].bold
                          ? FontWeight.w800
                          : FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

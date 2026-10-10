// lib/features/employee/salary/widgets/salary_history_card.dart

import 'package:flutter/material.dart';

import '../models/employee_salary_slip_model.dart';
import '../utils/salary_theme.dart';

class SalaryHistoryCard extends StatelessWidget {
  final EmployeeSalarySlipModel slip;
  final VoidCallback onViewBreakdown;
  final VoidCallback? onPdfPrint;

  const SalaryHistoryCard({
    super.key,
    required this.slip,
    required this.onViewBreakdown,
    this.onPdfPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: SalaryColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SalaryColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final compact = c.maxWidth < 720;

          final left = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    SalaryFormatters.monthYear(slip.month, slip.year),
                    style: SalaryText.month,
                  ),
                  const SizedBox(width: 10),
                  _StatusPill(status: slip.status),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 14,
                runSpacing: 4,
                children: [
                  RichText(
                    text: TextSpan(
                      style: SalaryText.rowLabel,
                      children: [
                        const TextSpan(text: 'Gross: '),
                        TextSpan(
                          text: SalaryFormatters.rupees(slip.grossSalary),
                          style: SalaryText.rowAmount,
                        ),
                      ],
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      style: SalaryText.rowLabel,
                      children: [
                        const TextSpan(text: 'Deductions: '),
                        TextSpan(
                          text: SalaryFormatters.deduction(
                            slip.totalDeductions,
                          ),
                          style: SalaryText.rowAmount.copyWith(
                            color: SalaryColors.deductions,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );

          final right = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('NET SALARY', style: SalaryText.label),
                  const SizedBox(height: 4),
                  Text(
                    SalaryFormatters.rupees(slip.netSalary),
                    style: SalaryText.metricValueGreen.copyWith(fontSize: 20),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              OutlinedButton(
                onPressed: onViewBreakdown,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: SalaryColors.textDark,
                  side: const BorderSide(color: SalaryColors.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'View Breakdown',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: onPdfPrint,
                style: FilledButton.styleFrom(
                  backgroundColor: SalaryColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'PDF / Print',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                left,
                const SizedBox(height: 14),
                Align(alignment: Alignment.centerLeft, child: right),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              right,
            ],
          );
        },
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    Color fg = SalaryColors.statusGenerated;
    Color bg = SalaryColors.statusGeneratedBg;
    switch (s) {
      case 'approved':
        fg = SalaryColors.statusApproved;
        bg = SalaryColors.statusApprovedBg;
        break;
      case 'paid':
        fg = SalaryColors.statusPaid;
        bg = SalaryColors.statusPaidBg;
        break;
      case 'draft':
        fg = SalaryColors.statusDraft;
        bg = SalaryColors.statusDraftBg;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            s.isEmpty ? '—' : s,
            style: SalaryText.pill.copyWith(color: fg, letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}

/// Inlined empty state (was salary_empty_state.dart).
class SalaryEmptyState extends StatelessWidget {
  const SalaryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 40,
            color: SalaryColors.textLight,
          ),
          const SizedBox(height: 12),
          Text(
            'No payslips available yet.',
            style: SalaryText.cardTitle.copyWith(
              color: SalaryColors.textMedium,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your monthly payslips will appear here once payroll is generated.',
            textAlign: TextAlign.center,
            style: SalaryText.subtitle,
          ),
        ],
      ),
    );
  }
}

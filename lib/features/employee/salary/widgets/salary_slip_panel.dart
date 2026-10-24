// lib/features/employee/salary/widgets/salary_slip_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/employee_salary_breakdown_model.dart';
import '../repositories/employee_salary_repository.dart';
import '../utils/salary_theme.dart';
import 'salary_breakdown_cards.dart';

/// Inline "Itemized Payslip Breakdown" panel shown on the My Salary page
/// (same as the web: orange bordered card above the history list).
class SalarySlipPanel extends ConsumerWidget {
  final int month;
  final int year;
  final bool busy;
  final VoidCallback onDownloadPdf;
  final VoidCallback onClose;

  const SalarySlipPanel({
    super.key,
    required this.month,
    required this.year,
    required this.busy,
    required this.onDownloadPdf,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (month: month, year: year);
    final detailAsync = ref.watch(salarySlipDetailProvider(key));

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SalarySpacing.cardPaddingH,
        vertical: SalarySpacing.cardPaddingV,
      ),
      decoration: BoxDecoration(
        color: SalaryColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: SalaryColors.primary.withValues(alpha: 0.75),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            month: month,
            year: year,
            busy: busy,
            onDownloadPdf: onDownloadPdf,
            onClose: onClose,
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: SalaryColors.border),
          const SizedBox(height: 16),
          detailAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: SalaryColors.primary),
              ),
            ),
            error: (e, _) => _PanelError(
              message: e.toString().replaceFirst('Exception: ', ''),
              onRetry: () => ref.invalidate(salarySlipDetailProvider(key)),
            ),
            data: (b) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AttendanceSummary(b: b),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, c) {
                    final stacked = c.maxWidth < 700;
                    final earnings = SalaryEarningsCard(b: b);
                    final deductions = SalaryDeductionsCard(b: b);
                    if (stacked) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          earnings,
                          const SizedBox(height: 16),
                          deductions,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: earnings),
                        const SizedBox(width: 16),
                        Expanded(child: deductions),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                _NetPaySection(b: b),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header (title + Download PDF / Print + Close Preview)
// ---------------------------------------------------------------------------

class _PanelHeader extends StatelessWidget {
  final int month;
  final int year;
  final bool busy;
  final VoidCallback onDownloadPdf;
  final VoidCallback onClose;

  const _PanelHeader({
    required this.month,
    required this.year,
    required this.busy,
    required this.onDownloadPdf,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < 560;

        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ITEMIZED PAYSLIP BREAKDOWN',
              style: SalaryText.sectionHeader.copyWith(
                color: SalaryColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${SalaryFormatters.monthYear(month, year)} Salary Slip',
              style: SalaryText.cardTitle.copyWith(fontSize: 17),
            ),
          ],
        );

        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: busy ? null : onDownloadPdf,
              style: FilledButton.styleFrom(
                backgroundColor: SalaryColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: busy
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                'Download PDF / Print',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: onClose,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: SalaryColors.textDark,
                side: const BorderSide(color: SalaryColors.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Close Preview',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 14), actions],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: title),
            const SizedBox(width: 12),
            actions,
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Attendance summary strip
// ---------------------------------------------------------------------------

class _AttendanceSummary extends StatelessWidget {
  final EmployeeSalaryBreakdownModel b;
  const _AttendanceSummary({required this.b});

  @override
  Widget build(BuildContext context) {
    final items = <_Metric>[
      _Metric('PRESENT DAYS', '${b.presentDays} Days', SalaryColors.earnings),
      _Metric('LATE CHECK-INS', '${b.lateDays} Lates', const Color(0xFFD97706)),
      _Metric('ABSENCES', '${b.absentDays} Days', SalaryColors.deductions),
      _Metric(
        'APPROVED LEAVES',
        '${b.leaveDays} Days',
        const Color(0xFF7C3AED),
      ),
      _Metric('PAYABLE DAYS', '${b.payableDays} Days', SalaryColors.textDark),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: SalaryColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final width = c.maxWidth;
          final perRow = width < 420
              ? 2
              : width < 720
              ? 3
              : 5;
          const spacing = 12.0;
          final cellWidth = (width - spacing * (perRow - 1)) / perRow;

          return Wrap(
            spacing: spacing,
            runSpacing: 14,
            children: [
              for (final m in items)
                SizedBox(
                  width: cellWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.label, style: SalaryText.label),
                      const SizedBox(height: 6),
                      Text(
                        m.value,
                        style: SalaryText.value.copyWith(
                          color: m.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Metric {
  final String label;
  final String value;
  final Color color;
  const _Metric(this.label, this.value, this.color);
}

// ---------------------------------------------------------------------------
// Net pay band
// ---------------------------------------------------------------------------

class _NetPaySection extends StatelessWidget {
  final EmployeeSalaryBreakdownModel b;
  const _NetPaySection({required this.b});

  @override
  Widget build(BuildContext context) {
    final caption =
        'Calculated for ${b.payableDays} Payable Days in '
        '${SalaryFormatters.monthYear(b.month, b.year)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: SalaryColors.netBand,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final compact = c.maxWidth < 480;
          final left = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NET MONTHLY SALARY PAYABLE',
                style: SalaryText.netBandLabel,
              ),
              const SizedBox(height: 4),
              Text(caption, style: SalaryText.netBandCaption),
            ],
          );
          final amount = Text(
            SalaryFormatters.rupees(b.netSalary),
            style: SalaryText.netBandAmount,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [left, const SizedBox(height: 12), amount],
            );
          }

          return Row(
            children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              amount,
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _PanelError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PanelError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: SalaryColors.primary,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            message.isEmpty ? 'Failed to load payslip.' : message,
            textAlign: TextAlign.center,
            style: SalaryText.subtitle.copyWith(color: SalaryColors.textMedium),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: SalaryColors.primary,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
// lib/features/employee/salary/screens/employee_salary_slip_screen.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/employee_salary_breakdown_model.dart';
import '../repositories/employee_salary_repository.dart';
import '../utils/salary_theme.dart';
import '../widgets/salary_breakdown_cards.dart';

class EmployeeSalarySlipScreen extends ConsumerStatefulWidget {
  final int month;
  final int year;
  final bool autoPrint;

  const EmployeeSalarySlipScreen({
    super.key,
    required this.month,
    required this.year,
    this.autoPrint = false,
  });

  @override
  ConsumerState<EmployeeSalarySlipScreen> createState() =>
      _EmployeeSalarySlipScreenState();
}

class _EmployeeSalarySlipScreenState
    extends ConsumerState<EmployeeSalarySlipScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoPrint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _downloadOrPrintHtml(month: widget.month, year: widget.year);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = (month: widget.month, year: widget.year);
    final detailAsync = ref.watch(salarySlipDetailProvider(key));

    final media = MediaQuery.of(context);
    final clamped = media.textScaler.clamp(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.15,
    );

    return Scaffold(
      backgroundColor: SalaryColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: SalaryColors.textDark),
        title: Text(
          '${SalaryFormatters.monthYear(widget.month, widget.year)} Salary Slip',
          style: const TextStyle(
            color: SalaryColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      body: MediaQuery(
        data: media.copyWith(textScaler: clamped),
        child: detailAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: SalaryColors.primary),
          ),
          error: (e, _) => _SlipErrorState(
            message: e.toString().replaceFirst('Exception: ', ''),
            onRetry: () => ref.invalidate(salarySlipDetailProvider(key)),
          ),
          data: (b) => SingleChildScrollView(
            padding: const EdgeInsets.all(SalarySpacing.pagePadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: SalarySpacing.maxContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SlipHeaderCard(
                      month: b.month,
                      year: b.year,
                      busy: _busy,
                      onDownloadPdf: () =>
                          _downloadOrPrintHtml(month: b.month, year: b.year),
                    ),
                    const SizedBox(height: 16),
                    _AttendanceSummary(b: b),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, c) {
                        final stacked = c.maxWidth < 820;
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
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadOrPrintHtml({
    required int month,
    required int year,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final employeeId = await ref.read(currentEmployeeIdProvider.future);
      final html = await ref
          .read(employeeSalaryRepositoryProvider)
          .getSlipHtml(employeeId: employeeId, month: month, year: year);

      if (!mounted) return;
      await _openHtml(html, month, year);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Writes the HTML to a temp file and opens it in the system browser,
  /// where the user can print or save as PDF.
  Future<void> _openHtml(String html, int month, int year) async {
    if (kIsWeb) {
      throw Exception(
        'Printing is not supported on the web build of this app.',
      );
    }

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/payslip_${year}_${month.toString().padLeft(2, '0')}.html',
    );
    await file.writeAsString(html);

    final uri = Uri.file(file.path);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      throw Exception('Could not open the payslip in a viewer.');
    }
  }
}

// ---------------------------------------------------------------------------
// Inlined header card
// ---------------------------------------------------------------------------

class _SlipHeaderCard extends StatelessWidget {
  final int month;
  final int year;
  final bool busy;
  final VoidCallback onDownloadPdf;

  const _SlipHeaderCard({
    required this.month,
    required this.year,
    required this.busy,
    required this.onDownloadPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SalarySpacing.cardPaddingH,
        vertical: SalarySpacing.cardPaddingV,
      ),
      decoration: BoxDecoration(
        color: SalaryColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: SalaryColors.primary.withValues(alpha: 0.55),
          width: 1.2,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final compact = c.maxWidth < 560;

          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ITEMIZED PAYSLIP BREAKDOWN',
                style: SalaryText.sectionHeader,
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
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: SalaryColors.textDark,
                  side: const BorderSide(color: SalaryColors.border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Close Preview',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inlined attendance summary (was salary_attendance_summary.dart)
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
// Inlined net pay band (was salary_summary_section.dart)
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
// Inlined error state
// ---------------------------------------------------------------------------

class _SlipErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SlipErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              style: SalaryText.subtitle.copyWith(
                color: SalaryColors.textMedium,
              ),
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
      ),
    );
  }
}

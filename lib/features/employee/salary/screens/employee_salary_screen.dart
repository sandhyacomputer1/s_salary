// lib/features/employee/salary/screens/employee_salary_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/employee_salary_slip_model.dart';
import '../repositories/employee_salary_repository.dart';
import '../utils/payslip_viewer.dart';
import '../utils/salary_theme.dart';
import '../widgets/salary_history_card.dart';
import '../widgets/salary_slip_panel.dart';
import '../widgets/salary_structure_card.dart';

typedef _SlipKey = ({int month, int year});

class EmployeeSalaryScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const EmployeeSalaryScreen({super.key, this.embedded = false});

  @override
  ConsumerState<EmployeeSalaryScreen> createState() =>
      _EmployeeSalaryScreenState();
}

class _EmployeeSalaryScreenState extends ConsumerState<EmployeeSalaryScreen> {
  /// Month currently expanded inline (null = nothing open).
  _SlipKey? _selected;
  bool _busy = false;

  static String _clean(Object e) =>
      e.toString().replaceFirst('Exception: ', '');

  /// Page padding that follows the real width of the area, so the screen
  /// fits when the sidebar is open, hidden, or on a phone.
  static double _pagePadFor(double width) {
    if (width < 420) return 10;
    if (width < 700) return 14;
    if (width < 1000) return 18;
    return SalarySpacing.pagePadding;
  }

  void _toggleBreakdown(EmployeeSalarySlipModel s) {
    final key = (month: s.month, year: s.year);
    setState(() => _selected = _selected == key ? null : key);
  }

  Future<void> _pdfPrint(EmployeeSalarySlipModel s) async {
    // Same as web: PDF / Print opens the breakdown and prints it.
    setState(() => _selected = (month: s.month, year: s.year));
    await _downloadOrPrintHtml(month: s.month, year: s.year);
  }

  @override
  Widget build(BuildContext context) {
    final structureAsync = ref.watch(salaryStructureProvider);
    final slipsAsync = ref.watch(salarySlipsProvider);

    final media = MediaQuery.of(context);
    final clamped = media.textScaler.clamp(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.15,
    );

    final body = MediaQuery(
      data: media.copyWith(textScaler: clamped),
      // LayoutBuilder gives the width that is really free (sidebar open,
      // hidden, or phone) - the content always fills it.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pad = _pagePadFor(constraints.maxWidth);

          return SingleChildScrollView(
            padding: EdgeInsets.all(pad),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  structureAsync.when(
                    loading: () => const _CardSkeleton(height: 160),
                    error: (e, _) => _ErrorCard(
                      title: 'Active Salary Package Structure',
                      message: _clean(e),
                      onRetry: () => ref.invalidate(salaryStructureProvider),
                    ),
                    data: (s) => SalaryStructureCard(structure: s),
                  ),
                  const SizedBox(height: SalarySpacing.cardGap),

                  // Inline breakdown (appears between structure & history)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: _selected == null
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                      padding: const EdgeInsets.only(
                        bottom: SalarySpacing.cardGap,
                      ),
                      child: SalarySlipPanel(
                        key: ValueKey(
                            '${_selected!.year}-${_selected!.month}'),
                        month: _selected!.month,
                        year: _selected!.year,
                        busy: _busy,
                        onDownloadPdf: () => _downloadOrPrintHtml(
                          month: _selected!.month,
                          year: _selected!.year,
                        ),
                        onClose: () => setState(() => _selected = null),
                      ),
                    ),
                  ),

                  slipsAsync.when(
                    loading: () => const _CardSkeleton(height: 280),
                    error: (e, _) => _ErrorCard(
                      title: 'My Monthly Payslips & Salary History',
                      message: _clean(e),
                      onRetry: () => ref.invalidate(salarySlipsProvider),
                    ),
                    data: (slips) => _HistorySection(
                      slips: slips,
                      selected: _selected,
                      compact: constraints.maxWidth < 600,
                      onViewBreakdown: _toggleBreakdown,
                      onPdfPrint: _pdfPrint,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: SalaryColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: SalaryColors.textDark),
        title: const Text(
          'My Salary',
          style: TextStyle(
            color: SalaryColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      body: body,
    );
  }

  // -------------------------------------------------------------------------
  // Download / print — opens the payslip page + print dialog (same as web)
  // -------------------------------------------------------------------------

  Future<void> _downloadOrPrintHtml({
    required int month,
    required int year,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);

    // Must run before the first `await` (web popup rule).
    final viewer = createPayslipViewer();

    try {
      final employeeId = await ref.read(currentEmployeeIdProvider.future);
      final html = await ref
          .read(employeeSalaryRepositoryProvider)
          .getSlipHtml(employeeId: employeeId, month: month, year: year);

      if (!mounted) {
        viewer.cancel();
        return;
      }
      await viewer.show(html, month: month, year: year);
    } catch (e) {
      viewer.cancel();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_clean(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

// ---------------------------------------------------------------------------
// History section
// ---------------------------------------------------------------------------

class _HistorySection extends StatelessWidget {
  final List<EmployeeSalarySlipModel> slips;
  final _SlipKey? selected;

  /// True on phones / narrow areas: tighter card padding.
  final bool compact;
  final ValueChanged<EmployeeSalarySlipModel> onViewBreakdown;
  final ValueChanged<EmployeeSalarySlipModel> onPdfPrint;

  const _HistorySection({
    required this.slips,
    required this.selected,
    required this.onViewBreakdown,
    required this.onPdfPrint,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : SalarySpacing.cardPaddingH,
        vertical: compact ? 14 : SalarySpacing.cardPaddingV,
      ),
      decoration: BoxDecoration(
        color: SalaryColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SalaryColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Monthly Payslips & Salary History (${slips.length})',
            style: SalaryText.cardTitle,
          ),
          const SizedBox(height: 4),
          const Text(
            'Select any month to inspect detailed breakdown or print PDF payslip',
            style: SalaryText.subtitle,
          ),
          const SizedBox(height: 16),
          if (slips.isEmpty)
            const SalaryEmptyState()
          else
            for (var i = 0; i < slips.length; i++) ...[
              _SelectableRow(
                isSelected: selected != null &&
                    selected!.month == slips[i].month &&
                    selected!.year == slips[i].year,
                child: SalaryHistoryCard(
                  slip: slips[i],
                  onViewBreakdown: () => onViewBreakdown(slips[i]),
                  onPdfPrint: () => onPdfPrint(slips[i]),
                ),
              ),
              if (i != slips.length - 1) const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

/// Blue highlight on the open month (as on the web).
class _SelectableRow extends StatelessWidget {
  final bool isSelected;
  final Widget child;
  const _SelectableRow({required this.isSelected, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? const Color(0xFFEEF2FF) : null,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: const Color(0xFF6366F1), width: 1.2)
            : null,
      ),
      child: child,
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  final double height;
  const _CardSkeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: SalaryColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SalaryColors.border),
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: SalaryColors.primary),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SalaryColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SalaryColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: SalaryText.cardTitle),
          const SizedBox(height: 8),
          Text(
            message.isEmpty ? 'Something went wrong.' : message,
            style: SalaryText.subtitle.copyWith(color: SalaryColors.deductions),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: SalaryColors.primary,
              ),
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}
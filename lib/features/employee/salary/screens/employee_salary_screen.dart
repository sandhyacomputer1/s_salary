// lib/features/employee/salary/screens/employee_salary_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/employee_salary_slip_model.dart';
import '../repositories/employee_salary_repository.dart';
import '../utils/salary_theme.dart';
import '../widgets/salary_history_card.dart';
import '../widgets/salary_structure_card.dart';
import 'employee_salary_slip_screen.dart';

class EmployeeSalaryScreen extends ConsumerWidget {
  final bool embedded;
  const EmployeeSalaryScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final structureAsync = ref.watch(salaryStructureProvider);
    final slipsAsync = ref.watch(salarySlipsProvider);

    final media = MediaQuery.of(context);
    final clamped = media.textScaler.clamp(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.15,
    );

    final body = MediaQuery(
      data: media.copyWith(textScaler: clamped),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(SalarySpacing.pagePadding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: SalarySpacing.maxContentWidth,
            ),
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
                slipsAsync.when(
                  loading: () => const _CardSkeleton(height: 280),
                  error: (e, _) => _ErrorCard(
                    title: 'My Monthly Payslips & Salary History',
                    message: _clean(e),
                    onRetry: () => ref.invalidate(salarySlipsProvider),
                  ),
                  data: (slips) => _HistorySection(
                    slips: slips,
                    onViewBreakdown: (s) => _openBreakdown(context, s),
                    onPdfPrint: (s) =>
                        _openBreakdown(context, s, autoPrint: true),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );

    if (embedded) return body;

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

  static String _clean(Object e) =>
      e.toString().replaceFirst('Exception: ', '');

  Future<void> _openBreakdown(
    BuildContext context,
    EmployeeSalarySlipModel slip, {
    bool autoPrint = false,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmployeeSalarySlipScreen(
          month: slip.month,
          year: slip.year,
          autoPrint: autoPrint,
        ),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final List<EmployeeSalarySlipModel> slips;
  final ValueChanged<EmployeeSalarySlipModel> onViewBreakdown;
  final ValueChanged<EmployeeSalarySlipModel> onPdfPrint;

  const _HistorySection({
    required this.slips,
    required this.onViewBreakdown,
    required this.onPdfPrint,
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
              SalaryHistoryCard(
                slip: slips[i],
                onViewBreakdown: () => onViewBreakdown(slips[i]),
                onPdfPrint: () => onPdfPrint(slips[i]),
              ),
              if (i != slips.length - 1) const SizedBox(height: 12),
            ],
        ],
      ),
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

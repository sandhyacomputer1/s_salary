// lib/features/employee/salary/widgets/salary_structure_card.dart

import 'package:flutter/material.dart';

import '../models/employee_salary_structure_model.dart';
import '../utils/salary_theme.dart';

class SalaryStructureCard extends StatelessWidget {
  final EmployeeSalaryStructureModel structure;

  const SalaryStructureCard({super.key, required this.structure});

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
          const Text(
            'Active Salary Package Structure',
            style: SalaryText.cardTitle,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final stacked = c.maxWidth < 720;

              final baseCell = _Tile(
                label: 'BASE MONTHLY SALARY',
                child: Text(
                  SalaryFormatters.rupees(structure.baseSalary),
                  style: SalaryText.metricValueGreen,
                ),
              );

              final effectiveCell = _Tile(
                label: 'EFFECTIVE DATE',
                child: Text(
                  SalaryFormatters.prettyDate(structure.effectiveFrom),
                  style: SalaryText.metricValue.copyWith(fontSize: 18),
                ),
              );

              final allowancesCell = _Tile(
                label: 'MONTHLY ALLOWANCES BREAKDOWN',
                child: structure.allowances.isEmpty
                    ? const Text('—', style: SalaryText.value)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final a in structure.allowances)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      a.name.isEmpty ? 'Allowance' : a.name,
                                      style: SalaryText.rowLabel,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    SalaryFormatters.rupees(a.amount),
                                    style: SalaryText.rowAmount,
                                  ),
                                ],
                              ),
                            ),
                          if (structure.allowances.length > 1) ...[
                            const Divider(height: 12),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Total allowances',
                                    style: SalaryText.rowLabel,
                                  ),
                                ),
                                Text(
                                  SalaryFormatters.rupees(
                                    structure.allowancesTotal,
                                  ),
                                  style: SalaryText.rowAmount,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    baseCell,
                    const SizedBox(height: 12),
                    effectiveCell,
                    const SizedBox(height: 12),
                    allowancesCell,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: baseCell),
                  const SizedBox(width: 12),
                  Expanded(flex: 3, child: effectiveCell),
                  const SizedBox(width: 12),
                  Expanded(flex: 4, child: allowancesCell),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final Widget child;
  const _Tile({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: SalaryColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: SalaryText.label),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

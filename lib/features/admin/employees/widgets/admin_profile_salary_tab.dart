import 'package:flutter/material.dart';

import '../models/admin_employee_model.dart';
import '../models/admin_employee_profile_models.dart';
import '../models/admin_salary_structure_model.dart';
import '../services/admin_employee_profile_service.dart';
import 'admin_employee_theme.dart';
import 'admin_profile_common.dart';

/// Current salary structure + payslip history.
class AdminProfileSalaryTab extends StatelessWidget {
  final AdminEmployeeModel employee;
  final AdminEmployeeProfileService service;

  const AdminProfileSalaryTab({super.key, required this.employee, required this.service});

  Future<(AdminSalaryStructure?, List<AdminSalarySlip>)> _load() async {
    final results = await Future.wait([
      service.getSalaryStructure(employee.id),
      service.getSalarySlips(employee.id),
    ]);
    return (results[0] as AdminSalaryStructure?, results[1] as List<AdminSalarySlip>);
  }

  @override
  Widget build(BuildContext context) {
    return AdminProfileFuture<(AdminSalaryStructure?, List<AdminSalarySlip>)>(
      load: _load,
      builder: (context, data) {
        final (structure, slips) = data;
        return Column(
          children: [
            _structureCard(structure),
            const SizedBox(height: 24),
            _slipsCard(slips),
          ],
        );
      },
    );
  }

  Widget _structureCard(AdminSalaryStructure? s) {
    return AdminProfileCard(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminProfileSectionTitle('Salary Structure'),
          const SizedBox(height: 24),
          if (s == null)
            const AdminProfileEmpty('No salary structure set yet.', icon: Icons.currency_rupee_rounded)
          else ...[
            AdminInfoGrid(
              maxColumns: 3,
              items: [
                ('BASE SALARY / MONTH', adminEmpRupees(s.baseSalary)),
                ('EFFECTIVE FROM', adminEmpFormatDate(s.effectiveFrom)),
                ('ALLOWANCES TOTAL', adminEmpRupees(s.allowancesTotal)),
              ],
            ),
            if (s.allowances.isNotEmpty) ...[
              const SizedBox(height: 22),
              const AdminProfileSmallCaps('ALLOWANCES'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final a in s.allowances)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${a.name}  ${adminEmpRupees(a.amount)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7F3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFBE3D8)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Estimated Gross / month',
                      style: TextStyle(fontSize: 13.5, color: AdminEmpColors.muted),
                    ),
                  ),
                  Text(
                    adminEmpRupees(s.gross),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AdminEmpColors.primary,
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

  Widget _slipsCard(List<AdminSalarySlip> slips) {
    return AdminProfileCard(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: AdminProfileSectionTitle('Salary Slips'),
          ),
          const SizedBox(height: 18),
          if (slips.isEmpty)
            const AdminProfileEmpty('No salary slips generated yet.')
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AdminSimpleTable(
                headers: const ['PERIOD', 'PRESENT DAYS', 'GROSS', 'NET PAY', 'STATUS'],
                flex: const [3, 2, 2, 2, 2],
                rows: [
                  for (final s in slips)
                    [
                      Text('${adminProfMonthName(s.month)} ${s.year}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${s.presentDays}'),
                      Text(adminEmpRupees(s.grossSalary)),
                      Text(adminEmpRupees(s.netSalary),
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      AdminStatusPill(s.status),
                    ],
                ],
                compactBuilder: (i) {
                  final s = slips[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AdminEmpColors.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${adminProfMonthName(s.month)} ${s.year}',
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(
                                'Gross ${adminEmpRupees(s.grossSalary)}  •  Net ${adminEmpRupees(s.netSalary)}',
                                style: const TextStyle(fontSize: 12.5, color: AdminEmpColors.muted),
                              ),
                            ],
                          ),
                        ),
                        AdminStatusPill(s.status),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
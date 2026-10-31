import 'package:flutter/material.dart';

import '../models/admin_employee_model.dart';
import '../models/admin_employee_profile_models.dart';
import 'admin_employee_theme.dart';
import 'admin_profile_common.dart';

/// Top card: avatar, name, status, code · designation · department,
/// company · email, then the 6 key details.
class AdminProfileHeaderCard extends StatelessWidget {
  final AdminEmployeeModel employee;
  final AdminProfileExtra extra;

  const AdminProfileHeaderCard({super.key, required this.employee, required this.extra});

  @override
  Widget build(BuildContext context) {
    final e = employee;
    final designation = e.designation.trim().isEmpty ? 'Staff' : e.designation;
    final company = extra.companyName.trim();

    final line1 = [
      if (e.employeeCode.isNotEmpty) e.employeeCode,
      designation,
      if (e.department.isNotEmpty) e.department,
    ].join(' · ');

    final line2 = [
      if (company.isNotEmpty) company,
      if (e.email.isNotEmpty) e.email,
    ].join(' · ');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7A1A), Color(0xFFE96832)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      // 4px accent bar on top, card below
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 26),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16), top: Radius.circular(4)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF4ED), Colors.white],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _top(line1, line2),
            const SizedBox(height: 22),
            const Divider(height: 1, color: Color(0xFFF0E4DC)),
            const SizedBox(height: 22),
            AdminInfoGrid(
              items: [
                ('EMPLOYEE CODE', adminProfOrDash(e.employeeCode)),
                ('DESIGNATION', adminProfOrDash(e.designation)),
                ('DEPARTMENT', adminProfOrDash(e.department)),
                ('EMPLOYMENT TYPE', e.employmentType.isEmpty ? '—' : e.employmentType.replaceAll('_', ' ')),
                ('DATE OF JOINING', e.joiningLabel),
                ('PHONE', adminProfOrDash(e.phone)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _top(String line1, String line2) {
    final avatar = Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF7A1A), Color(0xFFE0501E)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x33E96832), blurRadius: 12, offset: Offset(0, 5)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        employee.initials,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );

    final statusChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AdminEmpColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AdminEmpColors.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            employee.status.replaceAll('_', ' '),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AdminEmpColors.primary,
            ),
          ),
        ],
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        avatar,
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    employee.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AdminEmpColors.text,
                    ),
                  ),
                  statusChip,
                ],
              ),
              const SizedBox(height: 8),
              Text(line1, style: const TextStyle(fontSize: 14.5, color: Color(0xFF4B5563))),
              if (line2.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(line2, style: const TextStyle(fontSize: 14.5, color: Color(0xFF4B5563))),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import '../models/admin_employee_model.dart';
import 'admin_employee_actions.dart';
import 'admin_employee_status_chip.dart';
import 'admin_employee_theme.dart';
import 'admin_employee_work_mode_chip.dart';

/// Compact employee card for narrow (phone) screens.
class AdminEmployeeCard extends StatelessWidget {
  final AdminEmployeeModel employee;
  final bool archived;

  final VoidCallback onAccess;
  final VoidCallback onSalary;
  final VoidCallback onProfile;
  final VoidCallback onArchive;
  final VoidCallback onRestore;
  final VoidCallback onDeleteForever;

  const AdminEmployeeCard({
    super.key,
    required this.employee,
    required this.archived,
    required this.onAccess,
    required this.onSalary,
    required this.onProfile,
    required this.onArchive,
    required this.onRestore,
    required this.onDeleteForever,
  });

  @override
  Widget build(BuildContext context) {
    final e = employee;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminEmpColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AdminEmpColors.primarySoft,
                child: Text(
                  e.initials,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AdminEmpColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AdminEmpColors.text,
                      ),
                    ),
                    Text(
                      e.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: AdminEmpColors.muted),
                    ),
                  ],
                ),
              ),
              AdminEmployeeStatusChip(status: e.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _info('CODE', e.employeeCode)),
              Expanded(child: _info('DEPARTMENT', e.department.isEmpty ? '—' : e.department)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _info('JOINING', e.joiningLabel)),
              Expanded(child: _info('SALARY', e.salaryLabel, bold: true)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AdminEmployeeWorkModeChip(isField: e.isFieldEmployee),
              const Spacer(),
              AdminEmployeeActions(
                employee: e,
                archived: archived,
                onAccess: onAccess,
                onSalary: onSalary,
                onProfile: onProfile,
                onArchive: onArchive,
                onRestore: onRestore,
                onDeleteForever: onDeleteForever,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value, {bool bold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AdminEmpColors.muted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: AdminEmpColors.text,
          ),
        ),
      ],
    );
  }
}
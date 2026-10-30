import 'package:flutter/material.dart';
import '../models/admin_employee_model.dart';
import 'admin_employee_actions.dart';
import 'admin_employee_status_chip.dart';
import 'admin_employee_theme.dart';
import 'admin_employee_work_mode_chip.dart';

/// Desktop / web table:
/// EMPLOYEE | CODE | DEPARTMENT | WORK MODE | JOINING | STATUS | SALARY | actions
class AdminEmployeeTable extends StatelessWidget {
  final List<AdminEmployeeModel> employees;
  final bool archived;

  final void Function(AdminEmployeeModel) onAccess;
  final void Function(AdminEmployeeModel) onSalary;
  final void Function(AdminEmployeeModel) onProfile;
  final void Function(AdminEmployeeModel) onArchive;
  final void Function(AdminEmployeeModel) onRestore;
  final void Function(AdminEmployeeModel) onDeleteForever;

  const AdminEmployeeTable({
    super.key,
    required this.employees,
    required this.archived,
    required this.onAccess,
    required this.onSalary,
    required this.onProfile,
    required this.onArchive,
    required this.onRestore,
    required this.onDeleteForever,
  });

  static const double _actionsWidth = 190;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _header(),
        for (var i = 0; i < employees.length; i++) ...[
          _row(employees[i]),
          if (i != employees.length - 1)
            const Divider(height: 1, color: AdminEmpColors.border),
        ],
      ],
    );
  }

  Widget _header() {
    const style = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: AdminEmpColors.muted,
    );
    return Container(
      color: AdminEmpColors.headerBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: const Row(
        children: [
          Expanded(flex: 30, child: Text('EMPLOYEE', style: style)),
          Expanded(flex: 13, child: Text('CODE', style: style)),
          Expanded(flex: 15, child: Text('DEPARTMENT', style: style)),
          Expanded(flex: 13, child: Text('WORK MODE', style: style)),
          Expanded(flex: 14, child: Text('JOINING', style: style)),
          Expanded(flex: 12, child: Text('STATUS', style: style)),
          Expanded(flex: 12, child: Text('SALARY', style: style)),
          SizedBox(width: _actionsWidth),
        ],
      ),
    );
  }

  Widget _row(AdminEmployeeModel e) {
    const cell = TextStyle(fontSize: 14, color: AdminEmpColors.text);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 30,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AdminEmpColors.primarySoft,
                  child: Text(
                    e.initials,
                    style: const TextStyle(
                      fontSize: 12,
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
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AdminEmpColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        e.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: AdminEmpColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 13,
            child: Text(e.employeeCode, style: cell.copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 15,
            child: Text(e.department.isEmpty ? '—' : e.department, style: cell),
          ),
          Expanded(
            flex: 13,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AdminEmployeeWorkModeChip(isField: e.isFieldEmployee),
            ),
          ),
          Expanded(flex: 14, child: Text(e.joiningLabel, style: cell)),
          Expanded(
            flex: 12,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AdminEmployeeStatusChip(status: e.status),
            ),
          ),
          Expanded(
            flex: 12,
            child: Text(e.salaryLabel, style: cell.copyWith(fontWeight: FontWeight.w700)),
          ),
          SizedBox(
            width: _actionsWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: AdminEmployeeActions(
                employee: e,
                archived: archived,
                onAccess: () => onAccess(e),
                onSalary: () => onSalary(e),
                onProfile: () => onProfile(e),
                onArchive: () => onArchive(e),
                onRestore: () => onRestore(e),
                onDeleteForever: () => onDeleteForever(e),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
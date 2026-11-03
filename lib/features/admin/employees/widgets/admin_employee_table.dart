import 'package:flutter/material.dart';
import '../models/admin_employee_access.dart';
import '../models/admin_employee_model.dart';
import 'admin_employee_actions.dart';
import 'admin_employee_status_chip.dart';
import 'admin_employee_theme.dart';
import 'admin_employee_work_mode_chip.dart';

/// Desktop / web table:
/// EMPLOYEE | CODE | DEPARTMENT | WORK MODE | JOINING | STATUS | SALARY | actions
///
/// PERMISSION: [access] hides the salary column and the actions this role
/// may not use. With full access it looks exactly as before.
class AdminEmployeeTable extends StatelessWidget {
  final List<AdminEmployeeModel> employees;
  final bool archived;
  final AdminEmployeeAccess access;

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
    this.access = AdminEmployeeAccess.full,
  });

  static const double _actionsWidth = 190;

  /// Archived rows only have restore / delete, so without delete rights
  /// there is nothing to show in the actions column.
  bool get _hasActions => !archived || access.canDelete;

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
      child: Row(
        children: [
          const Expanded(flex: 30, child: Text('EMPLOYEE', style: style)),
          const Expanded(flex: 13, child: Text('CODE', style: style)),
          const Expanded(flex: 15, child: Text('DEPARTMENT', style: style)),
          const Expanded(flex: 13, child: Text('WORK MODE', style: style)),
          const Expanded(flex: 14, child: Text('JOINING', style: style)),
          const Expanded(flex: 12, child: Text('STATUS', style: style)),
          if (access.canSeeSalary)
            const Expanded(flex: 12, child: Text('SALARY', style: style)),
          if (_hasActions) const SizedBox(width: _actionsWidth),
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
          if (access.canSeeSalary)
            Expanded(
              flex: 12,
              child: Text(e.salaryLabel, style: cell.copyWith(fontWeight: FontWeight.w700)),
            ),
          if (_hasActions)
            SizedBox(
              width: _actionsWidth,
              child: Align(
                alignment: Alignment.centerRight,
                child: _actions(e),
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // actions
  // ------------------------------------------------------------

  Widget _actions(AdminEmployeeModel e) {
    // full access: the original action buttons, unchanged
    if (access.isFull) {
      return AdminEmployeeActions(
        employee: e,
        archived: archived,
        onAccess: () => onAccess(e),
        onSalary: () => onSalary(e),
        onProfile: () => onProfile(e),
        onArchive: () => onArchive(e),
        onRestore: () => onRestore(e),
        onDeleteForever: () => onDeleteForever(e),
      );
    }

    // limited access: only the buttons this role may use
    final buttons = <Widget>[];

    if (archived) {
      if (access.canDelete) {
        buttons.add(_iconButton(Icons.restore_rounded, 'Restore', () => onRestore(e)));
        buttons.add(_iconButton(Icons.delete_forever_outlined, 'Delete permanently',
                () => onDeleteForever(e), danger: true));
      }
    } else {
      if (access.canEdit) {
        buttons.add(_iconButton(Icons.lock_outline_rounded, 'Access & credentials',
                () => onAccess(e)));
      }
      if (access.canManageSalary) {
        buttons.add(_iconButton(Icons.currency_rupee_rounded, 'Set salary',
                () => onSalary(e)));
      }
      buttons.add(_iconButton(Icons.person_outline_rounded, 'View profile',
              () => onProfile(e)));
      if (access.canDelete) {
        buttons.add(_iconButton(Icons.delete_outline_rounded, 'Archive',
                () => onArchive(e), danger: true));
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          buttons[i],
        ],
      ],
    );
  }

  Widget _iconButton(
      IconData icon,
      String tooltip,
      VoidCallback onTap, {
        bool danger = false,
      }) {
    final color = danger ? AdminEmpColors.danger : AdminEmpColors.text;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AdminEmpColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 19, color: color),
          ),
        ),
      ),
    );
  }
}
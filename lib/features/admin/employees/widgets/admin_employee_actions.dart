import 'package:flutter/material.dart';
import '../models/admin_employee_model.dart';
import 'admin_employee_theme.dart';

/// Row action icons.
/// Active  : lock (access) | rupee (salary) | person (profile) | trash (archive)
/// Archive : restore | delete forever
class AdminEmployeeActions extends StatelessWidget {
  final AdminEmployeeModel employee;
  final bool archived;

  final VoidCallback? onAccess;
  final VoidCallback? onSalary;
  final VoidCallback? onProfile;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;
  final VoidCallback? onDeleteForever;

  const AdminEmployeeActions({
    super.key,
    required this.employee,
    this.archived = false,
    this.onAccess,
    this.onSalary,
    this.onProfile,
    this.onArchive,
    this.onRestore,
    this.onDeleteForever,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = archived
        ? <Widget>[
      _IconBtn(icon: Icons.restore_rounded, tooltip: 'Restore', onTap: onRestore),
      _IconBtn(
        icon: Icons.delete_forever_outlined,
        tooltip: 'Delete permanently',
        danger: true,
        onTap: onDeleteForever,
      ),
    ]
        : <Widget>[
      _IconBtn(icon: Icons.lock_outline_rounded, tooltip: 'Access', onTap: onAccess),
      _IconBtn(icon: Icons.currency_rupee_rounded, tooltip: 'Salary', onTap: onSalary),
      _IconBtn(icon: Icons.person_outline_rounded, tooltip: 'Profile', onTap: onProfile),
      _IconBtn(
        icon: Icons.delete_outline_rounded,
        tooltip: 'Archive',
        danger: true,
        onTap: onArchive,
      ),
    ];

    return Wrap(spacing: 8, runSpacing: 8, children: buttons);
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool danger;
  final VoidCallback? onTap;

  const _IconBtn({
    required this.icon,
    required this.tooltip,
    this.danger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AdminEmpColors.danger : AdminEmpColors.text;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AdminEmpColors.border),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }
}
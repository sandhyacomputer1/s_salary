import 'package:flutter/material.dart';

import '../models/admin_employee_access.dart';
import '../models/admin_employee_model.dart';
import 'admin_employee_status_chip.dart';
import 'admin_employee_theme.dart';

/// Compact employee row for phones (Android / iOS).
///
///  [R]  rahul                         ₹2,00,000
///       EMP-0006 · Accounts          ● active    ⋮
///
/// Only the key info is shown. Everything else is in the profile, and the
/// actions are inside the ⋮ menu.
///
/// PERMISSION: [access] hides the salary and the menu actions this role may
/// not use. With full access it looks exactly as before.
class AdminEmployeeCard extends StatelessWidget {
  final AdminEmployeeModel employee;
  final bool archived;
  final AdminEmployeeAccess access;

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
    this.access = AdminEmployeeAccess.full,
  });

  @override
  Widget build(BuildContext context) {
    final e = employee;
    final sub = [
      if (e.employeeCode.isNotEmpty) e.employeeCode,
      if (e.department.isNotEmpty) e.department,
    ].join(' · ');

    final items = _menuItems();
    final hasMenu = items.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminEmpColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: archived ? null : onProfile,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 11, hasMenu ? 2 : 12, 11),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: AdminEmpColors.primarySoft,
                  child: Text(
                    e.initials,
                    style: const TextStyle(
                      fontSize: 12.5,
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
                          fontWeight: FontWeight.w700,
                          color: AdminEmpColors.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AdminEmpColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (access.canSeeSalary) ...[
                      Text(
                        e.salaryLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AdminEmpColors.text,
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                    AdminEmployeeStatusChip(status: e.status),
                  ],
                ),
                if (hasMenu) _menu(items),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _item(String value, IconData icon, String label, {bool danger = false}) {
    final color = danger ? AdminEmpColors.danger : AdminEmpColors.text;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  /// PERMISSION: only the actions this role may use.
  List<PopupMenuEntry<String>> _menuItems() {
    if (archived) {
      if (!access.canDelete) return const [];
      return [
        _item('restore', Icons.restore_rounded, 'Restore'),
        _item('delete', Icons.delete_forever_outlined, 'Delete permanently', danger: true),
      ];
    }

    return [
      _item('profile', Icons.person_outline_rounded, 'View profile'),
      if (access.canEdit)
        _item('access', Icons.lock_outline_rounded, 'Access & credentials'),
      if (access.canManageSalary)
        _item('salary', Icons.currency_rupee_rounded, 'Set salary'),
      if (access.canDelete) ...[
        const PopupMenuDivider(),
        _item('archive', Icons.delete_outline_rounded, 'Archive', danger: true),
      ],
    ];
  }

  Widget _menu(List<PopupMenuEntry<String>> items) {
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      padding: EdgeInsets.zero,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      icon: const Icon(Icons.more_vert_rounded, size: 21, color: AdminEmpColors.muted),
      onSelected: (v) {
        switch (v) {
          case 'profile':
            onProfile();
            break;
          case 'access':
            onAccess();
            break;
          case 'salary':
            onSalary();
            break;
          case 'archive':
            onArchive();
            break;
          case 'restore':
            onRestore();
            break;
          case 'delete':
            onDeleteForever();
            break;
        }
      },
      itemBuilder: (_) => items,
    );
  }
}
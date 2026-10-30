import 'package:flutter/material.dart';
import 'admin_employee_theme.dart';

/// Small pill: "• active", "• on_leave", "• terminated".
class AdminEmployeeStatusChip extends StatelessWidget {
  final String status;
  const AdminEmployeeStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color fg;
    Color bg;
    switch (status) {
      case 'active':
        fg = AdminEmpColors.primary;
        bg = AdminEmpColors.primarySoft;
        break;
      case 'on_leave':
        fg = const Color(0xFFB45309);
        bg = const Color(0xFFFFFBEB);
        break;
      default:
        fg = AdminEmpColors.danger;
        bg = AdminEmpColors.dangerSoft;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.replaceAll('_', ' '),
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}
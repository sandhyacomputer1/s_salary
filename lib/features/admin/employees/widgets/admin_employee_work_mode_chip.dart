import 'package:flutter/material.dart';
import 'admin_employee_theme.dart';

/// "In-House" / "Field" badge.
class AdminEmployeeWorkModeChip extends StatelessWidget {
  final bool isField;
  const AdminEmployeeWorkModeChip({super.key, required this.isField});

  @override
  Widget build(BuildContext context) {
    final fg = isField ? AdminEmpColors.green : AdminEmpColors.text;
    final bg = isField ? AdminEmpColors.greenSoft : const Color(0xFFEEF2F7);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        isField ? 'Field' : 'In-House',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'admin_employee_theme.dart';

/// Overview | Attendance & Logs | Personal | Leave | Salary | Expenses
class AdminProfileTabBar extends StatelessWidget {
  static const List<String> tabs = [
    'Overview',
    'Attendance & Logs',
    'Personal',
    'Leave',
    'Salary',
    'Expenses',
  ];

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const AdminProfileTabBar({super.key, required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            _tab(i),
            if (i != tabs.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _tab(int i) {
    final selected = i == selectedIndex;
    return InkWell(
      onTap: () => onChanged(i),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        decoration: BoxDecoration(
          color: selected ? AdminEmpColors.primarySoft : Colors.transparent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          border: Border(
            bottom: BorderSide(
              color: selected ? AdminEmpColors.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          tabs[i],
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            color: selected ? AdminEmpColors.primary : AdminEmpColors.text,
          ),
        ),
      ),
    );
  }
}
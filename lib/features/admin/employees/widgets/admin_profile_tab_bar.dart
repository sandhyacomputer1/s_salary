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
    // Determine if we are on a small screen
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            _tab(i, isMobile),
            if (i != tabs.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _tab(int i, bool isMobile) {
    final selected = i == selectedIndex;

    // Compact padding and font size for mobile
    final horizontalPadding = isMobile ? 14.0 : 22.0;
    final verticalPadding = isMobile ? 12.0 : 15.0;
    final fontSize = isMobile ? 14.0 : 15.5;

    return InkWell(
      onTap: () => onChanged(i),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
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
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: selected ? AdminEmpColors.primary : AdminEmpColors.text,
          ),
        ),
      ),
    );
  }
}
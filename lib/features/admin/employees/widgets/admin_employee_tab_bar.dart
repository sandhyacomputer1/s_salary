import 'package:flutter/material.dart';
import 'admin_employee_theme.dart';

/// "Active Employees (3)" | "Archive (0)" tabs.
class AdminEmployeeTabBar extends StatelessWidget {
  final int selectedIndex;
  final int activeCount;
  final int archiveCount;
  final ValueChanged<int> onChanged;

  const AdminEmployeeTabBar({
    super.key,
    required this.selectedIndex,
    required this.activeCount,
    required this.archiveCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Tab(
            label: 'Active Employees ($activeCount)',
            selected: selectedIndex == 0,
            onTap: () => onChanged(0),
          ),
          const SizedBox(width: 8),
          _Tab(
            label: 'Archive ($archiveCount)',
            selected: selectedIndex == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: selected ? AdminEmpColors.primary : AdminEmpColors.text,
          ),
        ),
      ),
    );
  }
}
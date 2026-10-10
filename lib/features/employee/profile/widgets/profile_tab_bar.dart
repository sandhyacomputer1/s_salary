// lib/features/employee/profile/widgets/profile_tab_bar.dart

import 'package:flutter/material.dart';

import '../utils/profile_colors.dart';

class ProfileTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const ProfileTabBar({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  static const _labels = [
    'Personal & Emergency Details',
    'Bank Account & IFSC Details',
    'Employment Details',
    'Expense Claims',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ProfileColors.border),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < _labels.length; i++)
              _Tab(
                label: _labels[i],
                selected: i == selectedIndex,
                onTap: () => onChanged(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected
                      ? ProfileColors.primary
                      : ProfileColors.textMedium,
                ),
              ),
            ),
            Container(
              height: 2.5,
              width: selected ? null : 0,
              color: ProfileColors.primary,
              padding: selected
                  ? const EdgeInsets.symmetric(horizontal: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
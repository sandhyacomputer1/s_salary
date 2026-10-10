// lib/features/employee/attendance/widgets/attendance_month_header.dart

import 'package:flutter/material.dart';

import '../utils/attendance_theme.dart';

class AttendanceMonthHeader extends StatelessWidget {
  final int month;
  final int year;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const AttendanceMonthHeader({
    super.key,
    required this.month,
    required this.year,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AttendanceColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AttendanceColors.border),
      ),
      child: Row(
        children: [
          _ArrowButton(
            icon: Icons.chevron_left_rounded,
            onTap: onPrev,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AttendanceFormatters.monthYear(month, year),
                  style: AttendanceText.monthLabel,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ArrowButton(
            icon: Icons.chevron_right_rounded,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AttendanceColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AttendanceColors.border),
        ),
        child: Icon(icon, size: 18, color: AttendanceColors.textDark),
      ),
    );
  }
}
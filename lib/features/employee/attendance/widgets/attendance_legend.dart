// lib/features/employee/attendance/widgets/attendance_legend.dart

import 'package:flutter/material.dart';

import '../utils/attendance_theme.dart';

class AttendanceLegend extends StatelessWidget {
  const AttendanceLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 10,
      children: [
        for (final s in AttendanceStatuses.all)
          _LegendItem(
            color: s.solid,
            label: '${s.label} (${s.code})',
          ),
        const _LegendItem(
          color: AttendanceColors.primary,
          label: 'Today',
          ring: true,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool ring;

  const _LegendItem({
    required this.color,
    required this.label,
    this.ring = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: ring ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(4),
            border: ring ? Border.all(color: color, width: 2) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AttendanceColors.textMedium,
          ),
        ),
      ],
    );
  }
}
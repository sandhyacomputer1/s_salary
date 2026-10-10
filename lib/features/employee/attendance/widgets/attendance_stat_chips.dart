// lib/features/employee/attendance/widgets/attendance_stat_chips.dart

import 'package:flutter/material.dart';

import '../models/attendance_summary_model.dart';
import '../utils/attendance_theme.dart';

class AttendanceStatChips extends StatelessWidget {
  final AttendanceSummaryModel summary;

  const AttendanceStatChips({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final chips = <_Chip>[
      _Chip('Present', summary.present, AttendanceColors.present),
      _Chip('Late', summary.late, AttendanceColors.late),
      _Chip('Absent', summary.absent, AttendanceColors.absent),
      _Chip('Leaves', summary.onLeave, AttendanceColors.leave),
      _Chip('Holidays', summary.holiday + summary.weekOff,
          AttendanceColors.holiday),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth;
        final perRow = width < 420
            ? 2
            : width < 720
            ? 3
            : 5;
        const spacing = 12.0;
        final cellWidth = (width - spacing * (perRow - 1)) / perRow;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final chip in chips)
              SizedBox(
                width: cellWidth,
                child: _ChipCard(chip: chip),
              ),
          ],
        );
      },
    );
  }
}

class _Chip {
  final String label;
  final int value;
  final Color dotColor;
  const _Chip(this.label, this.value, this.dotColor);
}

class _ChipCard extends StatelessWidget {
  final _Chip chip;
  const _ChipCard({required this.chip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AttendanceColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AttendanceColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: chip.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              chip.label,
              style: AttendanceText.chipLabel,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text('${chip.value}', style: AttendanceText.chipValue),
        ],
      ),
    );
  }
}
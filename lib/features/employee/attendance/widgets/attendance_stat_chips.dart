// lib/features/employee/attendance/widgets/attendance_stat_chips.dart

import 'package:flutter/material.dart';

import '../models/attendance_summary_model.dart';
import '../utils/attendance_theme.dart';

/// Present / Late / Absent / Leaves / Holidays  (dot + label + count),
/// same as the web page.
class AttendanceStatChips extends StatelessWidget {
  final AttendanceSummaryModel summary;

  const AttendanceStatChips({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final chips = <_Chip>[
      _Chip('Present', summary.present, AttendanceStatuses.present.solid),
      _Chip('Late', summary.late, AttendanceStatuses.late.solid),
      _Chip('Absent', summary.absent, AttendanceStatuses.absent.solid),
      _Chip('Leaves', summary.onLeave, AttendanceStatuses.leave.solid),
      _Chip('Holidays', summary.holiday, AttendanceStatuses.holiday.solid),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth;
        final perRow = width < 440
            ? 2
            : width < 720
            ? 3
            : 5;
        const spacing = 12.0;
        final cellWidth = ((width - spacing * (perRow - 1)) / perRow)
            .floorToDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final chip in chips)
              SizedBox(width: cellWidth, child: _ChipCard(chip: chip)),
          ],
        );
      },
    );
  }
}

class _Chip {
  final String label;
  final int value;
  final Color dot;
  const _Chip(this.label, this.value, this.dot);
}

class _ChipCard extends StatelessWidget {
  final _Chip chip;
  const _ChipCard({required this.chip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AttendanceColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AttendanceColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: chip.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              chip.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AttendanceColors.textMedium,
              ),
            ),
          ),
          Text(
            '${chip.value}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AttendanceColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
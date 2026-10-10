// lib/features/employee/attendance/widgets/attendance_calendar_grid.dart

import 'package:flutter/material.dart';

import '../models/attendance_day_model.dart';
import '../utils/attendance_theme.dart';
import 'attendance_day_cell.dart';

class AttendanceCalendarGrid extends StatelessWidget {
  final int month;
  final int year;
  final List<AttendanceDayModel> records;

  const AttendanceCalendarGrid({
    super.key,
    required this.month,
    required this.year,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    // Build a lookup: "YYYY-MM-DD" -> record
    final byDate = <String, AttendanceDayModel>{
      for (final r in records) r.date: r,
    };

    final daysCount = AttendanceFormatters.daysInMonth(month, year);
    final firstWeekday = AttendanceFormatters.weekdayOf(1, month, year); // 1..7
    final leadingBlanks = firstWeekday - 1; // Mon = 0 blanks

    final today = DateTime.now();
    final isCurrentMonth = today.month == month && today.year == year;

    // Total cells = leading blanks + days, rounded up to full weeks.
    final totalCells = ((leadingBlanks + daysCount + 6) ~/ 7) * 7;

    return LayoutBuilder(
      builder: (context, c) {
        // Responsive cell size — aim for 7 columns, drop to fewer on very
        // narrow screens so cells stay legible.
        final width = c.maxWidth;
        final minCellWidth = width < 500 ? 44.0 : 80.0;
        final cols = (width / minCellWidth).floor().clamp(1, 7);
        const gap = 8.0;
        final cellWidth = (width - gap * (cols - 1)) / cols;

        // Header row of weekday names always 7 across (scrollable if needed).
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekday header
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: cellWidth * 7 + gap * 6,
                child: Row(
                  children: [
                    for (var i = 0; i < 7; i++) ...[
                      SizedBox(
                        width: cellWidth,
                        child: Center(
                          child: Text(
                            AttendanceFormatters.weekdayShort[i],
                            style: AttendanceText.weekday,
                          ),
                        ),
                      ),
                      if (i != 6) const SizedBox(width: gap),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Grid
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: cellWidth * 7 + gap * 6,
                child: Column(
                  children: [
                    for (var row = 0; row < totalCells / 7; row++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: gap),
                        child: Row(
                          children: [
                            for (var col = 0; col < 7; col++) ...[
                              _buildCell(
                                index: row * 7 + col,
                                leadingBlanks: leadingBlanks,
                                daysCount: daysCount,
                                cellWidth: cellWidth,
                                byDate: byDate,
                                isCurrentMonth: isCurrentMonth,
                                today: today,
                              ),
                              if (col != 6) const SizedBox(width: gap),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCell({
    required int index,
    required int leadingBlanks,
    required int daysCount,
    required double cellWidth,
    required Map<String, AttendanceDayModel> byDate,
    required bool isCurrentMonth,
    required DateTime today,
  }) {
    final dayNumber = index - leadingBlanks + 1;
    final inRange = dayNumber >= 1 && dayNumber <= daysCount;

    if (!inRange) {
      return SizedBox(
        width: cellWidth,
        height: 68,
        child: const SizedBox.shrink(),
      );
    }

    final iso = AttendanceFormatters.isoDate(dayNumber, month, year);
    final record = byDate[iso];
    final isToday = isCurrentMonth && today.day == dayNumber;

    return SizedBox(
      width: cellWidth,
      height: 68,
      child: AttendanceDayCell(
        day: dayNumber,
        isoDate: iso,
        record: record,
        isToday: isToday,
      ),
    );
  }
}
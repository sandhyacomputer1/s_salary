// lib/features/employee/attendance/widgets/attendance_calendar_grid.dart

import 'package:flutter/material.dart';

import '../utils/attendance_resolver.dart';
import '../utils/attendance_theme.dart';
import 'attendance_day_cell.dart';
import 'attendance_day_details_sheet.dart';

/// Always 7 equal columns (MON..SUN) - no horizontal scrolling.
/// Days of the previous / next month are shown faded (like the web).
class AttendanceCalendarGrid extends StatelessWidget {
  final int month;
  final int year;
  final List<AttendanceDayInfo> days; // resolved days of this month

  /// true  -> the grid stretches to the height it is given, so the whole
  ///          month fits the screen (needs a bounded height, e.g. Expanded).
  /// false -> fixed cell height (the page scrolls).
  final bool fillHeight;

  const AttendanceCalendarGrid({
    super.key,
    required this.month,
    required this.year,
    required this.days,
    this.fillHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    final daysCount = AttendanceFormatters.daysInMonth(month, year);
    final leadingBlanks = AttendanceFormatters.weekdayOf(1, month, year) - 1;
    final totalCells = ((leadingBlanks + daysCount + 6) ~/ 7) * 7;
    final rows = totalCells ~/ 7;

    final prevMonthDays = AttendanceFormatters.daysInMonth(
      month == 1 ? 12 : month - 1,
      month == 1 ? year - 1 : year,
    );

    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < 560;
        final gap = compact ? 5.0 : 10.0;

        Widget cellAt(int index) {
          final dayNumber = index - leadingBlanks + 1;

          // previous month (faded)
          if (dayNumber < 1) {
            return AttendanceOutsideCell(
              day: prevMonthDays + dayNumber,
              compact: compact,
            );
          }

          // next month (faded)
          if (dayNumber > daysCount) {
            return AttendanceOutsideCell(
              day: dayNumber - daysCount,
              compact: compact,
            );
          }

          final info = days[dayNumber - 1];

          return AttendanceDayCell(
            info: info,
            compact: compact,
            onTap: () => showAttendanceDayDetails(context, info: info),
          );
        }

        Widget gridWith(double extent, {required bool scrollable}) {
          return GridView.builder(
            shrinkWrap: !fillHeight,
            physics: scrollable
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: totalCells,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: gap,
              crossAxisSpacing: gap,
              mainAxisExtent: extent,
            ),
            itemBuilder: (context, index) => cellAt(index),
          );
        }

        final header = Row(
          children: [
            for (var i = 0; i < 7; i++) ...[
              Expanded(
                child: Center(
                  child: Text(
                    AttendanceFormatters.weekdayShort[i],
                    style: AttendanceText.weekday.copyWith(
                      fontSize: compact ? 10 : 12,
                      color: AttendanceColors.fieldLabel,
                    ),
                  ),
                ),
              ),
              if (i != 6) SizedBox(width: gap),
            ],
          ],
        );

        // ---------- fit-to-screen mode ----------
        if (fillHeight && c.maxHeight.isFinite) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 10),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, cc) {
                    final raw = (cc.maxHeight - gap * (rows - 1)) / rows;
                    final extent = raw.floorToDouble().clamp(48.0, 108.0);
                    final needsScroll =
                        extent * rows + gap * (rows - 1) > cc.maxHeight + 0.5;
                    return gridWith(extent, scrollable: needsScroll);
                  },
                ),
              ),
            ],
          );
        }

        // ---------- normal (scrolling page) mode ----------
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 10),
            gridWith(compact ? 56.0 : 98.0, scrollable: false),
          ],
        );
      },
    );
  }
}
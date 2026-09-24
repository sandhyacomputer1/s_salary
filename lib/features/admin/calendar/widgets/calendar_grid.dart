import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import 'calendar_event_card.dart';

// =================================================================
// CALENDAR GRID
//
// Monday–Sunday weekday header row + a monthly date grid.
// Leading/trailing days from the adjacent months are shown muted
// so the grid always fills complete weeks, but they are not the
// focus — tapping one simply moves to that month and selects it.
// =================================================================

class CalendarGrid extends StatelessWidget {
  static const Color primary = Color(0xFFE96832);
  static const Color textDark = Color(0xFF18212F);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color muted = Color(0xFFC7CDD6);
  static const Color border = Color(0xFFE5E7EB);
  static const Color todayBg = Color(0xFFFFF1EB);

  final DateTime displayedMonth;
  final DateTime selectedDate;
  final DateTime today;
  final Map<DateTime, List<CalendarEvent>> eventsByDay;
  final ValueChanged<DateTime> onDateSelected;

  const CalendarGrid({
    super.key,
    required this.displayedMonth,
    required this.selectedDate,
    required this.today,
    required this.eventsByDay,
    required this.onDateSelected,
  });

  static const List<String> _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  DateTime _dayKey(DateTime date) => DateTime(date.year, date.month, date.day);

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _daysInMonth(DateTime month) {
    final firstOfNextMonth = DateTime(month.year, month.month + 1, 1);
    return firstOfNextMonth.subtract(const Duration(days: 1)).day;
  }

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(displayedMonth.year, displayedMonth.month, 1);

    // DateTime.weekday: Monday = 1 ... Sunday = 7.
    // Number of muted lead-in cells before day 1 falls on the grid.
    final leadingBlanks = firstOfMonth.weekday - 1;

    final daysInMonth = _daysInMonth(displayedMonth);

    final totalCells = ((leadingBlanks + daysInMonth) / 7).ceil() * 7;

    final cellDates = List<DateTime>.generate(totalCells, (index) {
      final dayOffset = index - leadingBlanks;
      return DateTime(displayedMonth.year, displayedMonth.month, 1 + dayOffset);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: _weekdayLabels
              .map(
                (label) => Expanded(
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: textLight,
                  ),
                ),
              ),
            ),
          )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cellDates.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final date = cellDates[index];

            final inCurrentMonth = date.month == displayedMonth.month;

            final isToday = _isSameDay(date, today);

            final isSelected = _isSameDay(date, selectedDate);

            final dayEvents = eventsByDay[_dayKey(date)] ?? const [];

            return _DateCell(
              date: date,
              inCurrentMonth: inCurrentMonth,
              isToday: isToday,
              isSelected: isSelected,
              events: dayEvents,
              onTap: () => onDateSelected(date),
            );
          },
        ),
      ],
    );
  }
}

class _DateCell extends StatelessWidget {
  final DateTime date;
  final bool inCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final List<CalendarEvent> events;
  final VoidCallback onTap;

  const _DateCell({
    required this.date,
    required this.inCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.events,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color background = Colors.white;
    Color textColor = CalendarGrid.textDark;
    Border? border = Border.all(color: CalendarGrid.border);
    FontWeight fontWeight = FontWeight.w600;

    if (!inCurrentMonth) {
      textColor = CalendarGrid.muted;
      background = const Color(0xFFFBFBFC);
    }

    if (isToday && !isSelected) {
      background = CalendarGrid.todayBg;
      border = Border.all(color: CalendarGrid.primary, width: 1.3);
      textColor = CalendarGrid.primary;
      fontWeight = FontWeight.w700;
    }

    if (isSelected) {
      background = CalendarGrid.primary;
      border = Border.all(color: CalendarGrid.primary);
      textColor = Colors.white;
      fontWeight = FontWeight.w700;
    }

    // Up to 3 small dots, one per distinct event type on this day.
    final dotColors = events
        .map((event) => CalendarEventTypeStyle.of(event.type).color)
        .toSet()
        .take(3)
        .toList();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: border,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: fontWeight,
                color: textColor,
              ),
            ),
            if (dotColors.isNotEmpty) ...[
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: dotColors
                    .map(
                      (color) => Container(
                    width: 4.5,
                    height: 4.5,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : color,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../widgets/calendar_event_card.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/calendar_header.dart';
import '../../../../data/services/calendar_service.dart';
// =================================================================
// ADMIN CALENDAR SCREEN
//
// Monthly calendar for the Admin Dashboard. Shows attendance,
// leave, holiday and shift events (once wired to real services)
// for a selected date, next to or below the calendar depending
// on screen width.
//
// This screen does NOT call any API yet — see _loadEventsForMonth
// below for exactly where to plug that in once the relevant
// services (attendance / leave / shift / holiday) are available.
// =================================================================

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // ==========================================================
  // BREAKPOINTS
  // ==========================================================
  final CalendarService _calendarService =
  CalendarService();
  static const double _mobileBreakpoint = 700;
  static const double _sideBySideBreakpoint = 900;

  bool get _isMobile => MediaQuery.of(context).size.width < _mobileBreakpoint;

  // ==========================================================
  // COLORS — same palette used across the S Salary admin screens
  // ==========================================================

  static const Color _primary = Color(0xFFE96832);
  static const Color _primaryLight = Color(0xFFFFF1EB);
  static const Color _textDark = Color(0xFF18212F);
  static const Color _textMedium = Color(0xFF4B5563);
  static const Color _textLight = Color(0xFF8A93A1);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _pageBg = Color(0xFFF7F8FA);

  // ==========================================================
  // STATE
  // ==========================================================

  late DateTime _today;
  late DateTime _displayedMonth;
  late DateTime _selectedDate;

  /// Events for the currently displayed month. Empty until this
  /// is wired to real services — see _loadEventsForMonth().
  List<CalendarEvent> _events = [];

  bool _isLoadingEvents = false;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _today = DateTime(now.year, now.month, now.day);
    _displayedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = _today;

    _loadEventsForMonth(_displayedMonth);
  }

  // ==========================================================
  // LOAD EVENTS
  //
  // Deliberately empty for now — no endpoints have been given
  // for attendance / leave / shift / holiday data. Wire it up
  // like this once those services exist:
  //
  //   final results = await Future.wait([
  //     _attendanceService.getMonthlyAttendance(month: _displayedMonth),
  //     _leaveService.getMonthlyLeaves(month: _displayedMonth),
  //     _shiftService.getMonthlyShifts(month: _displayedMonth),
  //     _holidayService.getHolidays(month: _displayedMonth),
  //   ]);
  //
  //   final merged = <CalendarEvent>[
  //     ...(results[0] as List).map((json) => CalendarEvent.fromJson(json)),
  //     ...(results[1] as List).map((json) => CalendarEvent.fromJson(json)),
  //     ...(results[2] as List).map((json) => CalendarEvent.fromJson(json)),
  //     ...(results[3] as List).map((json) => CalendarEvent.fromJson(json)),
  //   ];
  //
  //   setState(() => _events = merged);
  // ==========================================================

  Future<void> _loadEventsForMonth(
      DateTime month,
      ) async {
    if (!mounted) return;

    setState(() {
      _isLoadingEvents = true;
    });

    try {
      final events =
      await _calendarService.getMonthlyEvents(
        month: month,
      );

      if (!mounted) return;

      setState(() {
        _events = events;
        _isLoadingEvents = false;
      });
    } catch (e) {
      debugPrint(
        'CALENDAR LOAD ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _events = [];
        _isLoadingEvents = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load calendar events: '
                '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }
  // ==========================================================
  // NAVIGATION
  // ==========================================================

  void _goToPreviousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
        1,
      );
    });

    _loadEventsForMonth(_displayedMonth);
  }

  void _goToNextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
        1,
      );
    });

    _loadEventsForMonth(_displayedMonth);
  }

  void _goToToday() {
    final monthChanged = _displayedMonth.year != _today.year ||
        _displayedMonth.month != _today.month;

    setState(() {
      _displayedMonth = DateTime(_today.year, _today.month, 1);
      _selectedDate = _today;
    });

    if (monthChanged) {
      _loadEventsForMonth(_displayedMonth);
    }
  }

  void _onDateSelected(DateTime date) {
    final monthChanged =
        date.month != _displayedMonth.month || date.year != _displayedMonth.year;

    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);

      if (monthChanged) {
        _displayedMonth = DateTime(date.year, date.month, 1);
      }
    });

    if (monthChanged) {
      _loadEventsForMonth(_displayedMonth);
    }
  }

  // ==========================================================
  // DERIVED DATA
  // ==========================================================

  Map<DateTime, List<CalendarEvent>> get _eventsByDay {
    final map = <DateTime, List<CalendarEvent>>{};

    for (final event in _events) {
      final key = DateTime(event.date.year, event.date.month, event.date.day);
      map.putIfAbsent(key, () => []).add(event);
    }

    return map;
  }

  List<CalendarEvent> get _selectedDateEvents {
    return _events.where((event) => event.isOnSameDayAs(_selectedDate)).toList()
      ..sort((a, b) => (a.startTime ?? '').compareTo(b.startTime ?? ''));
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobile;

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildPageHeader(mobile),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  mobile ? 14 : 24,
                  mobile ? 16 : 22,
                  mobile ? 14 : 24,
                  24,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final sideBySide = constraints.maxWidth >= _sideBySideBreakpoint;

                    final calendarCard = _buildCalendarCard(mobile);
                    final eventsCard = _buildEventsPanel(mobile);

                    if (sideBySide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: calendarCard),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: eventsCard),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        calendarCard,
                        const SizedBox(height: 16),
                        eventsCard,
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // PAGE HEADER — same shape as the other admin screens
  // ==========================================================

  Widget _buildPageHeader(bool mobile) {
    return Container(
      width: double.infinity,
      height: 62,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: _border),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: mobile ? 6 : 16),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(
                Icons.arrow_back_rounded,
                size: 21,
                color: _textDark,
              ),
            ),
            const SizedBox(width: 2),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                color: _primary,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calendar',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Attendance, leaves, shifts and holidays.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: _textLight,
                    ),
                  ),
                ],
              ),
            ),
            if (!mobile)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _pageBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 16,
                      color: _textMedium,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _textMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // CALENDAR CARD
  // ==========================================================

  Widget _buildCalendarCard(bool mobile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(mobile ? 14 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CalendarHeader(
              displayedMonth: _displayedMonth,
              compact: mobile,
              onPreviousMonth: _goToPreviousMonth,
              onNextMonth: _goToNextMonth,
              onToday: _goToToday,
            ),
            SizedBox(height: mobile ? 16 : 20),
            CalendarGrid(
              displayedMonth: _displayedMonth,
              selectedDate: _selectedDate,
              today: _today,
              eventsByDay: _eventsByDay,
              onDateSelected: _onDateSelected,
            ),
            const SizedBox(height: 14),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    final types = [
      CalendarEventType.attendance,
      CalendarEventType.leave,
      CalendarEventType.holiday,
      CalendarEventType.shift,
    ];

    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: types.map((type) {
        final color = CalendarEventTypeStyle.of(type).color;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              type.label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _textMedium,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ==========================================================
  // EVENTS PANEL (for the selected date)
  // ==========================================================

  static const List<String> _weekdayFullNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _monthFullNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String get _selectedDateLabel {
    final weekday = _weekdayFullNames[_selectedDate.weekday - 1];
    final month = _monthFullNames[_selectedDate.month - 1];

    return '$weekday, ${_selectedDate.day} $month ${_selectedDate.year}';
  }

  Widget _buildEventsPanel(bool mobile) {
    final isToday = _selectedDate.year == _today.year &&
        _selectedDate.month == _today.month &&
        _selectedDate.day == _today.day;

    final events = _selectedDateEvents;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(mobile ? 14 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedDateLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isToday ? 'Today' : 'Selected date',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoadingEvents)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFE9ECF0)),
            const SizedBox(height: 14),
            if (events.isEmpty)
              _buildEmptyEventsState()
            else
              Column(
                children: [
                  for (var i = 0; i < events.length; i++) ...[
                    CalendarEventCard(event: events[i]),
                    if (i != events.length - 1) const SizedBox(height: 10),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyEventsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.event_available_outlined,
              size: 26,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No events for this date',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: _textMedium,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Attendance, leaves, shifts and holidays will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
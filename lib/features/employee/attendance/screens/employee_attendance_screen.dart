// lib/features/employee/attendance/screens/employee_attendance_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/attendance_repository.dart';
import '../utils/attendance_resolver.dart';
import '../utils/attendance_theme.dart';
import '../widgets/attendance_calendar_grid.dart';
import '../widgets/attendance_legend.dart';
import '../widgets/attendance_month_header.dart';
import '../widgets/attendance_stat_chips.dart';

/// Page padding that follows the real width of the area, so the screen
/// fits when the sidebar is open, hidden, or on a phone.
double _pagePadFor(double width) {
  if (width < 420) return 10;
  if (width < 700) return 14;
  if (width < 1000) return 18;
  return AttendanceSpacing.pagePadding;
}

class EmployeeAttendanceScreen extends ConsumerWidget {
  final bool embedded;
  const EmployeeAttendanceScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(attendanceMonthProvider);
    final year = ref.watch(attendanceYearProvider);
    final key = (month: month, year: year);

    final historyAsync = ref.watch(attendanceHistoryProvider(key));
    final weeklyOffs =
        ref.watch(attendanceWeeklyOffsProvider).valueOrNull ?? const {6, 7};

    final media = MediaQuery.of(context);
    final clamped = media.textScaler.clamp(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.15,
    );

    void setMonthYear(int m, int y) {
      ref.read(attendanceMonthProvider.notifier).state = m;
      ref.read(attendanceYearProvider.notifier).state = y;
    }

    void shiftMonth(int delta) {
      var m = ref.read(attendanceMonthProvider) + delta;
      var y = ref.read(attendanceYearProvider);
      if (m < 1) {
        m = 12;
        y -= 1;
      } else if (m > 12) {
        m = 1;
        y += 1;
      }
      setMonthYear(m, y);
    }

    Future<void> refresh() async {
      ref.invalidate(attendanceHistoryProvider(key));
      ref.invalidate(attendanceWeeklyOffsProvider);
      try {
        await ref.read(attendanceHistoryProvider(key).future);
      } catch (_) {}
    }

    // Days after the web rules (absent / off worked out when no record).
    final days = historyAsync.hasValue
        ? resolveMonth(
      month: month,
      year: year,
      records: historyAsync.requireValue,
      weeklyOffs: weeklyOffs,
    )
        : null;

    AttendanceMonthHeader headerWith({required bool fullWidth}) {
      return AttendanceMonthHeader(
        month: month,
        year: year,
        fullWidth: fullWidth,
        onPrev: () => shiftMonth(-1),
        onNext: () => shiftMonth(1),
        onMonthChanged: (m) => setMonthYear(m, year),
        onYearChanged: (y) => setMonthYear(month, y),
      );
    }

    final header = headerWith(fullWidth: false);

    final chips = days != null
        ? AttendanceStatChips(summary: summarize(days))
        : const _ChipsSkeleton();

    Widget calendarArea({required bool fit, double cellHeight = 56}) {
      return historyAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 70),
          child: Center(
            child: CircularProgressIndicator(color: AttendanceColors.primary),
          ),
        ),
        error: (e, _) => _ErrorBlock(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(attendanceHistoryProvider(key)),
        ),
        data: (_) => AttendanceCalendarGrid(
          month: month,
          year: year,
          days: days!,
          fillHeight: fit,
          compactCellHeight: cellHeight,
        ),
      );
    }

    BoxDecoration cardDecoration() => BoxDecoration(
      color: AttendanceColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AttendanceColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    );

    final body = MediaQuery(
      data: media.copyWith(textScaler: clamped),
      child: LayoutBuilder(
        builder: (context, c) {
          final pad = _pagePadFor(c.maxWidth);

          // Big screens (web / tablet): the whole month fits on screen.
          final fit =
              c.hasBoundedHeight && c.maxWidth >= 700 && c.maxHeight >= 560;

          if (fit) {
            // Fills the free width (sidebar open OR hidden) - no max width.
            return Padding(
              padding: EdgeInsets.all(pad),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                decoration: cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: header,
                    ),
                    const SizedBox(height: 16),
                    chips,
                    const SizedBox(height: 18),
                    Expanded(child: calendarArea(fit: true)),
                    if (days != null) ...[
                      const SizedBox(height: 12),
                      const AttendanceLegend(),
                    ],
                  ],
                ),
              ),
            );
          }

          // ---------- ANDROID / PHONE ----------
          // Month selector in its own full-width card, the calendar card
          // below it. Day boxes grow on tall phones so the calendar fills
          // the screen (the page still scrolls on small phones).
          if (c.maxWidth < 600) {
            final daysInMonth = AttendanceFormatters.daysInMonth(month, year);
            final leading = AttendanceFormatters.weekdayOf(1, month, year) - 1;
            final rows = (leading + daysInMonth + 6) ~/ 7;

            // space used by everything except the day boxes (estimate)
            final chipRows = c.maxWidth < 440 ? 3 : 2;
            final chipsH = chipRows * 50.0 + (chipRows - 1) * 12;
            const headerCardH = 40.0 + 20; // selector + card padding
            const cardPad = 28.0; // calendar card top + bottom padding
            const weekdayRowH = 26.0;
            const legendH = 150.0;
            const gaps = 12.0 + 16 + 18 + 16; // between the blocks

            final free = c.maxHeight -
                pad * 2 -
                headerCardH -
                cardPad -
                chipsH -
                weekdayRowH -
                legendH -
                gaps;
            final cellH = ((free - 5.0 * (rows - 1)) / rows)
                .floorToDouble()
                .clamp(56.0, 84.0);

            return RefreshIndicator(
              color: AttendanceColors.primary,
              onRefresh: refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(pad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1) month selector - own card
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: cardDecoration(),
                      child: headerWith(fullWidth: true),
                    ),
                    const SizedBox(height: 12),

                    // 2) calendar card
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
                      decoration: cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          chips,
                          const SizedBox(height: 18),
                          calendarArea(fit: false, cellHeight: cellH),
                          if (days != null) ...[
                            const SizedBox(height: 16),
                            const AttendanceLegend(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Phones / short windows: normal scrolling page.
          final compactCard = c.maxWidth < 600;

          return RefreshIndicator(
            color: AttendanceColors.primary,
            onRefresh: refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(pad),
              child: Container(
                width: double.infinity,
                padding: compactCard
                    ? const EdgeInsets.fromLTRB(10, 14, 10, 14)
                    : const EdgeInsets.fromLTRB(14, 16, 14, 16),
                decoration: cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: header,
                    ),
                    const SizedBox(height: 16),
                    chips,
                    const SizedBox(height: 18),
                    calendarArea(fit: false),
                    if (days != null) ...[
                      const SizedBox(height: 16),
                      const AttendanceLegend(),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (embedded) return body;

    return Scaffold(
      backgroundColor: AttendanceColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AttendanceColors.textDark),
        title: const Text(
          'Attendance Calendar',
          style: TextStyle(
            color: AttendanceColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      body: body,
    );
  }
}

class _ChipsSkeleton extends StatelessWidget {
  const _ChipsSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final perRow = c.maxWidth < 440
            ? 2
            : c.maxWidth < 720
            ? 3
            : 5;
        const spacing = 12.0;
        final cellWidth =
        ((c.maxWidth - spacing * (perRow - 1)) / perRow).floorToDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var i = 0; i < 5; i++)
              Container(
                width: cellWidth,
                height: 50,
                decoration: BoxDecoration(
                  color: AttendanceColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AttendanceColors.border),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBlock({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: AttendanceColors.primary,
          ),
          const SizedBox(height: 12),
          Text(
            message.isEmpty ? 'Failed to load attendance.' : message,
            textAlign: TextAlign.center,
            style: AttendanceText.subtitle.copyWith(
              color: AttendanceColors.textMedium,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AttendanceColors.primary,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
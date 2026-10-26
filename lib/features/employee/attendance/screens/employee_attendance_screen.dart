// lib/features/employee/attendance/screens/employee_attendance_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/attendance_repository.dart';
import '../utils/attendance_resolver.dart';
import '../utils/attendance_theme.dart';
import '../widgets/attendance_calendar_grid.dart';
import '../widgets/attendance_month_header.dart';
import '../widgets/attendance_stat_chips.dart';

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

    final header = AttendanceMonthHeader(
      month: month,
      year: year,
      onPrev: () => shiftMonth(-1),
      onNext: () => shiftMonth(1),
      onMonthChanged: (m) => setMonthYear(m, year),
      onYearChanged: (y) => setMonthYear(month, y),
    );

    final chips = days != null
        ? AttendanceStatChips(summary: summarize(days))
        : const _ChipsSkeleton();

    Widget calendarArea({required bool fit}) {
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
          // Big screens (web / tablet): the whole month fits on screen.
          final fit =
              c.hasBoundedHeight && c.maxWidth >= 700 && c.maxHeight >= 560;

          if (fit) {
            return Padding(
              padding: const EdgeInsets.all(AttendanceSpacing.pagePadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AttendanceSpacing.maxContentWidth,
                  ),
                  child: Container(
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
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          // Phones / short windows: normal scrolling page.
          return RefreshIndicator(
            color: AttendanceColors.primary,
            onRefresh: refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AttendanceSpacing.pagePadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AttendanceSpacing.maxContentWidth,
                  ),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
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
                      ],
                    ),
                  ),
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
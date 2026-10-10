// lib/features/employee/attendance/screens/employee_attendance_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/attendance_summary_model.dart';
import '../repositories/attendance_repository.dart';
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
    final summaryAsync = ref.watch(attendanceSummaryProvider(key));

    final media = MediaQuery.of(context);
    final clamped = media.textScaler.clamp(
      minScaleFactor: 1.0,
      maxScaleFactor: 1.15,
    );

    final body = MediaQuery(
      data: media.copyWith(textScaler: clamped),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AttendanceSpacing.pagePadding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AttendanceSpacing.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AttendanceMonthHeader(
                  month: month,
                  year: year,
                  onPrev: () {
                    final m = ref.read(attendanceMonthProvider);
                    final y = ref.read(attendanceYearProvider);
                    var newMonth = m - 1;
                    var newYear = y;
                    if (newMonth < 1) {
                      newMonth = 12;
                      newYear -= 1;
                    }
                    ref.read(attendanceMonthProvider.notifier).state = newMonth;
                    ref.read(attendanceYearProvider.notifier).state = newYear;
                  },
                  onNext: () {
                    final m = ref.read(attendanceMonthProvider);
                    final y = ref.read(attendanceYearProvider);
                    var newMonth = m + 1;
                    var newYear = y;
                    if (newMonth > 12) {
                      newMonth = 1;
                      newYear += 1;
                    }
                    ref.read(attendanceMonthProvider.notifier).state = newMonth;
                    ref.read(attendanceYearProvider.notifier).state = newYear;
                  },
                ),                const SizedBox(height: AttendanceSpacing.cardGap),

                // Summary chips
                summaryAsync.when(
                  loading: () => const _ChipsSkeleton(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (s) => AttendanceStatChips(summary: s),
                ),
                const SizedBox(height: AttendanceSpacing.cardGap),

                // Calendar card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AttendanceSpacing.cardPaddingH,
                    vertical: AttendanceSpacing.cardPaddingV,
                  ),
                  decoration: BoxDecoration(
                    color: AttendanceColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AttendanceColors.border),
                  ),
                  child: historyAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AttendanceColors.primary,
                        ),
                      ),
                    ),
                    error: (e, _) => _ErrorBlock(
                      message: e
                          .toString()
                          .replaceFirst('Exception: ', ''),
                      onRetry: () =>
                          ref.invalidate(attendanceHistoryProvider(key)),
                    ),
                    data: (records) => AttendanceCalendarGrid(
                      month: month,
                      year: year,
                      records: records,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
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

  void _shiftMonth(Ref ref, int delta) {
    final m = ref.read(attendanceMonthProvider);
    final y = ref.read(attendanceYearProvider);

    var newMonth = m + delta;
    var newYear = y;
    if (newMonth < 1) {
      newMonth = 12;
      newYear -= 1;
    } else if (newMonth > 12) {
      newMonth = 1;
      newYear += 1;
    }
    ref.read(attendanceMonthProvider.notifier).state = newMonth;
    ref.read(attendanceYearProvider.notifier).state = newYear;
  }
}

class _ChipsSkeleton extends StatelessWidget {
  const _ChipsSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final perRow = c.maxWidth < 420
            ? 2
            : c.maxWidth < 720
            ? 3
            : 5;
        const spacing = 12.0;
        final cellWidth = (c.maxWidth - spacing * (perRow - 1)) / perRow;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var i = 0; i < 5; i++)
              Container(
                width: cellWidth,
                height: 52,
                decoration: BoxDecoration(
                  color: AttendanceColors.surface,
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
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 40, color: AttendanceColors.primary),
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
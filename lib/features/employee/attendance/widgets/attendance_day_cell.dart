// lib/features/employee/attendance/widgets/attendance_day_cell.dart

import 'package:flutter/material.dart';

import '../utils/attendance_resolver.dart';
import '../utils/attendance_theme.dart';

/// Day box of the current month (white box, soft status pill - like the web).
/// When the day was marked by the admin, a "Marked by Admin" tag is shown
/// under the status pill (phones: a small shield badge in the corner).
class AttendanceDayCell extends StatelessWidget {
  final AttendanceDayInfo info;
  final bool compact;
  final VoidCallback? onTap;

  const AttendanceDayCell({
    super.key,
    required this.info,
    required this.compact,
    this.onTap,
  });

  static const Color _adminTagText = Color(0xFF4B5563);

  @override
  Widget build(BuildContext context) {
    final style = info.hasStatus ? AttendanceStatuses.of(info.status) : null;
    final radius = BorderRadius.circular(compact ? 8 : 10);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: AttendanceColors.surface,
          borderRadius: radius,
          border: Border.all(
            color: info.isToday
                ? AttendanceColors.primary
                : AttendanceColors.border,
            width: info.isToday ? 1.4 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.all(compact ? 4 : 8),
            child: compact ? _compact(style) : _regular(style),
          ),
        ),
      ),
    );
  }

  Color get _numberColor =>
      info.isToday ? AttendanceColors.primary : AttendanceColors.textDark;

  // ---------------- phones: number + tiny code pill + admin badge ----------------

  Widget _compact(AttendanceStatusStyle? style) {
    return Stack(
      children: [
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${info.day}',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: _numberColor,
                ),
              ),
              const SizedBox(height: 4),
              if (style != null)
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                  decoration: BoxDecoration(
                    color: style.bg,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    style.code,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: style.fg,
                      height: 1.1,
                    ),
                  ),
                )
              else
                const Text(
                  '—',
                  style: TextStyle(
                    fontSize: 11,
                    color: AttendanceColors.textLight,
                    height: 1.4,
                  ),
                ),
            ],
          ),
        ),
        // Marked by admin -> small shield badge (tap the day for details)
        if (info.markedByAdmin)
          const Positioned(
            right: 0,
            top: 0,
            child: Icon(
              Icons.verified_user_rounded,
              size: 11,
              color: AttendanceColors.primary,
            ),
          ),
      ],
    );
  }

  // ---------------- web / tablet: number + pill + "Marked by Admin" ----------------

  Widget _regular(AttendanceStatusStyle? style) {
    return LayoutBuilder(
      builder: (context, c) {
        final timeText = info.checkInLabel;
        final pillText =
        timeText == null ? info.label : '${info.label} ($timeText)';

        // FittedBox(scaleDown): if a box is a little too short (6-week
        // months) the content shrinks slightly instead of overflowing.
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: c.maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${info.day}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _numberColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                if (style != null)
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: style.bg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          // shrinks the text instead of cutting it with "..."
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              pillText,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: style.fg,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(left: 2),
                    child: Text(
                      '—',
                      style: TextStyle(
                        fontSize: 13,
                        color: AttendanceColors.textLight,
                        height: 1.2,
                      ),
                    ),
                  ),

                // "Marked by Admin" - always shown when the admin marked it
                if (info.markedByAdmin) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF9CA3AF)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                size: 10,
                                color: _adminTagText,
                              ),
                              const SizedBox(width: 3),
                              const Flexible(
                                child: Text(
                                  'Marked by Admin',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: _adminTagText,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Faded box for days of the previous / next month.
class AttendanceOutsideCell extends StatelessWidget {
  final int day;
  final bool compact;

  const AttendanceOutsideCell({
    super.key,
    required this.day,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 4 : 10),
      alignment: compact ? Alignment.center : Alignment.topLeft,
      decoration: BoxDecoration(
        color: AttendanceColors.surfaceAlt,
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: Border.all(color: const Color(0xFFF1F3F5)),
      ),
      child: Text(
        '$day',
        style: TextStyle(
          fontSize: compact ? 13 : 15,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFC3CAD3),
        ),
      ),
    );
  }
}
// lib/features/employee/attendance/widgets/attendance_legend.dart

import 'package:flutter/material.dart';

import '../utils/attendance_theme.dart';

/// "What do the letters / icons mean?" - shown under the calendar.
/// Phones: short code pill (P, L, A ...) + name.  Wide screens: full pills.
class AttendanceLegend extends StatelessWidget {
  const AttendanceLegend({super.key});

  // status key (same keys as the resolver) + readable name
  static const List<(String, String)> _statuses = [
    ('present', 'Present'),
    ('late', 'Late'),
    ('absent', 'Absent'),
    ('on_leave', 'Leave'),
    ('holiday', 'Holiday'),
    ('week_off', 'Weekly Off'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < 560;

        final items = <Widget>[
          for (final s in _statuses) _statusItem(s.$1, s.$2, compact),
          _iconItem(
            icon: const Icon(
              Icons.verified_user_rounded,
              size: 14,
              color: AttendanceColors.primary,
            ),
            label: 'Marked by Admin',
          ),
          _iconItem(
            icon: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: AttendanceColors.primary,
                  width: 1.4,
                ),
              ),
            ),
            label: 'Today',
          ),
          _iconItem(
            icon: const Text(
              '—',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AttendanceColors.textLight,
              ),
            ),
            label: 'No record yet',
          ),
        ];

        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(compact ? 12 : 16, 12, 12, 12),
          decoration: BoxDecoration(
            color: AttendanceColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AttendanceColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: AttendanceColors.textMedium,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Legend',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AttendanceColors.textMedium,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: compact ? 14 : 22,
                runSpacing: 10,
                children: items,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusItem(String key, String name, bool compact) {
    final style = AttendanceStatuses.of(key);
    if (style == null) return const SizedBox.shrink();

    final pill = Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 9,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(compact ? 5 : 6),
      ),
      child: Text(
        compact ? style.code : name,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: compact ? 10 : 11.5,
          fontWeight: FontWeight.w800,
          color: style.fg,
          height: 1.15,
        ),
      ),
    );

    // Wide screens: the pill already says the name.
    if (!compact) return pill;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        pill,
        const SizedBox(width: 6),
        Text(name, style: _labelStyle),
      ],
    );
  }

  Widget _iconItem({required Widget icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 6),
        Text(label, style: _labelStyle),
      ],
    );
  }

  static const TextStyle _labelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AttendanceColors.textMedium,
  );
}
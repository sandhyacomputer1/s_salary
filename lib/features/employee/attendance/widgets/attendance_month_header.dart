// lib/features/employee/attendance/widgets/attendance_month_header.dart

import 'package:flutter/material.dart';

import '../utils/attendance_theme.dart';

/// [<]  [ October v | 2026 v ]  [>]   (same as the web page)
///
/// [fullWidth] = true (phones): the month / year box stretches over the whole
/// width and the arrows sit at both ends.
class AttendanceMonthHeader extends StatelessWidget {
  final int month;
  final int year;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;
  final bool fullWidth;

  const AttendanceMonthHeader({
    super.key,
    required this.month,
    required this.year,
    required this.onPrev,
    required this.onNext,
    required this.onMonthChanged,
    required this.onYearChanged,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final nowYear = DateTime.now().year;
    final years = [for (var y = nowYear - 4; y <= nowYear + 1; y++) y];

    final monthPicker = PopupMenuButton<int>(
      tooltip: 'Select month',
      position: PopupMenuPosition.under,
      onSelected: onMonthChanged,
      itemBuilder: (_) => [
        for (var m = 1; m <= 12; m++)
          PopupMenuItem<int>(
            value: m,
            child: Text(
              AttendanceFormatters.monthNames[m - 1],
              style: TextStyle(
                fontWeight: m == month ? FontWeight.w800 : FontWeight.w500,
                color: m == month
                    ? AttendanceColors.primary
                    : AttendanceColors.textDark,
              ),
            ),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AttendanceFormatters.monthNames[month - 1],
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AttendanceColors.textDark,
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: AttendanceColors.textDark,
          ),
        ],
      ),
    );

    final yearPicker = PopupMenuButton<int>(
      tooltip: 'Select year',
      position: PopupMenuPosition.under,
      onSelected: onYearChanged,
      itemBuilder: (_) => [
        for (final y in years)
          PopupMenuItem<int>(
            value: y,
            child: Text(
              '$y',
              style: TextStyle(
                fontWeight: y == year ? FontWeight.w800 : FontWeight.w500,
                color: y == year
                    ? AttendanceColors.primary
                    : AttendanceColors.textDark,
              ),
            ),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$year',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AttendanceColors.primary,
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: AttendanceColors.primary,
          ),
        ],
      ),
    );

    final selector = Container(
      height: fullWidth ? 40 : null,
      padding: EdgeInsets.symmetric(
        horizontal: fullWidth ? 12 : 14,
        vertical: fullWidth ? 0 : 8,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AttendanceColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AttendanceColors.border),
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: fullWidth
            ? MainAxisAlignment.spaceEvenly
            : MainAxisAlignment.start,
        children: [
          monthPicker,
          if (!fullWidth) const SizedBox(width: 14),
          yearPicker,
        ],
      ),
    );

    return Row(
      children: [
        _ArrowButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Previous month',
          onTap: onPrev,
        ),
        const SizedBox(width: 10),
        if (fullWidth) Expanded(child: selector) else Flexible(child: selector),
        const SizedBox(width: 10),
        _ArrowButton(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Next month',
          onTap: onNext,
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AttendanceColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AttendanceColors.border),
          ),
          child: Icon(icon, size: 20, color: AttendanceColors.textDark),
        ),
      ),
    );
  }
}
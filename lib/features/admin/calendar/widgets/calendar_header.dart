import 'package:flutter/material.dart';

// =================================================================
// CALENDAR HEADER
//
// Month/year label with previous, Today and next controls.
// Uses the same colors and shapes as the rest of the S Salary
// admin screens (AddEmployeeScreen, AdminDashboardScreen, etc).
// =================================================================

class CalendarHeader extends StatelessWidget {
  static const Color primary = Color(0xFFE96832);
  static const Color primaryLight = Color(0xFFFFF1EB);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color border = Color(0xFFE5E7EB);

  final DateTime displayedMonth;
  final bool compact;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;

  const CalendarHeader({
    super.key,
    required this.displayedMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
    this.compact = false,
  });

  static const List<String> _monthNames = [
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

  String get _label =>
      '${_monthNames[displayedMonth.month - 1]} ${displayedMonth.year}';

  @override
  Widget build(BuildContext context) {
    final label = Text(
      _label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: compact ? 17 : 19,
        fontWeight: FontWeight.w700,
        color: textDark,
      ),
    );

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _navButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Previous month',
          onTap: onPreviousMonth,
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: onToday,
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: const BorderSide(color: primary),
            backgroundColor: primaryLight,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Today',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _navButton(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Next month',
          onTap: onNextMonth,
        ),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label,
          const SizedBox(height: 12),
          controls,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: label),
        controls,
      ],
    );
  }

  Widget _navButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Icon(icon, size: 22, color: textMedium),
        ),
      ),
    );
  }
}
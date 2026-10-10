// lib/features/employee/attendance/utils/attendance_theme.dart

import 'package:flutter/material.dart';

class AttendanceColors {
  AttendanceColors._();

  // Brand (matches the shell and every other employee feature)
  static const Color primary = Color(0xFFE96832);
  static const Color primaryLight = Color(0xFFFFEEE7);

  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color fieldLabel = Color(0xFF6B7280);

  static const Color border = Color(0xFFE1E5EA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF9FAFB);
  static const Color background = Color(0xFFF7F8FA);

  // Status pill colors (from the web calendar)
  static const Color present = Color(0xFF16803B);
  static const Color presentBg = Color(0xFFE7F6EC);

  static const Color late = Color(0xFFD97706);
  static const Color lateBg = Color(0xFFFFF6E0);

  static const Color absent = Color(0xFFD64545);
  static const Color absentBg = Color(0xFFFDECEA);

  static const Color leave = Color(0xFF7C3AED);
  static const Color leaveBg = Color(0xFFF3E8FF);

  static const Color holiday = Color(0xFF2563EB);
  static const Color holidayBg = Color(0xFFE0E7FF);

  static const Color off = Color(0xFF6B7280);
  static const Color offBg = Color(0xFFF3F4F6);
}

class AttendanceText {
  AttendanceText._();

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: AttendanceColors.textDark,
  );

  static const TextStyle monthLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AttendanceColors.textDark,
  );

  static const TextStyle weekday = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: AttendanceColors.fieldLabel,
  );

  static const TextStyle dayNumber = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AttendanceColors.textDark,
  );

  static const TextStyle dayNumberMuted = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AttendanceColors.textLight,
  );

  static const TextStyle pill = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.2,
  );

  static const TextStyle chipLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AttendanceColors.textMedium,
  );

  static const TextStyle chipValue = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AttendanceColors.textDark,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 12.5,
    height: 1.45,
    color: AttendanceColors.textLight,
  );
}

class AttendanceSpacing {
  AttendanceSpacing._();

  static const double pagePadding = 16;
  static const double cardGap = 16;
  static const double cardPaddingH = 20;
  static const double cardPaddingV = 18;
  static const double maxContentWidth = 1200;
}

class AttendanceFormatters {
  AttendanceFormatters._();

  /// (10, 2026) -> "October 2026"
  static String monthYear(int month, int year) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    if (month < 1 || month > 12) return '$month/$year';
    return '${names[month - 1]} $year';
  }

  static const List<String> weekdayShort = [
    'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN',
  ];

  /// Days in a given month.
  static int daysInMonth(int month, int year) {
    if (month == 2) {
      final leap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
      return leap ? 29 : 28;
    }
    const d = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month < 1 || month > 12) return 30;
    return d[month - 1];
  }

  /// 1 = Monday … 7 = Sunday (ISO). Dart's DateTime.weekday is the same.
  static int weekdayOf(int day, int month, int year) {
    return DateTime(year, month, day).weekday;
  }

  /// "YYYY-MM-DD"
  static String isoDate(int day, int month, int year) {
    return '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';
  }
}
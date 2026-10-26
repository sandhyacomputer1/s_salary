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

  static const Color border = Color(0xFFE5E7EB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF9FAFB);
  static const Color background = Color(0xFFF7F8FA);

  // Status colours (bright)
  static const Color present = Color(0xFF15803D);
  static const Color presentBg = Color(0xFFDCFCE7);

  static const Color late = Color(0xFFB45309);
  static const Color lateBg = Color(0xFFFEF3C7);

  static const Color halfDay = Color(0xFFC2410C);
  static const Color halfDayBg = Color(0xFFFFEDD5);

  static const Color absent = Color(0xFFB91C1C);
  static const Color absentBg = Color(0xFFFEE2E2);

  static const Color leave = Color(0xFF6D28D9);
  static const Color leaveBg = Color(0xFFEDE9FE);

  static const Color holiday = Color(0xFF1D4ED8);
  static const Color holidayBg = Color(0xFFDBEAFE);

  static const Color off = Color(0xFF475569);
  static const Color offBg = Color(0xFFF1F5F9);
}

/// Everything the UI needs to draw one attendance status.
class AttendanceStatusStyle {
  final String label; // "Present"
  final String code; // "P"  (used on small phone cells)
  final Color fg; // text / icon colour
  final Color bg; // soft background
  final Color solid; // bright solid colour (badges, borders)
  final IconData icon;

  const AttendanceStatusStyle({
    required this.label,
    required this.code,
    required this.fg,
    required this.bg,
    required this.solid,
    required this.icon,
  });
}

class AttendanceStatuses {
  AttendanceStatuses._();

  static const AttendanceStatusStyle present = AttendanceStatusStyle(
    label: 'Present',
    code: 'P',
    fg: AttendanceColors.present,
    bg: AttendanceColors.presentBg,
    solid: Color(0xFF22C55E),
    icon: Icons.check_circle_rounded,
  );

  static const AttendanceStatusStyle late = AttendanceStatusStyle(
    label: 'Late',
    code: 'L',
    fg: AttendanceColors.late,
    bg: AttendanceColors.lateBg,
    solid: Color(0xFFF59E0B),
    icon: Icons.schedule_rounded,
  );

  static const AttendanceStatusStyle halfDay = AttendanceStatusStyle(
    label: 'Half Day',
    code: 'HD',
    fg: AttendanceColors.halfDay,
    bg: AttendanceColors.halfDayBg,
    solid: Color(0xFFF97316),
    icon: Icons.timelapse_rounded,
  );

  static const AttendanceStatusStyle absent = AttendanceStatusStyle(
    label: 'Absent',
    code: 'A',
    fg: AttendanceColors.absent,
    bg: AttendanceColors.absentBg,
    solid: Color(0xFFEF4444),
    icon: Icons.cancel_rounded,
  );

  static const AttendanceStatusStyle leave = AttendanceStatusStyle(
    label: 'Leave',
    code: 'LV',
    fg: AttendanceColors.leave,
    bg: AttendanceColors.leaveBg,
    solid: Color(0xFF8B5CF6),
    icon: Icons.beach_access_rounded,
  );

  static const AttendanceStatusStyle holiday = AttendanceStatusStyle(
    label: 'Holiday',
    code: 'H',
    fg: AttendanceColors.holiday,
    bg: AttendanceColors.holidayBg,
    solid: Color(0xFF3B82F6),
    icon: Icons.celebration_rounded,
  );

  static const AttendanceStatusStyle weekOff = AttendanceStatusStyle(
    label: 'Week Off',
    code: 'OFF',
    fg: AttendanceColors.off,
    bg: AttendanceColors.offBg,
    solid: Color(0xFF94A3B8),
    icon: Icons.weekend_rounded,
  );

  static const List<AttendanceStatusStyle> all = [
    present,
    late,
    halfDay,
    absent,
    leave,
    holiday,
    weekOff,
  ];

  /// Returns null for unknown / empty status.
  static AttendanceStatusStyle? of(String status) {
    switch (status.toLowerCase().replaceAll('-', '_')) {
      case 'present':
        return present;
      case 'late':
        return late;
      case 'half_day':
      case 'halfday':
        return halfDay;
      case 'absent':
        return absent;
      case 'on_leave':
      case 'leave':
        return leave;
      case 'holiday':
        return holiday;
      case 'week_off':
      case 'weekoff':
      case 'off':
        return weekOff;
      default:
        return null;
    }
  }
}

class AttendanceText {
  AttendanceText._();

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: AttendanceColors.textDark,
  );

  static const TextStyle monthLabel = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AttendanceColors.textDark,
  );

  static const TextStyle weekday = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.6,
    color: AttendanceColors.fieldLabel,
  );

  static const TextStyle dayNumber = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
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
    color: Colors.white,
  );

  static const TextStyle chipLabel = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    color: AttendanceColors.textMedium,
  );

  static const TextStyle chipValue = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1,
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
  static const double cardPaddingH = 18;
  static const double cardPaddingV = 18;
  static const double maxContentWidth = 1100;
}

class AttendanceFormatters {
  AttendanceFormatters._();

  static const List<String> monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const List<String> weekdayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  static const List<String> weekdayShort = [
    'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN',
  ];

  /// (10, 2026) -> "October 2026"
  static String monthYear(int month, int year) {
    if (month < 1 || month > 12) return '$month/$year';
    return '${monthNames[month - 1]} $year';
  }

  /// (23, 10, 2026) -> "Friday, 23 October 2026"
  static String fullDate(int day, int month, int year) {
    final wd = weekdayNames[DateTime(year, month, day).weekday - 1];
    return '$wd, $day ${monthNames[month - 1]} $year';
  }

  static int daysInMonth(int month, int year) {
    return DateTime(year, month + 1, 0).day;
  }

  /// 1 = Monday … 7 = Sunday
  static int weekdayOf(int day, int month, int year) {
    return DateTime(year, month, day).weekday;
  }

  /// "YYYY-MM-DD"
  static String isoDate(int day, int month, int year) {
    return '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';
  }

  /// "2026-10-21T09:47:57Z" -> "03:17 pm" (local). Other text is kept as is.
  static String time(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return raw;

    final d = parsed.toLocal();
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'pm' : 'am';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  /// "2026-10-24T04:37:00Z" -> "10:07 AM" (local, upper-case like the web)
  static String timeAmPm(String? raw) {
    final t = time(raw);
    return t == '—' ? t : t.replaceAll('am', 'AM').replaceAll('pm', 'PM');
  }

  /// 27000 -> "7h 30m"
  static String duration(int seconds) {
    if (seconds <= 0) return '—';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  /// 62.5 -> "62h 30m"
  static String hours(double hours) {
    return duration((hours * 3600).round());
  }
}
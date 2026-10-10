// lib/features/employee/salary/utils/salary_theme.dart

import 'package:flutter/material.dart';

class SalaryColors {
  SalaryColors._();

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

  static const Color earnings = Color(0xFF16A34A);
  static const Color earningsBg = Color(0xFFE7F6EC);
  static const Color deductions = Color(0xFFDC2626);
  static const Color deductionsBg = Color(0xFFFDECEA);
  static const Color netBand = Color(0xFF16803B);
  static const Color netBandText = Color(0xFFFFFFFF);

  static const Color statusGenerated = Color(0xFF6B7280);
  static const Color statusGeneratedBg = Color(0xFFF3F4F6);
  static const Color statusApproved = Color(0xFF1D4ED8);
  static const Color statusApprovedBg = Color(0xFFE0E7FF);
  static const Color statusPaid = Color(0xFF16803B);
  static const Color statusPaidBg = Color(0xFFE7F6EC);
  static const Color statusDraft = Color(0xFF9A6A00);
  static const Color statusDraftBg = Color(0xFFFFF6E0);
}

class SalaryText {
  SalaryText._();

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: SalaryColors.textDark,
  );
  static const TextStyle subtitle = TextStyle(
    fontSize: 12.5,
    height: 1.45,
    color: SalaryColors.textLight,
  );
  static const TextStyle label = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: SalaryColors.fieldLabel,
  );
  static const TextStyle value = TextStyle(
    fontSize: 13.5,
    height: 1.35,
    fontWeight: FontWeight.w600,
    color: SalaryColors.textDark,
  );
  static const TextStyle metricValue = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: SalaryColors.textDark,
  );
  static const TextStyle metricValueGreen = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: SalaryColors.earnings,
  );
  static const TextStyle month = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: SalaryColors.textDark,
  );
  static const TextStyle rowLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: SalaryColors.textMedium,
  );
  static const TextStyle rowAmount = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
    color: SalaryColors.textDark,
  );
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.0,
    color: SalaryColors.primary,
  );
  static const TextStyle pill = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.3,
  );
  static const TextStyle netBandLabel = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.0,
    color: SalaryColors.netBandText,
  );
  static const TextStyle netBandCaption = TextStyle(
    fontSize: 12,
    color: Color(0xCCFFFFFF),
  );
  static const TextStyle netBandAmount = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: SalaryColors.netBandText,
  );
}

class SalarySpacing {
  SalarySpacing._();

  static const double pagePadding = 16;
  static const double cardGap = 16;
  static const double cardPaddingH = 20;
  static const double cardPaddingV = 18;
  static const double maxContentWidth = 1200;
}

class SalaryFormatters {
  SalaryFormatters._();

  /// Indian-grouped rupee string. 145555 -> "₹1,45,555".
  static String rupees(num? amount, {bool decimals = false}) {
    if (amount == null) return '—';
    if (amount is double && (amount.isNaN || amount.isInfinite)) return '—';

    final negative = amount < 0;
    final abs = amount.abs();
    final intPart = abs.floor();
    final frac = abs - intPart;
    final grouped = _groupIndian(intPart.toString());
    final fracStr = decimals && frac > 0
        ? '.${(frac * 100).round().toString().padLeft(2, '0')}'
        : '';
    return '${negative ? '-' : ''}₹$grouped$fracStr';
  }

  static String deduction(num? amount) =>
      amount == null ? '—' : '- ${rupees(amount)}';

  static String earning(num? amount) =>
      amount == null ? '—' : '+ ${rupees(amount)}';

  static String _groupIndian(String digits) {
    if (digits.length <= 3) return digits;
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final buf = StringBuffer();
    while (rest.length > 2) {
      buf.write(rest.substring(rest.length - 2));
      buf.write(',');
      rest = rest.substring(0, rest.length - 2);
    }
    buf.write(rest);
    buf.write(',');
    buf.write(last3);
    final parts = buf.toString().split(',');
    final leading = parts.sublist(0, parts.length - 1).reversed.join(',');
    return '$leading,${parts.last}';
  }

  /// "2026-09-07" or ISO8601 -> "07 Sep 2026".
  static String prettyDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    final s = raw.trim();
    final dateOnly = s.length >= 10 ? s.substring(0, 10) : s;
    final parts = dateOnly.split('-');
    if (parts.length != 3) return s;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null || m < 1 || m > 12) return s;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.toString().padLeft(2, '0')} ${months[m - 1]} $y';
  }

  /// (10, 2026) -> "October 2026"
  static String monthYear(int month, int year) {
    const names = [
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
    if (month < 1 || month > 12) return '$month/$year';
    return '${names[month - 1]} $year';
  }
}

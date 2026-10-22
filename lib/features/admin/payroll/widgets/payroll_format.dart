import 'package:flutter/material.dart';

/// Display helpers for the Payroll screens (Indian digit grouping, month
/// names, email-status colours).
class PayrollFormat {
  PayrollFormat._();

  static const List<String> months = [
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

  /// 1-12 -> "January" .. "December" ("-" when out of range).
  static String monthName(int month) =>
      (month >= 1 && month <= 12) ? months[month - 1] : '-';

  /// Indian grouping for a whole number: 1234567 -> "12,34,567".
  static String _group(int whole) {
    final digits = whole.toString();
    if (digits.length <= 3) return digits;

    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final parts = <String>[];

    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);

    return '${parts.join(',')},$last3';
  }

  /// Whole rupees, like the web table: "₹67,084" ("-₹200" when negative).
  static String rupees(double value) {
    final rounded = value.round();
    final text = '₹${_group(rounded.abs())}';
    return rounded < 0 ? '-$text' : text;
  }

  /// Keeps paise when there are any: "₹1,234.50", otherwise like [rupees].
  static String rupeesExact(double value) {
    if (value == value.roundToDouble()) return rupees(value);

    final negative = value < 0;
    final abs = value.abs();
    final whole = abs.floor();
    final paise = ((abs - whole) * 100).round().toString().padLeft(2, '0');
    final text = '₹${_group(whole)}.$paise';

    return negative ? '-$text' : text;
  }

  /// A deduction as shown in the table: "₹0" or "-₹200".
  static String deduction(double value) =>
      value <= 0 ? '₹0' : '-${rupees(value)}';

  // ==========================================================
  // EMAIL STATUS (documented: pending | sent | failed)
  // ==========================================================

  static String emailLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'sent':
        return 'Sent';
      case 'failed':
        return 'Failed';
      default:
        return status.trim().isEmpty ? '-' : status;
    }
  }

  static Color emailColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'sent':
        return const Color(0xFF18864B);
      case 'failed':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF6B7280);
    }
  }

  /// Always two decimals, like the web payslip: "₹1,35,655.00".
  static String rupees2(double value) {
    final negative = value < 0;
    final abs = value.abs();

    var whole = abs.floor();
    var paise = ((abs - whole) * 100).round();

    if (paise == 100) {
      whole += 1;
      paise = 0;
    }

    final text = '₹${_group(whole)}.${paise.toString().padLeft(2, '0')}';
    return negative ? '-$text' : text;
  }

  static Color emailBackground(String status) {
    switch (status.trim().toLowerCase()) {
      case 'sent':
        return const Color(0xFFE9F8EF);
      case 'failed':
        return const Color(0xFFFDECEC);
      default:
        return const Color(0xFFF1F3F6);
    }
  }
}

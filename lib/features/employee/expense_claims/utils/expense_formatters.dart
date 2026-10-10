/// Formatting helpers for expense claims (no external packages).
class ExpenseFormatters {
  ExpenseFormatters._();

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// 55555 -> ₹55,555 | 4454500 -> ₹44,54,500 | 1250.5 -> ₹1,250.50
  static String inr(double amount) {
    final isNegative = amount < 0;
    final abs = amount.abs();

    final hasPaise = (abs - abs.truncateToDouble()).abs() > 0.004;
    final fixed = abs.toStringAsFixed(hasPaise ? 2 : 0);
    final parts = fixed.split('.');
    final whole = parts[0];

    String grouped;
    if (whole.length <= 3) {
      grouped = whole;
    } else {
      final last3 = whole.substring(whole.length - 3);
      var rest = whole.substring(0, whole.length - 3);
      final chunks = <String>[];
      while (rest.length > 2) {
        chunks.insert(0, rest.substring(rest.length - 2));
        rest = rest.substring(0, rest.length - 2);
      }
      if (rest.isNotEmpty) chunks.insert(0, rest);
      grouped = '${chunks.join(',')},$last3';
    }

    final decimals = parts.length > 1 ? '.${parts[1]}' : '';
    return '${isNegative ? '-' : ''}₹$grouped$decimals';
  }

  /// For expenseDate: server sends midnight UTC for a calendar date,
  /// so read the UTC parts to avoid shifting the day.
  static String calendarDate(DateTime? date) {
    if (date == null) return '';
    final d = date.toUtc();
    return _format(d.day, d.month, d.year);
  }

  /// For real instants such as submittedAt / actionedAt (local time).
  static String instantDate(DateTime? date) {
    if (date == null) return '';
    final d = date.toLocal();
    return _format(d.day, d.month, d.year);
  }

  static String _format(int day, int month, int year) {
    return '${day.toString().padLeft(2, '0')} ${_months[month - 1]} $year';
  }
}
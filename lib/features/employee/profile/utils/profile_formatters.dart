// lib/features/employee/profile/utils/profile_formatters.dart

class ProfileFormatters {
  ProfileFormatters._();

  /// "male" -> "Male", "on_leave" -> "On Leave", "" -> "—"
  static String titleCase(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return '—';
    return s
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) =>
    '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  /// Initials for the avatar: "Rahul Sharma" -> "RS".
  static String initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Show only the last 4 digits of an account number.
  static String maskAccount(String acc) {
    if (acc.length < 4) return acc.isEmpty ? '—' : acc;
    return '•••• ${acc.substring(acc.length - 4)}';
  }

  /// Display fallback for empty values.
  static String orDash(String value) {
    return value.trim().isEmpty ? '—' : value;
  }

  /// "YYYY-MM-DD" -> "DD MMM YYYY". Returns input unchanged if unparseable.
  static String prettyDate(String yyyymmdd) {
    final s = yyyymmdd.trim();
    if (s.isEmpty) return '—';
    final parts = s.split('-');
    if (parts.length != 3) return s;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return s;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    if (m < 1 || m > 12) return s;
    return '${d.toString().padLeft(2, '0')} ${months[m - 1]} $y';
  }
}
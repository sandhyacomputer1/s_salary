class EmpLeaveBalanceModel {
  final String id;
  final String leaveType;
  final int year;
  final double allotted;
  final double used;
  final double remaining;

  const EmpLeaveBalanceModel({
    required this.id,
    required this.leaveType,
    required this.year,
    required this.allotted,
    required this.used,
    required this.remaining,
  });

  /// Per-type balance document, same shape as the "balance" object returned
  /// by the admin approve-leave response.
  factory EmpLeaveBalanceModel.fromJson(Map<String, dynamic> json) {
    final allotted = _toDouble(json['allotted']);
    final used = _toDouble(json['used']);

    return EmpLeaveBalanceModel(
      id: json['_id']?.toString() ?? '',
      leaveType: json['leaveType']?.toString() ?? '',
      year: _toInt(json['year']),
      allotted: allotted,
      used: used,
      remaining: json['remaining'] == null
          ? allotted - used
          : _toDouble(json['remaining']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  String get displayName => EmpLeaveTypeHelper.displayName(leaveType);
}

/// Display helpers shared by the balance cards, form and history.
class EmpLeaveTypeHelper {
  EmpLeaveTypeHelper._();

  /// Used only when the balances endpoint returns nothing usable. These are
  /// the four types shown in the web app.
  static const List<String> fallbackTypes = [
    'Casual',
    'Sick',
    'Earned',
    'Unpaid',
  ];

  static String displayName(String type) {
    switch (type.toLowerCase()) {
      case 'casual':
        return 'Casual Leave';
      case 'sick':
        return 'Sick Leave';
      case 'earned':
        return 'Earned / Paid Leave';
      case 'unpaid':
        return 'Unpaid Leave';
      default:
        return type.toLowerCase().endsWith('leave') ? type : '$type Leave';
    }
  }

  /// Only "Unpaid" is a salary-cut type (matches the web dropdown labels).
  static bool isPaid(String type) => type.toLowerCase() != 'unpaid';

  static String optionLabel(String type) {
    return isPaid(type)
        ? '${displayName(type)} (Paid - 0 Salary Cut)'
        : '${displayName(type)} (Unpaid - Salary Cut)';
  }

  static String formatDays(double days) {
    return days.truncateToDouble() == days
        ? days.toStringAsFixed(0)
        : days.toStringAsFixed(1);
  }
}
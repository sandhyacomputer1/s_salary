class EmpDailyReportModel {
  final String id;
  final String employeeId;

  /// 'YYYY-MM-DD' (or '' when missing). Kept as text so no time zone
  /// conversion can ever shift the calendar day.
  final String dateKey;

  final String completedWork;
  final String ongoingWork;
  final String planForTomorrow;
  final String blockers;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EmpDailyReportModel({
    required this.id,
    required this.employeeId,
    required this.dateKey,
    required this.completedWork,
    required this.ongoingWork,
    required this.planForTomorrow,
    required this.blockers,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmpDailyReportModel.fromJson(Map<String, dynamic> json) {
    return EmpDailyReportModel(
      id: json['_id']?.toString() ?? '',
      employeeId: _idOf(json['employeeId']),
      dateKey: _dateKeyOf(json['date']),
      // "workDoneToday" is the documented legacy alias of completedWork.
      completedWork: _text(json['completedWork'] ?? json['workDoneToday']),
      ongoingWork: _text(json['ongoingWork']),
      planForTomorrow: _text(json['planForTomorrow']),
      blockers: _text(json['blockers']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static String _idOf(dynamic value) {
    if (value is Map) return value['_id']?.toString() ?? '';
    return value?.toString() ?? '';
  }

  static String _dateKeyOf(dynamic value) {
    final text = value?.toString() ?? '';
    if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(text)) {
      return text.substring(0, 10);
    }
    return '';
  }

  static String _text(dynamic value) => value?.toString() ?? '';

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  /// Last time this report was saved (reports are upserted).
  DateTime? get submittedAt => updatedAt ?? createdAt;
}

/// What the form hands to the service.
class EmpDailyReportInput {
  final String completedWork;
  final String ongoingWork;
  final String planForTomorrow;
  final DateTime date;

  const EmpDailyReportInput({
    required this.completedWork,
    required this.ongoingWork,
    required this.planForTomorrow,
    required this.date,
  });

  /// Documented body: { completedWork, ongoingWork, planForTomorrow,
  /// blockers, date }. "blockers" is omitted — the web form has no such field.
  Map<String, dynamic> toJson() {
    return {
      'completedWork': completedWork,
      'ongoingWork': ongoingWork,
      'planForTomorrow': planForTomorrow,
      'date': EmpDailyReportFormat.api(date),
    };
  }
}

class EmpDailyReportFormat {
  EmpDailyReportFormat._();

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  static const List<String> _shortWeekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// API date: YYYY-MM-DD (device-local calendar day).
  static String api(DateTime date) =>
      '${date.year}-${_two(date.month)}-${_two(date.day)}';

  /// "Thursday, 08 Oct 2026" — page subtitle.
  static String longDate(DateTime date) =>
      '${_weekdays[date.weekday - 1]}, ${_two(date.day)} ${_months[date.month - 1]} ${date.year}';

  /// 'YYYY-MM-DD' → "Thu, 08 Oct 2026" (pure calendar math, no time zones).
  static String keyToDisplay(String key) {
    if (key.length != 10) return '—';

    final year = int.tryParse(key.substring(0, 4));
    final month = int.tryParse(key.substring(5, 7));
    final day = int.tryParse(key.substring(8, 10));

    if (year == null || month == null || day == null) return '—';
    if (month < 1 || month > 12) return '—';

    final weekday = DateTime.utc(year, month, day).weekday;

    return '${_shortWeekdays[weekday - 1]}, ${_two(day)} ${_months[month - 1]} $year';
  }

  /// Timestamp → "08 Oct 2026, 10:32 AM" in device-local time.
  static String dateTime(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '${_two(local.day)} ${_months[local.month - 1]} ${local.year}, '
        '${_two(hour)}:${_two(local.minute)} $period';
  }
}
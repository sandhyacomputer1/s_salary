// =================================================================
// CALENDAR EVENT MODEL
//
// Represents a single item shown on the admin calendar — an
// attendance record, a leave, a holiday, or a shift.
//
// This model is intentionally API-agnostic: it does not call any
// service itself. fromJson()/toJson() are provided so it can be
// wired up to real endpoints later without changing the UI.
// =================================================================

enum CalendarEventType {
  attendance,
  leave,
  holiday,
  shift;

  /// Parses a backend string ('attendance', 'leave', 'holiday',
  /// 'shift') into the enum. Falls back to [attendance] for any
  /// unrecognised value so the UI never crashes on bad data.
  static CalendarEventType fromValue(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'leave':
        return CalendarEventType.leave;
      case 'holiday':
        return CalendarEventType.holiday;
      case 'shift':
        return CalendarEventType.shift;
      case 'attendance':
      default:
        return CalendarEventType.attendance;
    }
  }

  /// The string form sent to / received from the backend.
  String get value {
    switch (this) {
      case CalendarEventType.attendance:
        return 'attendance';
      case CalendarEventType.leave:
        return 'leave';
      case CalendarEventType.holiday:
        return 'holiday';
      case CalendarEventType.shift:
        return 'shift';
    }
  }

  /// A human-readable label for the UI.
  String get label {
    switch (this) {
      case CalendarEventType.attendance:
        return 'Attendance';
      case CalendarEventType.leave:
        return 'Leave';
      case CalendarEventType.holiday:
        return 'Holiday';
      case CalendarEventType.shift:
        return 'Shift';
    }
  }
}

class CalendarEvent {
  final String id;
  final DateTime date;
  final String title;
  final CalendarEventType type;
  final String? status;
  final String? employeeId;
  final String? employeeName;
  final String? startTime;
  final String? endTime;
  final String? description;

  const CalendarEvent({
    required this.id,
    required this.date,
    required this.title,
    required this.type,
    this.status,
    this.employeeId,
    this.employeeName,
    this.startTime,
    this.endTime,
    this.description,
  });

  /// True when [other] falls on the same calendar day as this
  /// event (ignoring time-of-day).
  bool isOnSameDayAs(DateTime other) {
    return date.year == other.year &&
        date.month == other.month &&
        date.day == other.day;
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'] ?? json['eventDate'];

    return CalendarEvent(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      date: DateTime.tryParse(rawDate?.toString() ?? '') ?? DateTime.now(),
      title: (json['title'] ?? '').toString(),
      type: CalendarEventType.fromValue(json['type']?.toString()),
      status: json['status']?.toString(),
      employeeId: json['employeeId']?.toString(),
      employeeName: json['employeeName']?.toString(),
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'title': title,
      'type': type.value,
      if (status != null) 'status': status,
      if (employeeId != null) 'employeeId': employeeId,
      if (employeeName != null) 'employeeName': employeeName,
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      if (description != null) 'description': description,
    };
  }

  CalendarEvent copyWith({
    String? id,
    DateTime? date,
    String? title,
    CalendarEventType? type,
    String? status,
    String? employeeId,
    String? employeeName,
    String? startTime,
    String? endTime,
    String? description,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      type: type ?? this.type,
      status: status ?? this.status,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
    );
  }
}
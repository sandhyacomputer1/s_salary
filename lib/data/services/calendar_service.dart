import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../features/admin/calendar/models/calendar_event.dart';
import '../models/employee.dart';
import 'employee_service.dart';

class CalendarService {
  final ApiClient _apiClient = ApiClient();
  final EmployeeService _employeeService = EmployeeService();

  // ============================================================
  // LOAD ALL CALENDAR EVENTS FOR A MONTH
  // ============================================================

  Future<List<CalendarEvent>> getMonthlyEvents({
    required DateTime month,
  }) async {
    final events = <CalendarEvent>[];

    // ------------------------------------------------------------
    // 1. ATTENDANCE + LEAVES
    // ------------------------------------------------------------

    try {
      final employees = await _employeeService.getEmployees(
        status: 'active',
      );

      if (employees.isNotEmpty) {
        final employeeResults = await Future.wait(
          employees.map(
                (employee) async {
              try {
                return await _employeeService.getEmployeeById(
                  employee.id,
                );
              } catch (e) {
                debugPrint(
                  'Calendar employee load failed '
                      '${employee.id}: $e',
                );

                return <String, dynamic>{};
              }
            },
          ),
        );

        for (int i = 0; i < employeeResults.length; i++) {
          final response = employeeResults[i];
          final employee = employees[i];

          if (response.isEmpty) {
            continue;
          }

          final employeeName = _getEmployeeName(
            response,
            employee,
          );

          // ------------------------------------------------------
          // ATTENDANCE
          // ------------------------------------------------------

          final attendance = response['attendance'];

          if (attendance is List) {
            for (final item in attendance) {
              if (item is! Map) {
                continue;
              }

              final json = Map<String, dynamic>.from(item);

              final date = _extractDate(
                json,
                keys: const [
                  'date',
                  'attendanceDate',
                  'checkInDate',
                  'checkIn',
                  'createdAt',
                ],
              );

              if (date == null || !_isSameMonth(date, month)) {
                continue;
              }

              final normalized = <String, dynamic>{
                ...json,
                'id': _stringValue(
                  json['id'] ?? json['_id'],
                  fallback:
                  'attendance-${employee.id}-${date.toIso8601String()}',
                ),
                'date': date.toIso8601String(),
                'title': _stringValue(
                  json['title'],
                  fallback: 'Attendance',
                ),
                'type': 'attendance',
                'employeeId': employee.id,
                'employeeName': employeeName,
                'status': _stringValueOrNull(
                  json['status'],
                ),
                'startTime': _extractTime(
                  json,
                  const [
                    'checkIn',
                    'checkInTime',
                    'inTime',
                    'startTime',
                  ],
                ),
                'endTime': _extractTime(
                  json,
                  const [
                    'checkOut',
                    'checkOutTime',
                    'outTime',
                    'endTime',
                  ],
                ),
              };

              events.add(
                CalendarEvent.fromJson(normalized),
              );
            }
          }

          // ------------------------------------------------------
          // LEAVES
          // ------------------------------------------------------

          final leaves = response['leaves'];

          if (leaves is List) {
            for (final item in leaves) {
              if (item is! Map) {
                continue;
              }

              final json = Map<String, dynamic>.from(item);

              _addLeaveEvents(
                events: events,
                json: json,
                employee: employee,
                employeeName: employeeName,
                month: month,
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint(
        'Calendar attendance/leave error: $e',
      );
    }

    // ------------------------------------------------------------
    // 2. SHIFTS
    // ------------------------------------------------------------

    try {
      final response = await _apiClient.get(
        '/shifts',
      );

      final shifts = _extractList(
        response,
        possibleKeys: const [
          'shifts',
          'data',
          'items',
          'results',
        ],
      );

      for (final item in shifts) {
        if (item is! Map) {
          continue;
        }

        final json = Map<String, dynamic>.from(item);

        final date = _extractDate(
          json,
          keys: const [
            'date',
            'shiftDate',
            'assignedDate',
            'rosterDate',
            'startDate',
            'createdAt',
          ],
        );

        if (date == null || !_isSameMonth(date, month)) {
          continue;
        }

        final employeeId =
        _nestedString(
          json,
          [
            ['employeeId'],
            ['employee', '_id'],
            ['employee', 'id'],
          ],
        );

        final employeeName =
        _nestedString(
          json,
          [
            ['employeeName'],
            ['employee', 'name'],
          ],
        );

        final normalized = <String, dynamic>{
          ...json,
          'id': _stringValue(
            json['id'] ?? json['_id'],
            fallback:
            'shift-${date.toIso8601String()}',
          ),
          'date': date.toIso8601String(),
          'title': _stringValue(
            json['title'] ??
                json['name'] ??
                json['shiftName'],
            fallback: 'Shift',
          ),
          'type': 'shift',
          'employeeId': employeeId,
          'employeeName': employeeName,
          'status': _stringValueOrNull(
            json['status'],
          ),
          'startTime': _extractTime(
            json,
            const [
              'startTime',
              'start',
              'from',
            ],
          ),
          'endTime': _extractTime(
            json,
            const [
              'endTime',
              'end',
              'to',
            ],
          ),
          'description': _stringValueOrNull(
            json['description'],
          ),
        };

        events.add(
          CalendarEvent.fromJson(normalized),
        );
      }
    } catch (e) {
      debugPrint(
        'Calendar shift error: $e',
      );
    }

    // ------------------------------------------------------------
    // SORT
    // ------------------------------------------------------------

    events.sort(
          (a, b) {
        final dateCompare =
        a.date.compareTo(b.date);

        if (dateCompare != 0) {
          return dateCompare;
        }

        return (a.startTime ?? '')
            .compareTo(b.startTime ?? '');
      },
    );

    return events;
  }

  // ============================================================
  // LEAVE → CREATE EVENT FOR EACH DAY
  // ============================================================

  void _addLeaveEvents({
    required List<CalendarEvent> events,
    required Map<String, dynamic> json,
    required Employee employee,
    required String employeeName,
    required DateTime month,
  }) {
    final startDate = _extractDate(
      json,
      keys: const [
        'startDate',
        'fromDate',
        'date',
        'leaveDate',
      ],
    );

    final endDate = _extractDate(
      json,
      keys: const [
        'endDate',
        'toDate',
        'date',
        'leaveDate',
      ],
    );

    if (startDate == null) {
      return;
    }

    final finalEndDate =
        endDate ?? startDate;

    DateTime current = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    final last = DateTime(
      finalEndDate.year,
      finalEndDate.month,
      finalEndDate.day,
    );

    while (!current.isAfter(last)) {
      if (_isSameMonth(current, month)) {
        events.add(
          CalendarEvent(
            id: _stringValue(
              json['id'] ?? json['_id'],
              fallback:
              'leave-${employee.id}-${current.toIso8601String()}',
            ),
            date: current,
            title: _stringValue(
              json['title'] ??
                  json['leaveType'] ??
                  json['type'],
              fallback: 'Leave',
            ),
            type: CalendarEventType.leave,
            status: _stringValueOrNull(
              json['status'],
            ),
            employeeId: employee.id,
            employeeName: employeeName,
            description: _stringValueOrNull(
              json['reason'] ??
                  json['description'],
            ),
          ),
        );
      }

      current = current.add(
        const Duration(days: 1),
      );
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool _isSameMonth(
      DateTime date,
      DateTime month,
      ) {
    return date.year == month.year &&
        date.month == month.month;
  }

  DateTime? _extractDate(
      Map<String, dynamic> json, {
        required List<String> keys,
      }) {
    for (final key in keys) {
      final value = json[key];

      if (value == null) {
        continue;
      }

      final parsed =
      DateTime.tryParse(value.toString());

      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  String? _extractTime(
      Map<String, dynamic> json,
      List<String> keys,
      ) {
    for (final key in keys) {
      final value = json[key];

      if (value == null) {
        continue;
      }

      final text = value.toString().trim();

      if (text.isEmpty) {
        continue;
      }

      // If backend sends ISO datetime,
      // extract only the time part.
      final parsed = DateTime.tryParse(text);

      if (parsed != null) {
        final hour =
        parsed.hour.toString().padLeft(2, '0');

        final minute =
        parsed.minute.toString().padLeft(2, '0');

        return '$hour:$minute';
      }

      return text;
    }

    return null;
  }

  String _getEmployeeName(
      Map<String, dynamic> response,
      Employee employee,
      ) {
    final user = response['user'];

    if (user is Map) {
      final name = user['name']?.toString().trim();

      if (name != null && name.isNotEmpty) {
        return name;
      }
    }

    final employeeData =
    response['employee'];

    if (employeeData is Map) {
      final name =
      employeeData['name']?.toString().trim();

      if (name != null && name.isNotEmpty) {
        return name;
      }
    }

    return employee.name;
  }

  String _stringValue(
      dynamic value, {
        String fallback = '',
      }) {
    if (value == null) {
      return fallback;
    }

    final text =
    value.toString().trim();

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  String? _stringValueOrNull(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    final text =
    value.toString().trim();

    return text.isEmpty ? null : text;
  }

  String? _nestedString(
      Map<String, dynamic> json,
      List<List<String>> paths,
      ) {
    for (final path in paths) {
      dynamic current = json;

      for (final key in path) {
        if (current is Map &&
            current.containsKey(key)) {
          current = current[key];
        } else {
          current = null;
          break;
        }
      }

      if (current != null) {
        final text =
        current.toString().trim();

        if (text.isNotEmpty) {
          return text;
        }
      }
    }

    return null;
  }

  List<dynamic> _extractList(
      dynamic response, {
        required List<String> possibleKeys,
      }) {
    if (response is List) {
      return response;
    }

    if (response is Map) {
      for (final key in possibleKeys) {
        final value = response[key];

        if (value is List) {
          return value;
        }
      }
    }

    return [];
  }
}
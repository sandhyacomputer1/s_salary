// lib/features/employee/attendance/services/attendance_service.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../models/attendance_day_model.dart';
import '../models/attendance_summary_model.dart';

class AttendanceService {
  final ApiClient _client;

  AttendanceService({ApiClient? client}) : _client = client ?? ApiClient();

  /// GET /attendance/employee/:employeeId?month=&year=
  /// (the endpoint confirmed in Postman). If it fails, the old
  /// /attendance/my-history route is tried as a fallback.
  Future<List<AttendanceDayModel>> fetchHistory({
    required String employeeId,
    required int month,
    required int year,
  }) async {
    try {
      final data = await _client.get(
        '/attendance/employee/$employeeId?month=$month&year=$year',
      );
      return _parse(data);
    } catch (_) {
      final data = await _client.get(
        '/attendance/my-history?month=$month&year=$year',
      );
      return _parse(data);
    }
  }

  List<AttendanceDayModel> _parse(dynamic data) {
    dynamic list = data;

    if (data is Map) {
      list = data['records'] ?? data['data'] ?? data['attendance'];
    }

    if (list is! List) return const [];

    // DEBUG: prints a few raw records in the Run console so the field
    // names (for example "Marked by Admin") can be checked.
    if (kDebugMode) {
      var printed = 0;
      for (final item in list.whereType<Map>()) {
        if (printed >= 3) break;
        debugPrint('ATTENDANCE RAW: ${jsonEncode(item)}');
        printed++;
      }
    }

    // One entry per date (last one wins).
    final byDate = <String, AttendanceDayModel>{};
    for (final item in list.whereType<Map>()) {
      final day = AttendanceDayModel.fromJson(Map<String, dynamic>.from(item));
      if (day.date.isNotEmpty) byDate[day.date] = day;
    }
    return byDate.values.toList();
  }

  /// GET /shifts/my-shift -> weekly off weekdays (1 = Mon ... 7 = Sun).
  /// Falls back to Saturday + Sunday if the shift cannot be read.
  Future<Set<int>> fetchWeeklyOffs() async {
    try {
      final data = await _client.get('/shifts/my-shift');
      if (data is Map && data['weeklyOffs'] is List) {
        const names = {
          'monday': 1, 'tuesday': 2, 'wednesday': 3, 'thursday': 4,
          'friday': 5, 'saturday': 6, 'sunday': 7,
        };
        final result = <int>{};
        for (final o in data['weeklyOffs'] as List) {
          final n = names[o.toString().trim().toLowerCase()];
          if (n != null) result.add(n);
        }
        return result;
      }
    } catch (_) {}
    return {6, 7};
  }

  /// GET /attendance/employee/:employeeId/summary?month=&year=
  Future<AttendanceSummaryModel> fetchSummary({
    required String employeeId,
    required int month,
    required int year,
  }) async {
    final data = await _client.get(
      '/attendance/employee/$employeeId/summary?month=$month&year=$year',
    );
    if (data is! Map) return AttendanceSummaryModel.empty;
    return AttendanceSummaryModel.fromJson(Map<String, dynamic>.from(data));
  }
}

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService();
});
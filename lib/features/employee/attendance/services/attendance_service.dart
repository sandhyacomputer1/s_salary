// lib/features/employee/attendance/services/attendance_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../models/attendance_day_model.dart';
import '../models/attendance_summary_model.dart';

class AttendanceService {
  final ApiClient _client;

  AttendanceService({ApiClient? client})
      : _client = client ?? ApiClient();

  /// GET /attendance/my-history?month=&year=
  /// Returns a bare array of Attendance records.
  Future<List<AttendanceDayModel>> fetchMyHistory({
    required int month,
    required int year,
  }) async {
    final data = await _client.get(
      '/attendance/my-history?month=$month&year=$year',
    );
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => AttendanceDayModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
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
    return AttendanceSummaryModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }
}

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService();
});
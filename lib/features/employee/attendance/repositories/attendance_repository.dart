// lib/features/employee/attendance/repositories/attendance_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/secure_storage.dart';
import '../models/attendance_day_model.dart';
import '../models/attendance_summary_model.dart';
import '../services/attendance_service.dart';

/// Currently visible month/year on the calendar. Starts at "now".
final attendanceMonthProvider = StateProvider<int>((ref) {
  return DateTime.now().month;
});

final attendanceYearProvider = StateProvider<int>((ref) {
  return DateTime.now().year;
});

/// Resolves the authenticated employee's document id.
final attendanceEmployeeIdProvider = FutureProvider<String>((ref) async {
  final id = await SecureStorage.getEmployeeId();
  if (id == null || id.isEmpty) {
    throw Exception(
      'Employee profile is not linked to this account. Please contact HR.',
    );
  }
  return id;
});

class AttendanceRepository {
  final AttendanceService _service;
  AttendanceRepository(this._service);

  Future<List<AttendanceDayModel>> getMyHistory({
    required int month,
    required int year,
  }) {
    return _service.fetchMyHistory(month: month, year: year);
  }

  Future<AttendanceSummaryModel> getSummary({
    required String employeeId,
    required int month,
    required int year,
  }) {
    return _service.fetchSummary(
      employeeId: employeeId,
      month: month,
      year: year,
    );
  }
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.watch(attendanceServiceProvider));
});

/// Family provider keyed by (month, year) — one fetch per visible month.
final attendanceHistoryProvider = FutureProvider.autoDispose
    .family<List<AttendanceDayModel>, ({int month, int year})>(
        (ref, key) async {
      return ref.watch(attendanceRepositoryProvider).getMyHistory(
        month: key.month,
        year: key.year,
      );
    });

/// Summary for the current employee + visible month.
final attendanceSummaryProvider = FutureProvider.autoDispose
    .family<AttendanceSummaryModel, ({int month, int year})>(
        (ref, key) async {
      final employeeId = await ref.watch(attendanceEmployeeIdProvider.future);
      return ref.watch(attendanceRepositoryProvider).getSummary(
        employeeId: employeeId,
        month: key.month,
        year: key.year,
      );
    });
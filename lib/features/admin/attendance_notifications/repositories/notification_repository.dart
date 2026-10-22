// lib/features/admin/attendance_notifications/repositories/notification_repository.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../data/services/employee_service.dart';
import '../../../../data/models/employee.dart';
import '../models/admin_attendance_model.dart';
import '../services/notification_service.dart';

String getTodayDateString() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

final notificationRepositoryProvider = Provider((ref) {
  return NotificationRepository(ref.watch(notificationServiceProvider));
});

class NotificationRepository {
  final NotificationService _service;
  final EmployeeService _employeeService = EmployeeService();

  NotificationRepository(this._service);

  Future<List<AdminAttendanceModel>> getTodayRecords() async {
    final companyId = await SecureStorage.getCompanyId();
    if (companyId == null || companyId.isEmpty) {
      throw Exception('Company ID missing from session.');
    }

    // 1. Fetch raw attendance records for today
    final rawRecords = await _service.fetchTodayAttendance(
      companyId: companyId,
      date: getTodayDateString(),
    );

    if (rawRecords.isEmpty) return [];

    // 2. Fetch all active employees to build a lookup map
    // (We do this because the attendance API doesn't populate the employee name)
    List<Employee> employees = [];
    try {
      employees = await _employeeService.getEmployees(status: 'active');
    } catch (_) {
      // If this fails, we still show the attendance, just without names
    }

    final employeeMap = {for (var e in employees) e.id: e};

    // 3. Map the names to the attendance records
    return rawRecords.map((record) {
      final emp = employeeMap[record.employeeId];
      if (emp != null) {
        return AdminAttendanceModel(
          id: record.id,
          employeeId: record.employeeId,
          employeeName: emp.name,
          employeeCode: emp.employeeCode,
          date: record.date,
          status: record.status,
          isLate: record.isLate,
          lateByMinutes: record.lateByMinutes,
          checkInTime: record.checkInTime,
          checkOutTime: record.checkOutTime,
        );
      }
      return record;
    }).toList();
  }
}

/// State notifier that handles polling every 30 seconds
class TodayAttendanceNotifier extends AsyncNotifier<List<AdminAttendanceModel>> {
  Timer? _timer;

  @override
  Future<List<AdminAttendanceModel>> build() async {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      refresh();
    });

    ref.onDispose(() {
      _timer?.cancel();
    });

    return ref.watch(notificationRepositoryProvider).getTodayRecords();
  }

  Future<void> refresh() async {
    if (state.isLoading) return;

    try {
      final data = await ref.read(notificationRepositoryProvider).getTodayRecords();
      state = AsyncData(data);
    } catch (e, st) {
      if (!state.hasValue) {
        state = AsyncError(e, st);
      }
    }
  }
}

final todayAttendanceProvider =
AsyncNotifierProvider<TodayAttendanceNotifier, List<AdminAttendanceModel>>(() {
  return TodayAttendanceNotifier();
});
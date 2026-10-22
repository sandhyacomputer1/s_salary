// lib/features/admin/attendance_notifications/services/notification_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/admin_attendance_model.dart';

class NotificationService {
  final ApiClient _client;
  NotificationService({ApiClient? client}) : _client = client ?? ApiClient();

  /// GET /attendance/company/:companyId/today?date=YYYY-MM-DD
  Future<List<AdminAttendanceModel>> fetchTodayAttendance({
    required String companyId,
    required String date,
  }) async {
    final data = await _client.get(
      '/attendance/company/$companyId/today?date=$date',
    );

    if (data is! List) return const [];

    return data
        .whereType<Map>()
        .map((e) => AdminAttendanceModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
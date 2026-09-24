import '../../core/network/api_client.dart';

class AttendanceService {
  final ApiClient _apiClient = ApiClient();

  // ============================================================
  // GET MONTHLY ATTENDANCE
  //
  // Example:
  // /api/attendance/my-history?month=09&year=2026
  // ============================================================

  Future<List<Map<String, dynamic>>> getMonthlyAttendance({
    required int month,
    required int year,
  }) async {
    final monthString = month.toString().padLeft(2, '0');

    final response = await _apiClient.get(
      '/attendance/my-history?month=$monthString&year=$year',
    );

    return _extractList(response);
  }

  // ============================================================
  // RESPONSE LIST HANDLER
  // ============================================================

  List<Map<String, dynamic>> _extractList(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
      )
          .toList();
    }

    if (response is Map<String, dynamic>) {
      final possibleLists = [
        response['data'],
        response['records'],
        response['attendance'],
        response['history'],
        response['items'],
      ];

      for (final value in possibleLists) {
        if (value is List) {
          return value
              .whereType<Map>()
              .map(
                (item) => Map<String, dynamic>.from(item),
          )
              .toList();
        }
      }
    }

    return [];
  }
}
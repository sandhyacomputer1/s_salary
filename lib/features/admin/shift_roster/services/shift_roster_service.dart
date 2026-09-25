import '../../../../core/network/api_client.dart';

import '../models/roster_schedule_model.dart';
import '../models/shift_model.dart';

// =================================================================
// SHIFT ROSTER ENDPOINTS
// =================================================================

class ShiftRosterEndpoints {
  ShiftRosterEndpoints._();

  // ---------------------------------------------------------------
  // SHIFTS
  // ---------------------------------------------------------------

  static const String shifts = '/shifts';

  static String shift(String id) {
    return '/shifts/$id';
  }

  // ---------------------------------------------------------------
  // ROSTER
  // ---------------------------------------------------------------

  static const String rosterSchedules =
      '/shifts/roster';

  static const String assignRoster =
      '/shifts/roster';

  static String rosterSchedule(String id) {
    return '/shifts/roster/$id';
  }
}

// =================================================================
// SHIFT ROSTER SERVICE
// =================================================================

class ShiftRosterService {
  final ApiClient _apiClient = ApiClient();

  // ============================================================
  // SHIFTS
  // ============================================================

  Future<List<ShiftModel>> getShifts() async {
    final response = await _apiClient.get(
      ShiftRosterEndpoints.shifts,
    );

    // API should return:
    //
    // [
    //   {...},
    //   {...},
    //   {...}
    // ]

    if (response is! List) {
      throw Exception(
        'Invalid shifts response. Expected a list.',
      );
    }

    return response.map<ShiftModel>((json) {
      return ShiftModel.fromJson(
        Map<String, dynamic>.from(json),
      );
    }).toList();
  }

  // ============================================================
  // CREATE SHIFT
  // ============================================================

  Future<ShiftModel> createShift(
      Map<String, dynamic> data,
      ) async {
    final response = await _apiClient.post(
      ShiftRosterEndpoints.shifts,
      body: data,
    );

    if (response is! Map) {
      throw Exception(
        'Invalid create shift response.',
      );
    }

    return ShiftModel.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  // ============================================================
  // UPDATE SHIFT
  // ============================================================

  Future<ShiftModel> updateShift(
      String id,
      Map<String, dynamic> data,
      ) async {
    final response = await _apiClient.put(
      ShiftRosterEndpoints.shift(id),
      body: data,
    );

    if (response is! Map) {
      throw Exception(
        'Invalid update shift response.',
      );
    }

    return ShiftModel.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  // ============================================================
  // DELETE SHIFT
  // ============================================================

  Future<void> deleteShift(
      String id,
      ) async {
    await _apiClient.delete(
      ShiftRosterEndpoints.shift(id),
    );
  }

  // ============================================================
  // ASSIGN ROSTER
  // ============================================================

  Future<dynamic> assignRoster(
      Map<String, dynamic> data,
      ) async {
    return await _apiClient.post(
      ShiftRosterEndpoints.assignRoster,
      body: data,
    );
  }

  // ============================================================
  // GET ROSTER SCHEDULES
  // ============================================================

  Future<List<RosterScheduleModel>>
  getRosterSchedules() async {
    final response = await _apiClient.get(
      ShiftRosterEndpoints.rosterSchedules,
    );

    // Expected API response:
    //
    // [
    //   {
    //      "_id": "...",
    //      "employeeId": {...},
    //      "shiftId": {...},
    //      "startDate": "...",
    //      "endDate": "..."
    //   }
    // ]

    if (response is! List) {
      throw Exception(
        'Invalid roster schedules response. '
            'Expected a list.',
      );
    }

    return response.map<RosterScheduleModel>((json) {
      return RosterScheduleModel.fromJson(
        Map<String, dynamic>.from(json),
      );
    }).toList();
  }

  // ============================================================
  // DELETE ROSTER SCHEDULE
  // ============================================================

  Future<void> deleteRosterSchedule(
      String id,
      ) async {
    await _apiClient.delete(
      ShiftRosterEndpoints.rosterSchedule(id),
    );
  }
}
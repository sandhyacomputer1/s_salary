import '../../../../core/network/api_client.dart';
import '../models/roster_schedule_model.dart';
import '../models/shift_model.dart';

// =================================================================
// ENDPOINTS
//
// Confirmed against your API docs (sdocs.html), Shift Roster
// section — these are the ONLY 3 admin-facing routes actually
// documented there:
//
//   GET  /shifts          -> getShifts()
//   POST /shifts          -> createShift()
//   POST /shifts/roster   -> assignRoster()
//
// Everything else below (update shift, delete shift, list roster
// schedules, delete a roster schedule) has NO matching entry in
// your docs — the sidebar links to #shift-list / #shift-create /
// #shift-roster exist, but there is no corresponding request/
// response section anywhere in the file for update/delete/list.
//
// The 4 methods marked UNCONFIRMED below use the REST shape you
// originally asked for (PUT/DELETE /shifts/:id, GET/DELETE
// /roster-schedules). If your Express server doesn't have these
// routes yet, calling them will 404 — check your route file, or
// tell me the real paths and I'll fix this again.
// =================================================================

class ShiftRosterEndpoints {
  ShiftRosterEndpoints._();

  // ---- CONFIRMED (present in sdocs.html) ----
  static const String shifts = '/shifts';
  static const String assignRoster = '/shifts/roster';

  // ---- UNCONFIRMED — not found in sdocs.html, best-guess REST ----
  static String shift(String id) => '/shifts/$id';
  static const String rosterSchedules = '/roster-schedules';
  static String rosterSchedule(String id) => '/roster-schedules/$id';
}

// =================================================================
// SHIFT ROSTER SERVICE
//
// Screen -> Service -> ApiClient -> Backend. No http client of its
// own — everything goes through the existing ApiClient.
// =================================================================

class ShiftRosterService {
  final ApiClient _apiClient = ApiClient();

  // ------------------------------------------------------------
  // SHIFTS
  // ------------------------------------------------------------

  /// GET /shifts — CONFIRMED endpoint.
  Future<List<ShiftModel>> getShifts() async {
    final response = await _apiClient.get(ShiftRosterEndpoints.shifts);

    if (response is! List) {
      throw Exception('Invalid shifts response.');
    }

    return response
        .map((json) => ShiftModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  /// POST /shifts — CONFIRMED endpoint.
  Future<ShiftModel> createShift(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      ShiftRosterEndpoints.shifts,
      body: data,
    );

    if (response is! Map) {
      throw Exception('Invalid create shift response.');
    }

    return ShiftModel.fromJson(Map<String, dynamic>.from(response));
  }

  /// UNCONFIRMED — PUT /shifts/:id is not documented in sdocs.html.
  /// Verify this route exists on your Express server before relying
  /// on the Edit Shift button.
  Future<ShiftModel> updateShift(
      String id,
      Map<String, dynamic> data,
      ) async {
    final response = await _apiClient.put(
      ShiftRosterEndpoints.shift(id),
      body: data,
    );

    if (response is! Map) {
      throw Exception('Invalid update shift response.');
    }

    return ShiftModel.fromJson(Map<String, dynamic>.from(response));
  }

  /// UNCONFIRMED — DELETE /shifts/:id is not documented in
  /// sdocs.html. Verify this route exists before relying on the
  /// Delete Shift button.
  Future<void> deleteShift(String id) async {
    await _apiClient.delete(ShiftRosterEndpoints.shift(id));
  }

  // ------------------------------------------------------------
  // ROSTER
  // ------------------------------------------------------------

  /// POST /shifts/roster — CONFIRMED endpoint (the only real
  /// roster-related route in your docs).
  Future<RosterScheduleModel> assignRoster(Map<String, dynamic> data) async {
    final response = await _apiClient.post(
      ShiftRosterEndpoints.assignRoster,
      body: data,
    );

    if (response is! Map) {
      throw Exception('Invalid assign roster response.');
    }

    return RosterScheduleModel.fromJson(Map<String, dynamic>.from(response));
  }

  /// UNCONFIRMED — there is no documented endpoint anywhere in
  /// sdocs.html for listing all roster schedules. GET
  /// /roster-schedules is a guess. Until you confirm the real path
  /// (or add one), the "Active Employee Roster Schedules" table on
  /// the screen will show whatever this call returns — likely a
  /// 404 — so it degrades to the empty state rather than crashing.
  Future<List<RosterScheduleModel>> getRosterSchedules() async {
    final response = await _apiClient.get(
      ShiftRosterEndpoints.rosterSchedules,
    );

    if (response is! List) {
      throw Exception('Invalid roster schedules response.');
    }

    return response
        .map(
          (json) =>
          RosterScheduleModel.fromJson(Map<String, dynamic>.from(json)),
    )
        .toList();
  }

  /// UNCONFIRMED — no documented endpoint for removing a single
  /// roster schedule. DELETE /roster-schedules/:id is a guess.
  Future<void> deleteRosterSchedule(String id) async {
    await _apiClient.delete(ShiftRosterEndpoints.rosterSchedule(id));
  }
}
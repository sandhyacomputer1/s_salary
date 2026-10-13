import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../endpoints/field_tracking_endpoints.dart';
import '../models/field_employee_location_model.dart';
import '../models/location_history_model.dart';

/// Message is safe to show directly to the user.
class FieldTrackingException implements Exception {
  final String message;

  /// True when the session is gone and the UI should send the user to login.
  final bool isAuthError;

  const FieldTrackingException(this.message, {this.isAuthError = false});

  @override
  String toString() => message;
}

class FieldTrackingService {
  FieldTrackingService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  /// YYYY-MM-DD in the device's local calendar, as the API expects.
  static String apiDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // ============================================================
  // GET /attendance/company/:companyId/field-locations
  // The company id is the logged-in admin's, from SecureStorage.
  // ============================================================

  Future<List<FieldEmployeeLocation>> fetchFieldLocations() async {
    final companyId = await SecureStorage.getCompanyId();

    if (companyId == null || companyId.isEmpty) {
      throw const FieldTrackingException(
        'Company not found. Please log in again.',
        isAuthError: true,
      );
    }

    final data = await _guard(
      () => _client.get(FieldTrackingEndpoints.fieldLocations(companyId)),
    );

    if (data == null) return const [];

    if (data is! List && data is! Map) {
      throw const FieldTrackingException('Invalid field locations response.');
    }

    return FieldEmployeeLocation.listFromResponse(data);
  }

  // ============================================================
  // GET /attendance/employee/:employeeId/location-history?date=
  // ============================================================

  Future<LocationHistory> fetchHistory(String employeeId, DateTime date) async {
    if (employeeId.isEmpty) {
      throw const FieldTrackingException('Missing employee id.');
    }

    final day = apiDate(date);

    final data = await _guard(
      () =>
          _client.get(FieldTrackingEndpoints.locationHistory(employeeId, day)),
    );

    return LocationHistory.fromResponse(data, requestedDate: day);
  }

  // ============================================================
  // ERROR HANDLING
  //
  // ApiClient throws Exception('<server message>') for non-2xx
  // responses ({success:false, message}), so toString() is
  // "Exception: <message>". Anything else (no internet, timeout)
  // gets a friendly connectivity message.
  //
  // Note: ApiClient does not expose the HTTP status code, so a 404 ("nothing
  // for that period" per the API reference) appears as an error message with
  // a Retry button.
  // ============================================================

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on FieldTrackingException {
      rethrow;
    } catch (e) {
      const prefix = 'Exception: ';
      final text = e.toString();

      if (text.startsWith(prefix)) {
        final message = text.substring(prefix.length).trim();

        final isAuth =
            message.startsWith('Session expired') ||
            message.startsWith('Authentication required');

        throw FieldTrackingException(message, isAuthError: isAuth);
      }

      throw const FieldTrackingException(
        'Could not reach the server. Check your connection and try again.',
      );
    }
  }
}

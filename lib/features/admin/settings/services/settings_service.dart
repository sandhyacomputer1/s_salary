import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../endpoints/settings_endpoints.dart';
import '../models/company_profile_model.dart';
import '../models/company_settings_model.dart';
import '../models/settings_request.dart';

/// Message is safe to show directly to the user.
class SettingsException implements Exception {
  final String message;

  /// True when the session is gone and the UI should send the user to login.
  final bool isAuthError;

  const SettingsException(this.message, {this.isAuthError = false});

  @override
  String toString() => message;
}

class SettingsService {
  SettingsService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  // ============================================================
  // GET /companies/me  -> company + settings
  // ============================================================

  Future<CompanyBundle> fetch() async {
    final data = await _guard(() => _client.get(SettingsEndpoints.myCompany));

    if (data is! Map) {
      throw const SettingsException('Invalid company response.');
    }

    final bundle = CompanyBundle.fromResponse(data);

    if (bundle.profile.id.isEmpty) {
      throw const SettingsException('Company details were not returned.');
    }

    return bundle;
  }

  // ============================================================
  // PUT /companies/:id   (body is not documented: see settings_request.dart)
  // ============================================================

  Future<void> saveProfile(CompanyProfile profile) async {
    final id = await _companyId(profile.id);

    await _guard(
      () => _client.put(
        SettingsEndpoints.company(id),
        body: CompanyProfileRequest(profile).toJson(),
      ),
    );
  }

  // ============================================================
  // PUT /companies/:id/settings
  // ============================================================

  Future<void> saveSettings({
    required String companyId,
    required CompanySettings settings,
    required int radiusMeters,
  }) async {
    final id = await _companyId(companyId);

    await _guard(
      () => _client.put(
        SettingsEndpoints.settings(id),
        body: SettingsPayload.build(settings, radiusMeters: radiusMeters),
      ),
    );
  }

  /// The id from GET /companies/me, or the one saved at login.
  Future<String> _companyId(String fromServer) async {
    if (fromServer.isNotEmpty) return fromServer;

    final stored = await SecureStorage.getCompanyId();

    if (stored == null || stored.isEmpty) {
      throw const SettingsException(
        'Company not found. Please log in again.',
        isAuthError: true,
      );
    }

    return stored;
  }

  // ============================================================
  // ERROR HANDLING
  //
  // ApiClient throws Exception('<server message>') for non-2xx
  // responses ({success:false, message}), so toString() is
  // "Exception: <message>". Anything else (no internet, timeout)
  // gets a friendly connectivity message. Tokens are never logged.
  // ============================================================

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on SettingsException {
      rethrow;
    } catch (e) {
      const prefix = 'Exception: ';
      final text = e.toString();

      if (text.startsWith(prefix)) {
        final message = text.substring(prefix.length).trim();

        final isAuth =
            message.startsWith('Session expired') ||
            message.startsWith('Authentication required');

        throw SettingsException(message, isAuthError: isAuth);
      }

      throw const SettingsException(
        'Could not reach the server. Check your connection and try again.',
      );
    }
  }
}

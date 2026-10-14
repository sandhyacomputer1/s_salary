import '../../../../core/network/api_client.dart';
import '../endpoints/audit_trail_endpoints.dart';
import '../models/audit_log_model.dart';

/// Message is safe to show directly to the user.
class AuditTrailException implements Exception {
  final String message;

  /// True when the session is gone and the UI should send the user to login.
  final bool isAuthError;

  const AuditTrailException(this.message, {this.isAuthError = false});

  @override
  String toString() => message;
}

class AuditTrailService {
  AuditTrailService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  // ============================================================
  // GET /audit-logs?page=&limit=&search=&action=&status=
  //
  // Filters are percent-encoded by Uri (an email's "@" becomes %40).
  // The existing ApiClient adds the Bearer token and handles refresh.
  // ============================================================

  Future<AuditPage> fetchPage(AuditQuery query) async {
    final endpoint = Uri(
      path: AuditTrailEndpoints.auditLogs,
      queryParameters: query.toQueryParameters(),
    ).toString();

    final data = await _guard(() => _client.get(endpoint));

    if (data == null) {
      return AuditPage(
        logs: const [],
        page: query.page,
        limit: query.limit,
        total: 0,
        totalPages: 0,
      );
    }

    if (data is! List && data is! Map) {
      throw const AuditTrailException('Invalid audit log response.');
    }

    return AuditPage.fromResponse(
      data,
      requestedPage: query.page,
      limit: query.limit,
    );
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
    } on AuditTrailException {
      rethrow;
    } catch (e) {
      const prefix = 'Exception: ';
      final text = e.toString();

      if (text.startsWith(prefix)) {
        final message = text.substring(prefix.length).trim();

        final isAuth = message.startsWith('Session expired') ||
            message.startsWith('Authentication required');

        throw AuditTrailException(message, isAuthError: isAuth);
      }

      throw const AuditTrailException(
        'Could not reach the server. Check your connection and try again.',
      );
    }
  }
}
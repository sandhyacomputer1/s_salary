import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../session/session_events.dart';
import '../storage/secure_storage.dart';

/// Result of a refresh attempt.
enum _RefreshStatus {
  /// New tokens received and saved.
  refreshed,

  /// The server REFUSED the refresh token (expired / revoked).
  /// The session is over -> user must login again.
  rejected,

  /// Network problem or server error. The session is still valid, so the
  /// user must NOT be logged out. The request just fails for now.
  unavailable,
}

class _RefreshResult {
  final _RefreshStatus status;
  final String? accessToken;

  const _RefreshResult(this.status, [this.accessToken]);
}

class ApiClient {
  /// Shared by EVERY ApiClient instance. Each service creates its own
  /// ApiClient, so this must be static: only one refresh may run at a time.
  /// Everybody who needs a new token waits for the same refresh.
  static Future<_RefreshResult>? _refreshInFlight;

  // ============================
  // HEADERS
  // ============================

  Map<String, String> _jsonHeaders(String token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ============================
  // GET
  // ============================

  Future<dynamic> get(String endpoint) async {
    Future<http.Response> request(String token) {
      return http.get(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: _jsonHeaders(token),
      );
    }

    try {
      final response = await _sendWithRefresh(request);
      return _handleResponse(response);
    } catch (e) {
      throw Exception(_friendlyError(e)); // 👈 Added friendly error
    }
  }

  // ============================
  // POST
  // ============================

  Future<dynamic> post(
      String endpoint, {
        Map<String, dynamic>? body,
      }) async {
    Future<http.Response> request(String token) {
      return http.post(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: _jsonHeaders(token),
        body: body == null ? null : jsonEncode(body),
      );
    }

    try {
      final response = await _sendWithRefresh(request);
      return _handleResponse(response);
    } catch (e) {
      throw Exception(_friendlyError(e)); // 👈 Added friendly error
    }
  }

  // ============================
  // PUT
  // ============================

  Future<dynamic> put(
      String endpoint, {
        Map<String, dynamic>? body,
      }) async {
    Future<http.Response> request(String token) {
      return http.put(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: _jsonHeaders(token),
        body: body == null ? null : jsonEncode(body),
      );
    }

    try {
      final response = await _sendWithRefresh(request);
      return _handleResponse(response);
    } catch (e) {
      throw Exception(_friendlyError(e)); // 👈 Added friendly error
    }
  }

  // ============================
  // DELETE
  // ============================

  Future<dynamic> delete(String endpoint) async {
    Future<http.Response> request(String token) {
      return http.delete(
        Uri.parse('${ApiConstants.baseUrl}$endpoint'),
        headers: _jsonHeaders(token),
      );
    }

    try {
      final response = await _sendWithRefresh(request);
      return _handleResponse(response);
    } catch (e) {
      throw Exception(_friendlyError(e)); // 👈 Added friendly error
    }
  }

  // ============================================================
  // SEND REQUEST + AUTOMATIC TOKEN REFRESH
  // ============================================================

  Future<http.Response> _sendWithRefresh(
      Future<http.Response> Function(String token) request,
      ) async {
    final accessToken = await SecureStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      // No access token. A refresh token may still exist, so try it
      // before giving up.
      final newToken = await _refreshOrThrow();
      return request(newToken);
    }

    // First request
    final response = await request(accessToken);

    // 👇 CHANGE THIS LINE
    // If the server returns 401 (Unauthorized) OR 403 (Forbidden), try to refresh
    if (response.statusCode != 401 && response.statusCode != 403) {
      return response;
    }
    // ----------------------------------------------------------
    // ACCESS TOKEN EXPIRED
    // ----------------------------------------------------------
    debugPrint('ACCESS TOKEN EXPIRED. Refreshing...');

    // While this request was running, another one may already have
    // refreshed the token. Then just use the newer token.
    final stored = await SecureStorage.getAccessToken();

    if (stored != null && stored.isNotEmpty && stored != accessToken) {
      debugPrint('Token was already refreshed by another request.');
      return request(stored);
    }

    final newToken = await _refreshOrThrow();

    // Retry the original request with the new token.
    return request(newToken);
  }

  // ============================================================
  // REFRESH (shared + safe)
  // ============================================================

  /// Returns a new access token, or throws.
  /// Logs the user out ONLY if the server rejects the refresh token.
  Future<String> _refreshOrThrow() async {
    final result = await _refreshShared();

    switch (result.status) {
      case _RefreshStatus.refreshed:
        return result.accessToken!;

      case _RefreshStatus.rejected:
        SessionEvents.sessionExpired();
        throw Exception('Session expired. Please login again.');

      case _RefreshStatus.unavailable:
      // The session is NOT cleared: the user stays logged in and the
      // next attempt works again once the connection is back.
        throw Exception(
          'Could not reach the server. Please check your connection and '
              'try again.',
        );
    }
  }

  Future<_RefreshResult> _refreshShared() {
    final running = _refreshInFlight;
    if (running != null) return running;

    final future = _doRefresh().whenComplete(() => _refreshInFlight = null);
    _refreshInFlight = future;

    return future;
  }

  Future<_RefreshResult> _doRefresh() async {
    try {
      final refreshToken = await SecureStorage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('No refresh token found.');
        await SecureStorage.clearSession();
        return const _RefreshResult(_RefreshStatus.rejected);
      }

      final response = await http
          .post(
        Uri.parse('${ApiConstants.baseUrl}/auth/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refreshToken': refreshToken}),
      )
          .timeout(const Duration(seconds: 20));

      debugPrint('REFRESH TOKEN STATUS: ${response.statusCode}');

      // ------------------------------------------------------
      // SUCCESS
      // ------------------------------------------------------
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final tokens = _extractTokens(response.body);

        final newAccess = tokens?['accessToken']?.toString();
        final newRefresh = tokens?['refreshToken']?.toString();

        if (newAccess == null || newAccess.isEmpty) {
          // Server said OK but the answer has no token. That is an API
          // format problem, not an expired session: keep the user logged in.
          debugPrint('Refresh response has no access token.');
          return const _RefreshResult(_RefreshStatus.unavailable);
        }

        await SecureStorage.saveAccessToken(newAccess);

        // The backend may or may not rotate the refresh token.
        if (newRefresh != null && newRefresh.isNotEmpty) {
          await SecureStorage.saveRefreshToken(newRefresh);
        }

        debugPrint('Access token refreshed successfully.');
        return _RefreshResult(_RefreshStatus.refreshed, newAccess);
      }

      // ------------------------------------------------------
      // The server clearly REFUSED the refresh token
      // ------------------------------------------------------
      if (response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 403) {
        debugPrint('Refresh token rejected by the server.');
        await SecureStorage.clearSession();
        return const _RefreshResult(_RefreshStatus.rejected);
      }

      // 5xx, 429 ... the server has a problem. Not the user's fault.
      return const _RefreshResult(_RefreshStatus.unavailable);
    } catch (e) {
      // No internet, timeout, DNS, etc. The session is still valid.
      debugPrint('TOKEN REFRESH ERROR (session kept): $e');
      return const _RefreshResult(_RefreshStatus.unavailable);
    }
  }

  /// Finds the tokens in the usual response shapes:
  ///   { "tokens": { accessToken, refreshToken } }
  ///   { "data": { "tokens": { ... } } }
  ///   { "data": { accessToken, refreshToken } }
  ///   { accessToken, refreshToken }
  Map<String, dynamic>? _extractTokens(String body) {
    if (body.isEmpty) return null;

    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;

      Map<String, dynamic>? asMap(dynamic v) =>
          v is Map ? Map<String, dynamic>.from(v) : null;

      final root = Map<String, dynamic>.from(decoded);
      final data = asMap(root['data']);

      final candidates = <Map<String, dynamic>?>[
        asMap(root['tokens']),
        asMap(data?['tokens']),
        data,
        root,
      ];

      for (final c in candidates) {
        if (c != null && c['accessToken'] != null) return c;
      }
    } catch (_) {}

    return null;
  }

  // ============================
  // RESPONSE HANDLER
  // ============================

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Request failed. Status code: ${response.statusCode}';

      try {
        final errorData = jsonDecode(response.body);

        if (errorData is Map && errorData['message'] != null) {
          message = errorData['message'].toString();
        }
      } catch (_) {}

      throw Exception(message);
    }

    if (response.body.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw Exception('Server returned an invalid response.');
    }
  }

  // ============================================================
  // FRIENDLY ERROR HELPER (Added to catch sudden disconnects)
  // ============================================================
  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('timeout') ||
        msg.contains('failed host lookup')) {
      return 'No internet connection. Please check your network and try again.';
    }
    return e.toString().replaceFirst('Exception: ', '');
  }
}
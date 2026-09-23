import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  bool _isRefreshing = false;

  // ============================
  // HEADERS
  // ============================

  Future<Map<String, String>> _headers({
    String? token,
  }) async {
    final accessToken =
        token ?? await SecureStorage.getAccessToken();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (accessToken != null &&
        accessToken.isNotEmpty) {
      headers['Authorization'] =
      'Bearer $accessToken';
    }

    return headers;
  }

  // ============================
  // GET
  // ============================

  Future<dynamic> get(
      String endpoint,
      ) async {
    Future<http.Response> request(
        String token,
        ) {
      return http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}$endpoint',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    }

    final response = await _sendWithRefresh(
      request,
    );

    return _handleResponse(response);
  }

  // ============================
  // POST
  // ============================

  Future<dynamic> post(
      String endpoint, {
        Map<String, dynamic>? body,
      }) async {
    Future<http.Response> request(
        String token,
        ) {
      return http.post(
        Uri.parse(
          '${ApiConstants.baseUrl}$endpoint',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body == null
            ? null
            : jsonEncode(body),
      );
    }

    final response = await _sendWithRefresh(
      request,
    );

    return _handleResponse(response);
  }

  // ============================
  // PUT
  // ============================

  Future<dynamic> put(
      String endpoint, {
        Map<String, dynamic>? body,
      }) async {
    Future<http.Response> request(
        String token,
        ) {
      return http.put(
        Uri.parse(
          '${ApiConstants.baseUrl}$endpoint',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body == null
            ? null
            : jsonEncode(body),
      );
    }

    final response = await _sendWithRefresh(
      request,
    );

    return _handleResponse(response);
  }

  // ============================
  // DELETE
  // ============================

  Future<dynamic> delete(
      String endpoint,
      ) async {
    Future<http.Response> request(
        String token,
        ) {
      return http.delete(
        Uri.parse(
          '${ApiConstants.baseUrl}$endpoint',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    }

    final response = await _sendWithRefresh(
      request,
    );

    return _handleResponse(response);
  }

  // ============================================================
  // SEND REQUEST + AUTOMATIC TOKEN REFRESH
  // ============================================================

  Future<http.Response> _sendWithRefresh(
      Future<http.Response> Function(
          String token,
          ) request,
      ) async {
    final accessToken =
    await SecureStorage.getAccessToken();

    if (accessToken == null ||
        accessToken.isEmpty) {
      throw Exception(
        'Authentication required. Please login again.',
      );
    }

    // First request
    var response =
    await request(accessToken);

    // Token still valid
    if (response.statusCode != 401) {
      return response;
    }

    // ==========================================================
    // ACCESS TOKEN EXPIRED
    // ==========================================================

    debugPrint(
      'ACCESS TOKEN EXPIRED. Trying to refresh...',
    );

    final newAccessToken =
    await _refreshAccessToken();

    if (newAccessToken == null ||
        newAccessToken.isEmpty) {
      throw Exception(
        'Session expired. Please login again.',
      );
    }

    // ==========================================================
    // RETRY ORIGINAL REQUEST WITH NEW TOKEN
    // ==========================================================

    debugPrint(
      'Retrying request with new access token...',
    );

    response =
    await request(newAccessToken);

    return response;
  }

  // ============================================================
  // REFRESH ACCESS TOKEN
  // ============================================================

  Future<String?> _refreshAccessToken() async {
    // Prevent multiple simultaneous refresh requests.
    if (_isRefreshing) {
      return await SecureStorage.getAccessToken();
    }

    _isRefreshing = true;

    try {
      final refreshToken =
      await SecureStorage.getRefreshToken();

      if (refreshToken == null ||
          refreshToken.isEmpty) {
        debugPrint(
          'No refresh token found.',
        );

        await SecureStorage.clearSession();

        return null;
      }

      final response = await http.post(
        Uri.parse(
          '${ApiConstants.baseUrl}/auth/refresh-token',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      debugPrint(
        'REFRESH TOKEN STATUS: ${response.statusCode}',
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        debugPrint(
          'Refresh token failed.',
        );

        await SecureStorage.clearSession();

        return null;
      }

      if (response.body.isEmpty) {
        await SecureStorage.clearSession();
        return null;
      }

      final data =
      jsonDecode(response.body);

      if (data is! Map) {
        await SecureStorage.clearSession();
        return null;
      }

      final responseData =
      Map<String, dynamic>.from(data);

      // ========================================================
      // HANDLE:
      //
      // {
      //   "tokens": {
      //      "accessToken": "...",
      //      "refreshToken": "..."
      //   }
      // }
      //
      // ========================================================

      final tokens =
      responseData['tokens'];

      if (tokens is! Map) {
        debugPrint(
          'Refresh response does not contain tokens.',
        );

        await SecureStorage.clearSession();

        return null;
      }

      final newAccessToken =
      tokens['accessToken']
          ?.toString();

      final newRefreshToken =
      tokens['refreshToken']
          ?.toString();

      if (newAccessToken == null ||
          newAccessToken.isEmpty) {
        debugPrint(
          'New access token not received.',
        );

        await SecureStorage.clearSession();

        return null;
      }

      // Save new access token
      await SecureStorage.saveAccessToken(
        newAccessToken,
      );

      // Backend may or may not rotate
      // the refresh token.
      if (newRefreshToken != null &&
          newRefreshToken.isNotEmpty) {
        await SecureStorage.saveRefreshToken(
          newRefreshToken,
        );
      }

      debugPrint(
        'Access token refreshed successfully.',
      );

      return newAccessToken;
    } catch (e) {
      debugPrint(
        'TOKEN REFRESH ERROR: $e',
      );

      await SecureStorage.clearSession();

      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  // ============================
  // RESPONSE HANDLER
  // ============================

  dynamic _handleResponse(
      http.Response response,
      ) {
    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      String message =
          'Request failed. Status code: ${response.statusCode}';

      try {
        final errorData =
        jsonDecode(response.body);

        if (errorData is Map &&
            errorData['message'] != null) {
          message =
              errorData['message'].toString();
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
      throw Exception(
        'Server returned an invalid response.',
      );
    }
  }
}
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';

class AuthService {
  // ============================
  // LOGIN
  // ============================

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/auth/login',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    debugPrint(
      'LOGIN STATUS CODE: ${response.statusCode}',
    );

    debugPrint(
      'LOGIN RESPONSE BODY: ${response.body}',
    );

    return _handleResponse(response);
  }

  // ============================
  // VERIFY 2FA
  // ============================

  Future<Map<String, dynamic>> verify2FA({
    required String tempToken,
    required String otpCode,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}/auth/verify-2fa',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'tempToken': tempToken,
        'otpCode': otpCode,
      }),
    );

    debugPrint(
      '2FA STATUS CODE: ${response.statusCode}',
    );

    debugPrint(
      '2FA RESPONSE BODY: ${response.body}',
    );

    return _handleResponse(response);
  }

  // ============================
  // REFRESH ACCESS TOKEN
  // POST /auth/refresh-token
  // ============================

  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
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
      'REFRESH TOKEN STATUS CODE: ${response.statusCode}',
    );

    // Do NOT print the response body here.
    // It may contain access/refresh tokens.

    return _handleResponse(response);
  }

  // ============================
  // COMMON RESPONSE HANDLER
  // ============================

  Map<String, dynamic> _handleResponse(
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
      return {};
    }

    try {
      final data =
      jsonDecode(response.body);

      if (data is! Map) {
        throw Exception(
          'Invalid server response.',
        );
      }

      return Map<String, dynamic>.from(data);
    } catch (_) {
      throw Exception(
        'Server returned an invalid response.',
      );
    }
  }
}
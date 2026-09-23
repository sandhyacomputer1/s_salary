import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._();

  static const FlutterSecureStorage _storage =
  FlutterSecureStorage();

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String companyIdKey = 'company_id';
  static const String tempTokenKey = 'temp_token';

  // Save final login session
  static Future<void> saveLoginSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String role,
    String? companyId,
  }) async {
    await _storage.write(
      key: accessTokenKey,
      value: accessToken,
    );

    await _storage.write(
      key: refreshTokenKey,
      value: refreshToken,
    );

    await _storage.write(
      key: userIdKey,
      value: userId,
    );

    await _storage.write(
      key: userRoleKey,
      value: role,
    );

    if (companyId != null && companyId.isNotEmpty) {
      await _storage.write(
        key: companyIdKey,
        value: companyId,
      );
    }
  }

  // Save temporary token for 2FA
  static Future<void> saveTempToken(
      String tempToken,
      ) async {
    await _storage.write(
      key: tempTokenKey,
      value: tempToken,
    );
  }
  static Future<void> clearTempToken() async {
    await _storage.delete(
      key: tempTokenKey,
    );
  }
  static Future<String?> getAccessToken() async {
    return await _storage.read(
      key: accessTokenKey,
    );
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(
      key: refreshTokenKey,
    );
  }

  static Future<String?> getUserId() async {
    return await _storage.read(
      key: userIdKey,
    );
  }

  static Future<String?> getUserRole() async {
    return await _storage.read(
      key: userRoleKey,
    );
  }

  static Future<String?> getCompanyId() async {
    return await _storage.read(
      key: companyIdKey,
    );
  }

  static Future<String?> getTempToken() async {
    return await _storage.read(
      key: tempTokenKey,
    );
  }

  static Future<void> clearSession() async {
    await _storage.deleteAll();
  }

  static Future<void> saveAccessToken(
      String accessToken,
      ) async {
    await _storage.write(
      key: accessTokenKey,
      value: accessToken,
    );
  }

  static Future<void> saveRefreshToken(
      String refreshToken,
      ) async {
    await _storage.write(
      key: refreshTokenKey,
      value: refreshToken,
    );
  }

}
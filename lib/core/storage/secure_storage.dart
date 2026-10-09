import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._();

  static const FlutterSecureStorage _storage =
  FlutterSecureStorage();

  // ============================================================
  // STORAGE KEYS
  // ============================================================

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String companyIdKey = 'company_id';
  static const String employeeIdKey = 'employee_id';
  static const String tempTokenKey = 'temp_token';

  // ============================================================
  // SAVE FINAL LOGIN SESSION
  // ============================================================

  static Future<void> saveLoginSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String role,
    String? companyId,
    String? employeeId,
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

    if (employeeId != null && employeeId.isNotEmpty) {
      await _storage.write(
        key: employeeIdKey,
        value: employeeId,
      );
    }
  }

  // ============================================================
  // SAVE TEMPORARY TOKEN FOR 2FA
  // ============================================================

  static Future<void> saveTempToken(
      String tempToken,
      ) async {
    await _storage.write(
      key: tempTokenKey,
      value: tempToken,
    );
  }

  // ============================================================
  // CLEAR TEMP TOKEN
  // ============================================================

  static Future<void> clearTempToken() async {
    await _storage.delete(
      key: tempTokenKey,
    );
  }

  // ============================================================
  // GET ACCESS TOKEN
  // ============================================================

  static Future<String?> getAccessToken() async {
    return await _storage.read(
      key: accessTokenKey,
    );
  }

  // ============================================================
  // GET REFRESH TOKEN
  // ============================================================

  static Future<String?> getRefreshToken() async {
    return await _storage.read(
      key: refreshTokenKey,
    );
  }

  // ============================================================
  // GET USER ID
  // ============================================================

  static Future<String?> getUserId() async {
    return await _storage.read(
      key: userIdKey,
    );
  }

  // ============================================================
  // GET USER ROLE
  // ============================================================

  static Future<String?> getUserRole() async {
    return await _storage.read(
      key: userRoleKey,
    );
  }

  // ============================================================
  // GET COMPANY ID
  // ============================================================

  static Future<String?> getCompanyId() async {
    return await _storage.read(
      key: companyIdKey,
    );
  }

  // ============================================================
  // GET EMPLOYEE ID
  // ============================================================

  static Future<String?> getEmployeeId() async {
    return await _storage.read(
      key: employeeIdKey,
    );
  }

  // ============================================================
  // GET TEMP TOKEN
  // ============================================================

  static Future<String?> getTempToken() async {
    return await _storage.read(
      key: tempTokenKey,
    );
  }

  // ============================================================
  // CLEAR SESSION
  // ============================================================

  static Future<void> clearSession() async {
    await _storage.deleteAll();
  }

  // ============================================================
  // SAVE ACCESS TOKEN
  // ============================================================

  static Future<void> saveAccessToken(
      String accessToken,
      ) async {
    await _storage.write(
      key: accessTokenKey,
      value: accessToken,
    );
  }

  // ============================================================
  // SAVE REFRESH TOKEN
  // ============================================================

  static Future<void> saveRefreshToken(
      String refreshToken,
      ) async {
    await _storage.write(
      key: refreshTokenKey,
      value: refreshToken,
    );
  }
}
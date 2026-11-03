import 'package:flutter/foundation.dart' show debugPrint;

import '../../../../core/network/api_client.dart'; // TODO: fix path if different
import '../../../../core/storage/secure_storage.dart';

/// Who is logged in (shown at the bottom of the sidebar).
class AdminSessionProfile {
  final String name;
  final String roleLabel;

  /// Base role from the API: super_admin | admin | employee ('' = unknown).
  final String role;

  /// Admin sub-role from the API: owner | general_admin | hr | accountant |
  /// manager ('' = unknown or not an admin).
  final String subRole;

  /// Screens this sub-role may open, from the company's saved list
  /// (settings.rolePermissions), e.g. [dashboard, employees, leaves].
  /// Empty = the server did not send a list for this role.
  final List<String> permissions;

  /// This person's own employee record id ('' = no employee record).
  /// Used by "My Space" (own check-in, leaves, expenses, payslips).
  final String employeeId;

  const AdminSessionProfile({
    required this.name,
    required this.roleLabel,
    this.role = '',
    this.subRole = '',
    this.permissions = const [],
    this.employeeId = '',
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

/// Name + role of the person who is logged in (admin / owner / HR /
/// accountant / manager / employee). Works for every role, so the employee
/// dashboard can use it too.
///
///   name        <- GET /employees/me   (own profile)
///   role label  <- user.subRole  (owner | general_admin | hr | accountant | manager)
///                  found through the company (adminId / assignedAdmins)
///                  employees: their designation (or "Employee")
///   permissions <- settings.rolePermissions[subRole]  (same /employees/me answer)
///   employeeId  <- employee._id (same /employees/me answer)
class AdminSessionProfileService {
  final ApiClient _api = ApiClient();

  static String _s(dynamic v) => v == null ? '' : v.toString();
  static Map<String, dynamic> _m(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  static String _idOf(dynamic v) => v is Map ? _s(v['_id']) : _s(v);

  /// first non-empty text of the given values
  static String _first(List<dynamic> values) {
    for (final v in values) {
      final t = _s(v).trim();
      if (t.isNotEmpty && t != 'null') return t;
    }
    return '';
  }

  Future<AdminSessionProfile> load() async {
    var role = '';
    try {
      role = (await SecureStorage.getUserRole()) ?? '';
    } catch (_) {}

    var name = '';
    var designation = '';
    var userId = '';
    var subRole = '';

    // kept from the /employees/me answer (it also carries company + settings)
    var company = <String, dynamic>{};
    var rolePermissions = <String, dynamic>{};

    // 1) own profile
    var employeeDocId = '';
    try {
      final res = _m(await _api.get('/employees/me'));
      debugPrint('SESSION PROFILE RAW (/employees/me): $res'); // helps if a field is missing

      final emp = res['employee'] is Map ? _m(res['employee']) : res;

      // user object: populated emp.userId, or a separate { user: {...} } block
      final user = emp['userId'] is Map
          ? _m(emp['userId'])
          : (res['user'] is Map ? _m(res['user']) : <String, dynamic>{});

      name = _first([emp['name'], user['name'], res['name'], emp['fullName'], emp['employeeName']]);
      designation = _first([emp['designation'], res['designation']]);
      employeeDocId = _s(emp['_id']);
      userId = _first([_idOf(emp['userId']), user['_id'], user['id']]);
      subRole = _first([user['subRole'], res['subRole'], emp['subRole']]);

      company = _m(res['company']);
      rolePermissions = _m(_m(res['settings'])['rolePermissions']);
    } catch (e) {
      debugPrint('SESSION PROFILE: /employees/me failed: $e');
    }

    // 1b) name not in the profile answer -> find this person in the employee list
    if (name.isEmpty && (employeeDocId.isNotEmpty || userId.isNotEmpty)) {
      try {
        final res = await _api.get('/employees');
        final list = res is List
            ? res
            : (res is Map ? (res['employees'] ?? res['data'] ?? res['items']) : null);

        if (list is List) {
          for (final item in list) {
            final m = _m(item);
            final itemUser = m['userId'];
            final sameEmployee = employeeDocId.isNotEmpty && _s(m['_id']) == employeeDocId;
            final sameUser = userId.isNotEmpty && _idOf(itemUser) == userId;

            if (sameEmployee || sameUser) {
              name = _first([m['name'], itemUser is Map ? itemUser['name'] : null]);
              if (userId.isEmpty) userId = _idOf(itemUser);
              if (designation.isEmpty) designation = _s(m['designation']);
              if (employeeDocId.isEmpty) employeeDocId = _s(m['_id']);
              break;
            }
          }
        }
      } catch (e) {
        debugPrint('SESSION PROFILE: employee list lookup failed: $e');
      }
    }

    // 2) admin sub-role from the company (owner / hr / accountant / manager)
    if (subRole.isEmpty && role.toLowerCase() != 'employee' && userId.isNotEmpty) {
      try {
        // the company usually came with /employees/me already; ask again only if not
        if (company.isEmpty) {
          final res = _m(await _api.get('/companies/me'));
          company = res['company'] is Map ? _m(res['company']) : res;
        }

        if (_idOf(company['adminId']) == userId) {
          subRole = 'owner';
        } else if (company['assignedAdmins'] is List) {
          for (final a in company['assignedAdmins'] as List) {
            final item = _m(a);
            final id = _idOf(item['adminId'] ?? item['userId'] ?? item['admin']);
            if (id == userId) {
              subRole = _s(item['role']);
              break;
            }
          }
        }
      } catch (_) {}
    }

    // always keep the sub-role in one clean form: hr, accountant, ...
    subRole = subRole.trim().toLowerCase();

    // 3) screens this sub-role may open (company's saved list)
    var permissions = <String>[];
    final rawList = rolePermissions[subRole];
    if (rawList is List) {
      permissions = rawList
          .map((e) => _s(e).trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    debugPrint(
      'SESSION PROFILE: role="$role" subRole="$subRole" '
          'employeeId="$employeeDocId" permissions=$permissions',
    );

    final label = _label(role, subRole, designation);
    return AdminSessionProfile(
      name: name.trim().isEmpty ? label : name.trim(),
      roleLabel: label,
      role: role.trim().toLowerCase(),
      subRole: subRole,
      permissions: permissions,
      employeeId: employeeDocId.trim(),
    );
  }

  static String _label(String role, String subRole, String designation) {
    switch (subRole.toLowerCase()) {
      case 'owner':
        return 'Company Owner';
      case 'general_admin':
        return 'General Admin';
      case 'hr':
        return 'HR Admin';
      case 'accountant':
        return 'Accountant';
      case 'manager':
        return 'Manager';
    }
    if (role.toLowerCase() == 'employee') {
      return designation.isNotEmpty ? designation : 'Employee';
    }
    // Admin whose sub-role is unknown. A plain "Admin" label is used (not the
    // designation) so a job title like "Account Executive" can never be
    // mistaken for the Accountant role.
    return 'Admin';
  }
}
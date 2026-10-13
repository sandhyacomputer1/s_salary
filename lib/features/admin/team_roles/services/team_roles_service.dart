import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../data/models/employee.dart';
import '../../../../data/services/employee_service.dart';
import '../endpoints/team_roles_endpoints.dart';
import '../models/role_permission_model.dart';
import '../models/team_member_model.dart';
import '../models/team_request.dart';

/// Message is safe to show directly to the user.
class TeamRolesException implements Exception {
  final String message;

  /// True when the session is gone and the UI should send the user to login.
  final bool isAuthError;

  const TeamRolesException(this.message, {this.isAuthError = false});

  @override
  String toString() => message;
}

class TeamRolesService {
  TeamRolesService({
    ApiClient? client,
    EmployeeService? employeeService,
  })  : _client = client ?? ApiClient(),
        _employeeService = employeeService ?? EmployeeService();

  final ApiClient _client;
  final EmployeeService _employeeService;

  // ============================================================
  // GET /companies/sub-admins   (bare JSON array)
  // ============================================================

  Future<List<TeamMember>> fetchTeam() async {
    final data = await _guard(() => _client.get(TeamRolesEndpoints.subAdmins));

    if (data is! List) {
      throw const TeamRolesException('Invalid team response.');
    }

    return TeamMember.listFromResponse(data);
  }

  // ============================================================
  // GET /employees?status=active   (existing EmployeeService)
  // Used by the "Assign Role to Existing Employee" dropdown.
  // ============================================================

  Future<List<Employee>> fetchEmployees() {
    return _guard(() => _employeeService.getEmployees(status: 'active'));
  }

  // ============================================================
  // POST /companies/sub-admins
  // Mode A: existing employee.  Mode B: new employee + role.
  // Request bodies are unverified; see team_request.dart.
  // ============================================================

  Future<dynamic> assignToExistingEmployee(AssignExistingRequest request) {
    return _guard(
          () => _client.post(TeamRolesEndpoints.subAdmins, body: request.toJson()),
    );
  }

  Future<dynamic> createMember(CreateMemberRequest request) {
    return _guard(
          () => _client.post(TeamRolesEndpoints.subAdmins, body: request.toJson()),
    );
  }

  // ============================================================
  // PUT /companies/sub-admins/:adminId/role
  // ============================================================

  Future<dynamic> changeRole(String adminId, String role) {
    if (adminId.isEmpty) {
      throw const TeamRolesException('Missing member id.');
    }

    return _guard(
          () => _client.put(
        TeamRolesEndpoints.subAdminRole(adminId),
        body: ChangeRoleRequest(role: role).toJson(),
      ),
    );
  }

  // ============================================================
  // DELETE /companies/sub-admins/:adminId   (revoke admin role)
  // ============================================================

  Future<dynamic> revoke(String adminId) {
    if (adminId.isEmpty) {
      throw const TeamRolesException('Missing member id.');
    }

    return _guard(
          () => _client.delete(TeamRolesEndpoints.subAdminById(adminId)),
    );
  }

  // ============================================================
  // GET /companies/me  -> settings.rolePermissions
  // ============================================================

  Future<RolePermissions> fetchRolePermissions() async {
    final data = await _guard(() => _client.get(TeamRolesEndpoints.myCompany));
    return RolePermissions.fromResponse(data);
  }

  // ============================================================
  // PUT /companies/:id/settings   { rolePermissions: {...} }
  // The company id comes from SecureStorage (saved at login); if it is
  // missing it is read from GET /companies/me instead.
  // ============================================================

  Future<void> saveRolePermissions(RolePermissions permissions) async {
    var companyId = await SecureStorage.getCompanyId();

    if (companyId == null || companyId.isEmpty) {
      final me = await _guard(() => _client.get(TeamRolesEndpoints.myCompany));
      companyId = _companyIdFrom(me);
    }

    if (companyId == null || companyId.isEmpty) {
      throw const TeamRolesException(
        'Could not determine your company. Please log in again.',
      );
    }

    final id = companyId;

    await _guard(
          () => _client.put(
        TeamRolesEndpoints.companySettings(id),
        body: SaveRolePermissionsRequest(permissions: permissions).toJson(),
      ),
    );
  }

  String? _companyIdFrom(dynamic body) {
    if (body is! Map) return null;

    final company = body['company'];
    if (company is Map) {
      final id = company['_id']?.toString();
      if (id != null && id.isNotEmpty) return id;
    }

    return null;
  }

  // ============================================================
  // ERROR HANDLING
  //
  // ApiClient throws Exception('<server message>') for non-2xx
  // responses ({success:false, message}), so toString() is
  // "Exception: <message>". Anything else (no internet, timeout)
  // gets a friendly connectivity message.
  // ============================================================

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on TeamRolesException {
      rethrow;
    } catch (e) {
      const prefix = 'Exception: ';
      final text = e.toString();

      if (text.startsWith(prefix)) {
        final message = text.substring(prefix.length).trim();

        final isAuth = message.startsWith('Session expired') ||
            message.startsWith('Authentication required');

        throw TeamRolesException(message, isAuthError: isAuth);
      }

      throw const TeamRolesException(
        'Could not reach the server. Check your connection and try again.',
      );
    }
  }
}
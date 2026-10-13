/// Role values exactly as the backend sends and expects them.
class TeamRole {
  TeamRole._();

  static const String owner = 'owner';
  static const String generalAdmin = 'general_admin';
  static const String hr = 'hr';
  static const String accountant = 'accountant';
  static const String manager = 'manager';

  /// Roles shown in the dropdowns (as in the web screens).
  static const List<String> assignable = [hr, accountant, manager];

  /// When true, a role already held by someone is shown as "Occupied" and
  /// disabled. This rule comes from the web UI text ("Max 1 HR, 1 Accountant,
  /// 1 Manager"); it is NOT in the API reference. Set to false if the backend
  /// allows several people per role.
  static const bool enforceSingleRolePerCompany = true;

  static String label(String role) {
    switch (role) {
      case owner:
        return 'Owner';
      case generalAdmin:
        return 'General Admin';
      case hr:
        return 'HR Admin';
      case accountant:
        return 'Accountant';
      case manager:
        return 'Manager';
      default:
        if (role.isEmpty) return '-';
        return role[0].toUpperCase() + role.substring(1);
    }
  }

  /// Short title used on the permission role selector tabs.
  static String shortLabel(String role) {
    switch (role) {
      case hr:
        return 'HR';
      default:
        return label(role);
    }
  }

  /// Small caption next to the role name on the permission selector.
  static String tagline(String role) {
    switch (role) {
      case hr:
        return 'HR & Staff Ops';
      case accountant:
        return 'Payroll & Finance';
      case manager:
        return 'Full Dept Control';
      default:
        return '';
    }
  }

  /// Description shown on the role cards in the Add Team Member dialog.
  static String description(String role) {
    switch (role) {
      case hr:
        return 'Manage Employees, Attendance, Leaves & Documents';
      case accountant:
        return 'Manage Salary Structures, Payroll & Payslips';
      case manager:
        return 'View Team Overview & Approve Requests';
      default:
        return '';
    }
  }
}

/// One element of the GET /companies/sub-admins response array:
/// {
///   "_id", "name", "email", "phone", "role", "employeeId",
///   "employeeCode", "designation", "department", "createdAt"
/// }
class TeamMember {
  final String id; // _id (the admin user id; used for role change / revoke)
  final String name;
  final String email;
  final String phone;
  final String role; // owner | general_admin | hr | accountant | manager
  final String employeeId;
  final String employeeCode;
  final String designation;
  final String department;
  final DateTime? createdAt;

  const TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.employeeId,
    required this.employeeCode,
    required this.designation,
    required this.department,
    this.createdAt,
  });

  bool get isOwner => role == TeamRole.owner;

  String get roleLabel => TeamRole.label(role);

  String get initials {
    final clean = name.trim();
    if (clean.isEmpty) return '?';

    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();

    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    String text(dynamic v) => v?.toString().trim() ?? '';

    return TeamMember(
      id: text(json['_id'] ?? json['id']),
      name: text(json['name']),
      email: text(json['email']),
      phone: text(json['phone']),
      role: text(json['role']),
      employeeId: text(json['employeeId']),
      employeeCode: text(json['employeeCode']),
      designation: text(json['designation']),
      department: text(json['department']),
      createdAt: DateTime.tryParse(text(json['createdAt'])),
    );
  }

  /// The API returns a bare JSON array (no { data: [...] } envelope).
  static List<TeamMember> listFromResponse(dynamic body) {
    if (body is! List) return const [];

    return body
        .whereType<Map>()
        .map((e) => TeamMember.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
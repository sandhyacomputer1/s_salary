// !!! UNVERIFIED REQUEST BODIES !!!
// ANDROID_API_REFERENCE lists these endpoints but documents no bodies:
//   POST /companies/sub-admins
//   PUT  /companies/sub-admins/:adminId/role
//   PUT  /companies/:id/settings   (rolePermissions is not in the documented body)
//
// This is the ONLY file that contains the guessed keys. If the backend
// rejects one, its message is shown in the dialog; fix it here.
//
// Evidence:
//   - { "role": "hr|accountant|manager|general_admin" } is the documented body
//     of the super-admin variant of the role-change endpoint, so ChangeRole
//     is the most likely correct one.
//   - rolePermissions is the key inside the settings object returned by GET.
//   - everything else (employeeId, name, email, password, ...) is a guess.

import 'role_permission_model.dart';

/// Mode A: assign an admin role to an EXISTING employee.
class AssignExistingRequest {
  final String employeeId;
  final String role;

  const AssignExistingRequest({
    required this.employeeId,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    'employeeId': employeeId, // GUESS
    'role': role,
  };
}

/// Mode B: create a NEW employee and give them an admin role in one call.
/// GUESS: a single POST /companies/sub-admins. If the backend instead expects
/// POST /employees first (documented body: name, email, phone, designation,
/// department, dateOfJoining, employmentType, workMode, portalAccess), then
/// the assign call, tell me and I'll split it into two requests.
class CreateMemberRequest {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String designation;
  final String department;
  final String monthlySalary;
  final String role;

  const CreateMemberRequest({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.designation,
    required this.department,
    required this.monthlySalary,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'password': password, // never trimmed, never logged or displayed
      'role': role,
    };

    void put(String key, String value) {
      final text = value.trim();
      if (text.isNotEmpty) body[key] = text;
    }

    put('phone', phone);
    put('designation', designation);
    put('department', department);

    final salary = double.tryParse(monthlySalary.trim());
    if (salary != null) body['monthlySalary'] = salary;

    return body;
  }
}

/// PUT /companies/sub-admins/:adminId/role
class ChangeRoleRequest {
  final String role;

  const ChangeRoleRequest({required this.role});

  Map<String, dynamic> toJson() => {'role': role};
}

/// PUT /companies/:id/settings
/// Sends every configured role so a partial list can't wipe the others.
class SaveRolePermissionsRequest {
  final RolePermissions permissions;

  const SaveRolePermissionsRequest({required this.permissions});

  Map<String, dynamic> toJson() => {
    'rolePermissions': permissions.toJson(),
  };
}
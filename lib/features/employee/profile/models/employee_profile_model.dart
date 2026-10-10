// lib/features/employee/profile/models/employee_profile_model.dart

import 'employee_profile_details_model.dart';

/// Root of `GET /employees/me`.
///
/// Response shape:
/// {
///   "employee": { ... },
///   "user": { ... },
///   "company": { ... },
///   "settings": { ... }
/// }
class EmployeeProfileModel {
  final EmployeeDocument employee;
  final ProfileUser user;
  final ProfileCompany? company;

  const EmployeeProfileModel({
    required this.employee,
    required this.user,
    this.company,
  });

  /// Employee document `_id`. This is the id used by
  /// `PUT /employees/:id/personal-details`.
  /// It is NOT the user id.
  String get employeeDocId => employee.id;

  factory EmployeeProfileModel.fromJson(Map<String, dynamic> json) {
    return EmployeeProfileModel(
      employee: EmployeeDocument.fromJson(
        _asMap(json['employee']),
      ),
      user: ProfileUser.fromJson(
        _asMap(json['user']),
      ),
      company: json['company'] is Map
          ? ProfileCompany.fromJson(_asMap(json['company']))
          : null,
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const {};
  }
}

class EmployeeDocument {
  final String id;
  final String employeeCode;
  final String designation;
  final String department;
  final String workMode;       // in_house | field
  final String status;         // active | on_leave | terminated
  final String employmentType; // full_time | part_time | contract | intern
  final PersonalDetails personalDetails;
  final BankDetails bankDetails;

  const EmployeeDocument({
    required this.id,
    required this.employeeCode,
    required this.designation,
    required this.department,
    required this.workMode,
    required this.status,
    required this.employmentType,
    required this.personalDetails,
    required this.bankDetails,
  });

  factory EmployeeDocument.fromJson(Map<String, dynamic> j) {
    return EmployeeDocument(
      id: (j['_id'] ?? '').toString(),
      employeeCode: (j['employeeCode'] ?? '').toString(),
      designation: (j['designation'] ?? '').toString(),
      department: (j['department'] ?? '').toString(),
      workMode: (j['workMode'] ?? '').toString(),
      status: (j['status'] ?? '').toString(),
      employmentType: (j['employmentType'] ?? '').toString(),
      personalDetails: PersonalDetails.fromJson(
        EmployeeProfileModel._asMap(j['personalDetails']),
      ),
      bankDetails: BankDetails.fromJson(
        EmployeeProfileModel._asMap(j['bankDetails']),
      ),
    );
  }
}

class ProfileUser {
  final String id;
  final String name;
  final String email;
  final String phone;

  const ProfileUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory ProfileUser.fromJson(Map<String, dynamic> j) {
    return ProfileUser(
      id: (j['_id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      email: (j['email'] ?? '').toString(),
      phone: (j['phone'] ?? '').toString(),
    );
  }
}

class ProfileCompany {
  final String id;
  final String name;
  final String timezone;

  const ProfileCompany({
    required this.id,
    required this.name,
    required this.timezone,
  });

  factory ProfileCompany.fromJson(Map<String, dynamic> j) {
    return ProfileCompany(
      id: (j['_id'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      timezone: (j['timezone'] ?? '').toString(),
    );
  }
}
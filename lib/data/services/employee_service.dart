// import 'package:flutter/foundation.dart';
//
// import '../../core/network/api_client.dart';
// import '../models/employee.dart';
//
// class EmployeeService {
//   final ApiClient _apiClient = ApiClient();
//
//   // ============================================================
//   // GET DEPARTMENTS
//   // ============================================================
//
//   Future<dynamic> getDepartments() async {
//     return await _apiClient.get(
//       '/departments',
//     );
//   }
//
//   // ============================================================
//   // GET EMPLOYEES
//   // GET /employees
//   // ============================================================
//
//   Future<List<Employee>> getEmployees({
//     String? status,
//     String? department,
//   }) async {
//     String endpoint = '/employees';
//
//     final queryParams = <String, String>{};
//
//     if (status != null &&
//         status.isNotEmpty) {
//       queryParams['status'] = status;
//     }
//
//     if (department != null &&
//         department.isNotEmpty) {
//       queryParams['department'] =
//           department;
//     }
//
//     if (queryParams.isNotEmpty) {
//       endpoint +=
//       '?${Uri(
//         queryParameters:
//         queryParams,
//       ).query}';
//     }
//
//     final response =
//     await _apiClient.get(
//       endpoint,
//     );
//
//     if (response is! List) {
//       throw Exception(
//         'Invalid employees response.',
//       );
//     }
//
//     return response
//         .map(
//           (json) =>
//           Employee.fromJson(
//             Map<String, dynamic>.from(
//               json,
//             ),
//           ),
//     )
//         .toList();
//   }
//
//   // ============================================================
//   // GET ARCHIVED EMPLOYEES
//   // GET /employees?status=terminated
//   // ============================================================
//
//   Future<List<Employee>>
//   getArchivedEmployees() async {
//     final response =
//     await _apiClient.get(
//       '/employees?status=terminated',
//     );
//
//     if (response is! List) {
//       throw Exception(
//         'Invalid archived employees response.',
//       );
//     }
//
//     return response
//         .map(
//           (json) =>
//           Employee.fromJson(
//             Map<String, dynamic>.from(
//               json,
//             ),
//           ),
//     )
//         .toList();
//   }
//
//   // ============================================================
//   // GET EMPLOYEE DETAILS
//   // GET /employees/:id
//   // ============================================================
//
//   Future<Map<String, dynamic>>
//   getEmployeeById(
//       String employeeId,
//       ) async {
//     debugPrint(
//       'GET EMPLOYEE DETAILS: '
//           '/employees/$employeeId',
//     );
//
//     final response =
//     await _apiClient.get(
//       '/employees/$employeeId',
//     );
//
//     debugPrint(
//       'EMPLOYEE DETAILS RESPONSE: '
//           '$response',
//     );
//
//     if (response is! Map) {
//       throw Exception(
//         'Invalid employee details response.',
//       );
//     }
//
//     return Map<String, dynamic>.from(
//       response,
//     );
//   }
//
//   // ============================================================
//   // GET EMPLOYEE PHONE
//   //
//   // Used by Admin Dashboard when the employee list API
//   // does not return phone.
//   // ============================================================
//
//   Future<String> getEmployeePhone(
//       String employeeId,
//       ) async {
//     final response =
//     await getEmployeeById(
//       employeeId,
//     );
//
//     // ----------------------------------------------------------
//     // Try user.phone
//     // ----------------------------------------------------------
//
//     final user =
//     response['user'];
//
//     if (user is Map) {
//       final phone =
//           user['phone']?.toString() ??
//               '';
//
//       if (phone.isNotEmpty) {
//         return phone;
//       }
//     }
//
//     // ----------------------------------------------------------
//     // Try employee.phone
//     // ----------------------------------------------------------
//
//     final employee =
//     response['employee'];
//
//     if (employee is Map) {
//       final phone =
//           employee['phone']?.toString() ??
//               '';
//
//       if (phone.isNotEmpty) {
//         return phone;
//       }
//     }
//
//     // ----------------------------------------------------------
//     // Try personalDetails.phone
//     // ----------------------------------------------------------
//
//     final personalDetails =
//     response['personalDetails'];
//
//     if (personalDetails is Map) {
//       final phone =
//           personalDetails['phone']
//               ?.toString() ??
//               '';
//
//       if (phone.isNotEmpty) {
//         return phone;
//       }
//     }
//
//     // ----------------------------------------------------------
//     // Try root phone
//     // ----------------------------------------------------------
//
//     return response['phone']
//         ?.toString() ??
//         '';
//   }
//
//   // ============================================================
//   // UPDATE EMPLOYEE
//   // PUT /employees/:id
//   // ============================================================
//
//   Future<dynamic> updateEmployee({
//     required String employeeId,
//     required Map<String, dynamic> data,
//   }) async {
//     return await _apiClient.put(
//       '/employees/$employeeId',
//       body: data,
//     );
//   }
//
//   // ============================================================
//   // UPDATE PERSONAL DETAILS
//   // PUT /employees/:id/personal-details
//   // ============================================================
//
//   Future<dynamic>
//   updatePersonalDetails({
//     required String employeeId,
//     required String phone,
//     required String address,
//     required String emergencyName,
//     required String emergencyRelationship,
//     required String emergencyPhone,
//   }) async {
//     return await _apiClient.put(
//       '/employees/$employeeId/personal-details',
//       body: {
//         'phone': phone,
//         'address': address,
//
//         // Backend currently expects
//         // emergencyContact as STRING.
//         'emergencyContact':
//         emergencyPhone,
//       },
//     );
//   }
//
//   // ============================================================
//   // CREATE EMPLOYEE
//   // POST /employees
//   // ============================================================
//
//   Future<Map<String, dynamic>>
//   createEmployee({
//     required String name,
//     required String email,
//     required String phone,
//     required String password,
//     required String designation,
//     required String department,
//     required double monthlySalary,
//     required String employmentType,
//     required String workMode,
//     required String accountNumber,
//     required String ifsc,
//     required String bankName,
//     required String upiId,
//   }) async {
//     final response =
//     await _apiClient.post(
//       '/employees',
//       body: {
//         'name': name,
//         'email': email,
//         'phone': phone,
//         'password': password,
//         'designation': designation,
//         'department': department,
//         'monthlySalary':
//         monthlySalary,
//         'employmentType':
//         employmentType,
//         'workMode': workMode,
//         'bankDetails': {
//           'accountNumber':
//           accountNumber,
//           'ifsc': ifsc,
//           'bankName': bankName,
//           'upiId': upiId,
//         },
//       },
//     );
//
//     if (response is! Map) {
//       throw Exception(
//         'Invalid create employee response.',
//       );
//     }
//
//     return Map<String, dynamic>.from(
//       response,
//     );
//   }
//
//   // ============================================================
//   // DELETE / ARCHIVE EMPLOYEE
//   // DELETE /employees/:id
//   // ============================================================
//
//   Future<dynamic> deleteEmployee(
//       String employeeId,
//       ) async {
//     return await _apiClient.delete(
//       '/employees/$employeeId',
//     );
//   }
//
//   // ============================================================
//   // RESTORE EMPLOYEE
//   // PUT /employees/:id/restore
//   // ============================================================
//
//   Future<dynamic> restoreEmployee(
//       String employeeId,
//       ) async {
//     return await _apiClient.put(
//       '/employees/$employeeId/restore',
//     );
//   }
// }


import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../models/employee.dart';

class EmployeeService {
  final ApiClient _apiClient = ApiClient();

  // ============================================================
  // GET DEPARTMENTS
  // ============================================================

  Future<dynamic> getDepartments() async {
    return await _apiClient.get(
      '/departments',
    );
  }

  // ============================================================
  // GET EMPLOYEES
  // GET /employees
  // ============================================================

  Future<List<Employee>> getEmployees({
    String? status,
    String? department,
  }) async {
    String endpoint = '/employees';

    final queryParams = <String, String>{};

    if (status != null &&
        status.isNotEmpty) {
      queryParams['status'] = status;
    }

    if (department != null &&
        department.isNotEmpty) {
      queryParams['department'] =
          department;
    }

    if (queryParams.isNotEmpty) {
      endpoint +=
      '?${Uri(
        queryParameters:
        queryParams,
      ).query}';
    }

    final response =
    await _apiClient.get(
      endpoint,
    );

    if (response is! List) {
      throw Exception(
        'Invalid employees response.',
      );
    }

    return response
        .map(
          (json) =>
          Employee.fromJson(
            Map<String, dynamic>.from(
              json,
            ),
          ),
    )
        .toList();
  }

  // ============================================================
  // GET ARCHIVED EMPLOYEES
  // GET /employees?status=terminated
  // ============================================================

  Future<List<Employee>>
  getArchivedEmployees() async {
    final response =
    await _apiClient.get(
      '/employees?status=terminated',
    );

    if (response is! List) {
      throw Exception(
        'Invalid archived employees response.',
      );
    }

    return response
        .map(
          (json) =>
          Employee.fromJson(
            Map<String, dynamic>.from(
              json,
            ),
          ),
    )
        .toList();
  }

  // ============================================================
  // GET EMPLOYEE DETAILS
  // GET /employees/:id
  // ============================================================

  Future<Map<String, dynamic>>
  getEmployeeById(
      String employeeId,
      ) async {
    debugPrint(
      'GET EMPLOYEE DETAILS: '
          '/employees/$employeeId',
    );

    final response =
    await _apiClient.get(
      '/employees/$employeeId',
    );

    debugPrint(
      'EMPLOYEE DETAILS RESPONSE: '
          '$response',
    );

    if (response is! Map) {
      throw Exception(
        'Invalid employee details response.',
      );
    }

    return Map<String, dynamic>.from(
      response,
    );
  }

  // ============================================================
  // GET EMPLOYEE PHONE
  //
  // Used by Admin Dashboard when the employee list API
  // does not return phone.
  // ============================================================

  Future<String> getEmployeePhone(
      String employeeId,
      ) async {
    final response =
    await getEmployeeById(
      employeeId,
    );

    // ----------------------------------------------------------
    // Try user.phone
    // ----------------------------------------------------------

    final user =
    response['user'];

    if (user is Map) {
      final phone =
          user['phone']?.toString() ??
              '';

      if (phone.isNotEmpty) {
        return phone;
      }
    }

    // ----------------------------------------------------------
    // Try employee.phone
    // ----------------------------------------------------------

    final employee =
    response['employee'];

    if (employee is Map) {
      final phone =
          employee['phone']?.toString() ??
              '';

      if (phone.isNotEmpty) {
        return phone;
      }
    }

    // ----------------------------------------------------------
    // Try personalDetails.phone
    // ----------------------------------------------------------

    final personalDetails =
    response['personalDetails'];

    if (personalDetails is Map) {
      final phone =
          personalDetails['phone']
              ?.toString() ??
              '';

      if (phone.isNotEmpty) {
        return phone;
      }
    }

    // ----------------------------------------------------------
    // Try root phone
    // ----------------------------------------------------------

    return response['phone']
        ?.toString() ??
        '';
  }

  // ============================================================
  // UPDATE EMPLOYEE
  // PUT /employees/:id
  //
  // Used for job / employment / bank / status fields, i.e.
  // everything the Edit Employee screen collects EXCEPT the
  // personal-details block below.
  // ============================================================

  Future<dynamic> updateEmployee({
    required String employeeId,
    required Map<String, dynamic> data,
  }) async {
    return await _apiClient.put(
      '/employees/$employeeId',
      body: data,
    );
  }

  // ============================================================
  // UPDATE PERSONAL DETAILS
  // PUT /employees/:id/personal-details
  // ============================================================

  Future<dynamic>
  updatePersonalDetails({
    required String employeeId,
    required String phone,
    required String address,
    required String emergencyName,
    required String emergencyRelationship,
    required String emergencyPhone,
  }) async {
    return await _apiClient.put(
      '/employees/$employeeId/personal-details',
      body: {
        'phone': phone,
        'address': address,

        // Backend currently expects
        // emergencyContact as STRING.
        'emergencyContact':
        emergencyPhone,
      },
    );
  }

  // ============================================================
  // CREATE EMPLOYEE
  // POST /employees
  // ============================================================

  Future<Map<String, dynamic>>
  createEmployee({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String designation,
    required String department,
    required double monthlySalary,
    required String employmentType,
    required String workMode,
    required DateTime dateOfJoining,
    String? adminRole,
    required String accountNumber,
    required String ifsc,
    required String bankName,
    required String upiId,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'designation': designation,
      'department': department,
      'monthlySalary':
      monthlySalary,
      'employmentType':
      employmentType,
      'workMode': workMode,

      // ISO date string, e.g. "2026-09-22".
      'dateOfJoining':
      dateOfJoining.toIso8601String().split('T').first,

      'bankDetails': {
        'accountNumber':
        accountNumber,
        'ifsc': ifsc,
        'bankName': bankName,
        'upiId': upiId,
      },
    };

    // Only send adminRole when the admin actually picked one.
    // ('none' means standard employee — leave it out.)
    if (adminRole != null &&
        adminRole.isNotEmpty &&
        adminRole != 'none') {
      body['adminRole'] = adminRole;
    }

    final response =
    await _apiClient.post(
      '/employees',
      body: body,
    );

    if (response is! Map) {
      throw Exception(
        'Invalid create employee response.',
      );
    }

    return Map<String, dynamic>.from(
      response,
    );
  }

  // ============================================================
  // DELETE / ARCHIVE EMPLOYEE
  // DELETE /employees/:id
  // ============================================================

  Future<dynamic> deleteEmployee(
      String employeeId,
      ) async {
    return await _apiClient.delete(
      '/employees/$employeeId',
    );
  }

  // ============================================================
  // RESTORE EMPLOYEE
  // PUT /employees/:id/restore
  // ============================================================

  Future<dynamic> restoreEmployee(
      String employeeId,
      ) async {
    return await _apiClient.put(
      '/employees/$employeeId/restore',
    );
  }
}
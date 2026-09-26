// import '../../../../core/network/api_client.dart';
//
// import '../endpoints/department_endpoints.dart';
// import '../models/department_employee_model.dart';
// import '../models/department_model.dart';
// import '../models/move_employees_request.dart';
//
// // =================================================================
// // DEPARTMENT SERVICE
// // =================================================================
//
// class DepartmentService {
//   final ApiClient _apiClient = ApiClient();
//
//   // ===============================================================
//   // GET DEPARTMENTS
//   // ===============================================================
//
//   Future<List<DepartmentModel>> getDepartments() async {
//     final response = await _apiClient.get(
//       DepartmentEndpoints.departments,
//     );
//
//     if (response is! List) {
//       throw Exception('Invalid departments response.');
//     }
//
//     return response
//         .map(
//           (json) => DepartmentModel.fromJson(
//         Map<String, dynamic>.from(json),
//       ),
//     )
//         .toList();
//   }
//
//   // ===============================================================
//   // CREATE DEPARTMENT
//   // ===============================================================
//
//   Future<DepartmentModel> createDepartment(
//       Map<String, dynamic> data,
//       ) async {
//     final response = await _apiClient.post(
//       DepartmentEndpoints.departments,
//       body: data,
//     );
//
//     if (response is! Map) {
//       throw Exception('Invalid create department response.');
//     }
//
//     return DepartmentModel.fromJson(
//       Map<String, dynamic>.from(response),
//     );
//   }
//
//   // ===============================================================
//   // UPDATE DEPARTMENT
//   // ===============================================================
//
//   Future<DepartmentModel> updateDepartment(
//       String id,
//       Map<String, dynamic> data,
//       ) async {
//     final response = await _apiClient.put(
//       DepartmentEndpoints.department(id),
//       body: data,
//     );
//
//     if (response is! Map) {
//       throw Exception('Invalid update department response.');
//     }
//
//     return DepartmentModel.fromJson(
//       Map<String, dynamic>.from(response),
//     );
//   }
//
//   // ===============================================================
//   // DELETE DEPARTMENT
//   // ===============================================================
//
//   Future<void> deleteDepartment(String id) async {
//     await _apiClient.delete(
//       DepartmentEndpoints.department(id),
//     );
//   }
//
//   // ===============================================================
//   // GET DEPARTMENT EMPLOYEES
//   //
//   // This endpoint returns a LIST of employees.
//   // ===============================================================
//
//   Future<List<DepartmentEmployeeModel>> getDepartmentEmployees(
//       String departmentId,
//       ) async {
//     final response = await _apiClient.get(
//       DepartmentEndpoints.departmentEmployees(
//         departmentId,
//       ),
//     );
//
//     if (response is! List) {
//       throw Exception(
//         'Invalid department employees response.',
//       );
//     }
//
//     return response
//         .map(
//           (json) => DepartmentEmployeeModel.fromJson(
//         Map<String, dynamic>.from(json),
//       ),
//     )
//         .toList();
//   }
//
//   // ===============================================================
//   // GET SINGLE EMPLOYEE DETAILS
//   //
//   // IMPORTANT:
//   // The View Staff API returns an OBJECT:
//   //
//   // {
//   //   "employee": {...},
//   //   "user": {...},
//   //   "company": {...},
//   //   "documents": [],
//   //   "attendance": [],
//   //   "leaves": [],
//   //   "expenses": [],
//   //   "salaryStructures": [],
//   //   "payrolls": []
//   // }
//   //
//   // Therefore this must NOT be parsed as List.
//   // ===============================================================
//
//   Future<Map<String, dynamic>> getEmployeeDetails(
//       String employeeId,
//       ) async {
//     final response = await _apiClient.get(
//       DepartmentEndpoints.employeeDetails(employeeId),
//     );
//
//     if (response is! Map) {
//       throw Exception(
//         'Invalid employee details response.',
//       );
//     }
//
//     return Map<String, dynamic>.from(response);
//   }
// // ===============================================================
// // GET ALL EMPLOYEES
// // ===============================================================
//
//   Future<List<DepartmentEmployeeModel>> getEmployees({
//     String? status,
//   }) async {
//     String endpoint = '/employees';
//
//     if (status != null && status.isNotEmpty) {
//       endpoint = '$endpoint?status=$status';
//     }
//
//     final response = await _apiClient.get(endpoint);
//
//     if (response is! List) {
//       throw Exception('Invalid employees response.');
//     }
//
//     return response
//         .map(
//           (json) => DepartmentEmployeeModel.fromJson(
//         Map<String, dynamic>.from(json),
//       ),
//     )
//         .toList();
//   }
//   // ===============================================================
//   // MOVE EMPLOYEES
//   // ===============================================================
//
//   Future<void> moveEmployees(
//       MoveEmployeesRequest request,
//       ) async {
//     await _apiClient.post(
//       DepartmentEndpoints.moveEmployees,
//       body: request.toJson(),
//     );
//   }
// }



import '../../../../core/network/api_client.dart';

import '../endpoints/department_endpoints.dart';
import '../models/department_employee_model.dart';
import '../models/department_model.dart';
import '../models/move_employees_request.dart';

// =================================================================
// DEPARTMENT SERVICE
// =================================================================

class DepartmentService {
  final ApiClient _apiClient = ApiClient();

  // ===============================================================
  // GET DEPARTMENTS
  // ===============================================================

  Future<List<DepartmentModel>> getDepartments() async {
    final response = await _apiClient.get(
      DepartmentEndpoints.departments,
    );

    if (response is! List) {
      throw Exception('Invalid departments response.');
    }

    return response
        .map(
          (json) => DepartmentModel.fromJson(
        Map<String, dynamic>.from(json),
      ),
    )
        .toList();
  }

  // ===============================================================
  // GET ALL EMPLOYEES
  //
  // Uses the Employee API instead of:
  // /departments/{departmentId}/employees
  // ===============================================================

  Future<List<DepartmentEmployeeModel>> getEmployees() async {
    final response = await _apiClient.get(
      DepartmentEndpoints.employees,
    );

    dynamic employeeList = response;

    // -------------------------------------------------------------
    // Handles:
    //
    // [
    //   {...},
    //   {...}
    // ]
    //
    // and also:
    //
    // {
    //   "employees": [...]
    // }
    // -------------------------------------------------------------

    if (response is Map) {
      final map = Map<String, dynamic>.from(response);

      employeeList =
          map['employees'] ??
              map['data'] ??
              map['results'] ??
              map['employee'];
    }

    if (employeeList is! List) {
      throw Exception(
        'Invalid employees response.',
      );
    }

    return employeeList
        .whereType<Map>()
        .map(
          (json) => DepartmentEmployeeModel.fromJson(
        Map<String, dynamic>.from(json),
      ),
    )
        .toList();
  }

  // ===============================================================
  // CREATE DEPARTMENT
  // ===============================================================

  Future<DepartmentModel> createDepartment(
      Map<String, dynamic> data,
      ) async {
    final response = await _apiClient.post(
      DepartmentEndpoints.departments,
      body: data,
    );

    if (response is! Map) {
      throw Exception(
        'Invalid create department response.',
      );
    }

    return DepartmentModel.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  // ===============================================================
  // UPDATE DEPARTMENT
  // ===============================================================

  Future<DepartmentModel> updateDepartment(
      String id,
      Map<String, dynamic> data,
      ) async {
    final response = await _apiClient.put(
      DepartmentEndpoints.department(id),
      body: data,
    );

    if (response is! Map) {
      throw Exception(
        'Invalid update department response.',
      );
    }

    return DepartmentModel.fromJson(
      Map<String, dynamic>.from(response),
    );
  }

  // ===============================================================
  // DELETE DEPARTMENT
  // ===============================================================

  Future<void> deleteDepartment(String id) async {
    await _apiClient.delete(
      DepartmentEndpoints.department(id),
    );
  }

  // ===============================================================
  // MOVE EMPLOYEES
  // ===============================================================

  Future<void> moveEmployees(
      MoveEmployeesRequest request,
      ) async {
    await _apiClient.post(
      DepartmentEndpoints.moveEmployees,
      body: request.toJson(),
    );
  }
}
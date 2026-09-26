// // =================================================================
// // DEPARTMENT API ENDPOINTS
// // =================================================================
//
// class DepartmentEndpoints {
//   DepartmentEndpoints._();
//
//   // ===============================================================
//   // DEPARTMENTS
//   // ===============================================================
//
//   static const String departments = '/departments';
//
//   static String department(String id) {
//     return '/departments/$id';
//   }
//
//   // ===============================================================
//   // EMPLOYEES
//   // ===============================================================
//
//   static String departmentEmployees(String departmentId) {
//     return '/departments/$departmentId/employees';
//   }
//
//   // ===============================================================
//   // SINGLE EMPLOYEE DETAILS
//   //
//   // Used when clicking "View Staff".
//   // ===============================================================
//
//   static String employeeDetails(String employeeId) {
//     return '/employees/$employeeId';
//   }
//
//   // ===============================================================
//   // MOVE EMPLOYEES
//   // ===============================================================
//
//   static const String moveEmployees =
//       '/departments/move-employees';
// }


// =================================================================
// DEPARTMENT API ENDPOINTS
// =================================================================

class DepartmentEndpoints {
  DepartmentEndpoints._();

  // ===============================================================
  // DEPARTMENTS
  // ===============================================================

  static const String departments = '/departments';

  static String department(String id) {
    return '/departments/$id';
  }

  // ===============================================================
  // EMPLOYEES
  // ===============================================================

  static const String employees = '/employees';

  // ===============================================================
  // MOVE EMPLOYEES
  // ===============================================================

  static const String moveEmployees = '/departments/move-employees';
}
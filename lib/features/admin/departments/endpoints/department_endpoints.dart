
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
class LeaveEndpoints {
  LeaveEndpoints._();

  // ============================================================
  // GET /leaves
  // Optional query param: ?status=pending|approved|rejected|cancelled
  // ============================================================

  static const String leaves = '/leaves';

  // ============================================================
  // GET /leaves/company/:companyId
  // ============================================================

  static String leavesByCompany(String companyId) {
    return '/leaves/company/$companyId';
  }

  // ============================================================
  // GET /leaves/employee/:employeeId
  // ============================================================

  static String leavesByEmployee(String employeeId) {
    return '/leaves/employee/$employeeId';
  }

  // ============================================================
  // PUT /leaves/:id/status
  // Body: {"status": "approved" | "rejected"}
  // ============================================================

  static String updateStatus(String id) {
    return '/leaves/$id/status';
  }

  // ============================================================
  // GET /employees
  // Used to resolve employee names for display
  // (the leaves API's employeeId object does not include name).
  // ============================================================

  static const String employees = '/employees';
}
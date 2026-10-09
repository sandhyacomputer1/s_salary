class EmpDashEndpoints {
  EmpDashEndpoints._();

  // ============================================================
  // GET /employees/me
  // ============================================================

  static const String profile = '/employees/me';

  // ============================================================
  // GET /attendance/employee/:employeeId?month=M&year=Y
  // (NOT /attendance/my-history — confirmed via Postman; that
  // route returns 404. This is the real, working endpoint.)
  // ============================================================

  static String attendanceHistory({
    required String employeeId,
    required int month,
    required int year,
  }) {
    return '/attendance/employee/$employeeId?month=$month&year=$year';
  }

  // ============================================================
  // GET /shifts/my-shift
  // ============================================================

  static const String myShift = '/shifts/my-shift';

  // ============================================================
  // POST /attendance/check-in
  // ============================================================

  static const String checkIn = '/attendance/check-in';

  // ============================================================
  // POST /attendance/check-out
  // ============================================================

  static const String checkOut = '/attendance/check-out';
}
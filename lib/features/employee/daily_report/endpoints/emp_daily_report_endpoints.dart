class EmpDailyReportEndpoints {
  EmpDailyReportEndpoints._();

  // GET /employees/me — only used to resolve the employee _id when it is
  // not in SecureStorage. Response: { employee: { _id, ... }, ... }
  static const String profile = '/employees/me';

  // POST /reports
  // { completedWork, ongoingWork, planForTomorrow, blockers, date }
  // One report per employee per date (upsert).
  static const String create = '/reports';

  // GET /reports/employee/:employeeId → full history array, newest first
  static String history(String employeeId) => '/reports/employee/$employeeId';

  // GET /reports/employee/:employeeId?date=YYYY-MM-DD → single object or null
  static String byDate(String employeeId, String date) =>
      '/reports/employee/$employeeId?date=$date';
}
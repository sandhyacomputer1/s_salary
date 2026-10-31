/// API paths used by the Employee Profile screen.
class AdminEmployeeProfileEndpoints {
  AdminEmployeeProfileEndpoints._();

  static String detail(String id) => '/employees/$id';
  static const String companyMe = '/companies/me';

  static String attendanceSummary(String id, int month, int year) =>
      '/attendance/employee/$id/summary?month=$month&year=$year';
  static String attendanceLogs(String id, int month, int year) =>
      '/attendance/employee/$id?month=$month&year=$year';

  static String calendar(String companyId, int year) =>
      '/companies/$companyId/calendar?year=$year';
  static String holidays(String companyId) => '/companies/$companyId/holidays';
  static const String manualMark = '/attendance/manual-mark';

  static String leaveBalances(String id, int year) =>
      '/leaves/balances/$id?year=$year';
  static String leaveHistory(String id) => '/leaves/employee/$id';
  static String leaveApprove(String leaveId) => '/leaves/$leaveId/approve';
  static String leaveReject(String leaveId) => '/leaves/$leaveId/reject';

  static String salaryStructure(String id) => '/salary/structure/$id';
  static String salarySlips(String id) => '/salary/slips/$id';

  static String expenses(String id) => '/expenses/employee/$id';
  static String expenseApprove(String expenseId) => '/expenses/$expenseId/approve';
  static String expenseReject(String expenseId) => '/expenses/$expenseId/reject';
}
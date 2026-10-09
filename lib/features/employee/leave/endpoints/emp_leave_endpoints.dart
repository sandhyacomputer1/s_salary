class EmpLeaveEndpoints {
  EmpLeaveEndpoints._();

  // GET /employees/me — only used to resolve the employee _id when it is
  // not in SecureStorage. Response: { employee: { _id, ... }, ... }
  static const String profile = '/employees/me';

  // GET /leaves/balances/:employeeId   (from API docs — shape unverified)
  static String balances(String employeeId) => '/leaves/balances/$employeeId';

  // GET /leaves/employee/:employeeId   (confirmed)
  static String history(String employeeId) => '/leaves/employee/$employeeId';

  // POST /leaves/apply   (from API docs — half-day field unverified)
  static const String apply = '/leaves/apply';
}
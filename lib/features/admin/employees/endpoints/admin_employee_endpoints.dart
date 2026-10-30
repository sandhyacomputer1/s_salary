/// All API paths used by the Admin Employees module.
class AdminEmployeeEndpoints {
  AdminEmployeeEndpoints._();

  static const String list = '/employees';
  static const String create = '/employees';
  static const String bulkImport = '/employees/bulk-import';

  /// Archived = soft-deleted employees (status = terminated).
  static const String archived = '/employees?status=terminated';

  static String byId(String id) => '/employees/$id';
  static String restore(String id) => '/employees/$id/restore';
  static String permanent(String id) => '/employees/$id/permanent';

  static String salaryStructure(String employeeId) =>
      '/salary/structure/$employeeId';
  static String salaryByCompany(String companyId) =>
      '/salary/structure/by-company/$companyId';

  static String departments(String companyId) => '/departments/$companyId';
}
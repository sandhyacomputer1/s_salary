
// The path exists in ANDROID_API_REFERENCE (section "System & audit").
// Roles: super_admin, admin.

class AuditTrailEndpoints {
  AuditTrailEndpoints._();

  // GET /audit-logs?page=&limit=&search=&action=&status=&userRole=&startDate=&endDate=
  static const String auditLogs = '/audit-logs';
}
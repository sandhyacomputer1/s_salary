// All paths below exist in ANDROID_API_REFERENCE (section 4.2).
// Request/response BODIES for most of them are not documented.

class TeamRolesEndpoints {
  TeamRolesEndpoints._();

  // GET (list team) / POST (add team member)
  static const String subAdmins = '/companies/sub-admins';

  // DELETE (revoke admin role)
  static String subAdminById(String adminId) =>
      '/companies/sub-admins/$adminId';

  // PUT (change admin role)
  static String subAdminRole(String adminId) =>
      '/companies/sub-admins/$adminId/role';

  // GET (employee dropdown)
  static const String employees = '/employees';

  // GET (own company + settings, incl. settings.rolePermissions)
  static const String myCompany = '/companies/me';

  // PUT (save settings, incl. rolePermissions)
  static String companySettings(String companyId) =>
      '/companies/$companyId/settings';
}
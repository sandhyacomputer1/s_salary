// All paths exist in ANDROID_API_REFERENCE (section 4.2, "Org & scheduling").

class SettingsEndpoints {
  SettingsEndpoints._();

  // GET - own company + settings + holidays + license (not for super_admin)
  static const String myCompany = '/companies/me';

  // PUT (admin, super_admin) - company details. Body is NOT documented.
  static String company(String companyId) => '/companies/$companyId';

  // PUT (admin, super_admin) - company settings.
  static String settings(String companyId) => '/companies/$companyId/settings';
}

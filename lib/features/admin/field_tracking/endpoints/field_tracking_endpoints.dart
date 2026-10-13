// Both paths exist in ANDROID_API_REFERENCE (attendance section).

class FieldTrackingEndpoints {
  FieldTrackingEndpoints._();

  // GET (admin, super_admin) - latest location of every field employee.
  static String fieldLocations(String companyId) =>
      '/attendance/company/$companyId/field-locations';

  // GET (employee, admin, super_admin) - GPS log for one day.
  // date format: YYYY-MM-DD
  static String locationHistory(String employeeId, String date) =>
      '/attendance/employee/$employeeId/location-history?date=$date';
}

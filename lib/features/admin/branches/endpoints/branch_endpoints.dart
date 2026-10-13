// Verified against ANDROID_API_REFERENCE:
//   GET  /companies/branches
//   POST /companies/branches
//   PUT  /companies/branches/:branchId

class BranchEndpoints {
  BranchEndpoints._();

  static const String branches = '/companies/branches';

  static String branchById(String branchId) => '/companies/branches/$branchId';
}
// Every path below exists in ANDROID_API_REFERENCE (section 4.2, "Payroll").
// All are admin / super_admin unless noted. Bodies are mostly undocumented.

class PayrollEndpoints {
  PayrollEndpoints._();

  // GET - the company's payslips for a month (month: 1-12)
  static String companyPayroll(String companyId, int month, int year) =>
      '/companies/$companyId/payroll?month=$month&year=$year';

  // POST - generate payroll for a month. Slips already "paid" are skipped.
  static String generate(int month, int year) =>
      '/salary/generate?month=$month&year=$year';

  // PUT - mark one slip as paid
  static String markPaid(String slipId) => '/salary/slip/$slipId/mark-paid';

  // POST - email payslips (body not documented)
  static const String sendEmails = '/salary/send-emails';

  // GET - all salary structures of a company
  static String structuresByCompany(String companyId) =>
      '/salary/structure/by-company/$companyId';

  // GET (employee, accountant, manager) / POST (admin)
  static String structure(String employeeId) => '/salary/structure/$employeeId';

  // POST - create a rule
  static const String rules = '/salary/rules';

  // GET - rules of a company
  static String rulesByCompany(String companyId) => '/salary/rules/$companyId';

  // GET - professional tax / provident fund reports
  static String ptReport(String companyId, int month, int year) =>
      '/salary/reports/pt/$companyId?month=$month&year=$year';

  static String pfReport(String companyId, int month, int year) =>
      '/salary/reports/pf/$companyId?month=$month&year=$year';

  // POST - PF refund (body not documented)
  static const String pfRefund = '/salary/pf/refund';

  // GET - printable payslip. Returns HTML (Content-Type: text/html), not JSON.
  static String slipHtml(String employeeId, int month, int year) =>
      '/salary/slip/$employeeId?month=$month&year=$year&format=html';
}

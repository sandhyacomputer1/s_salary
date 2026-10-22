import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../endpoints/payroll_endpoints.dart';
import '../models/payroll_reports_model.dart';
import '../models/payroll_request.dart';
import '../models/payroll_slip_model.dart';
import '../models/salary_structure_model.dart';

/// Message is safe to show directly to the user.
class PayrollException implements Exception {
  final String message;

  /// True when the session is gone and the UI should send the user to login.
  final bool isAuthError;

  const PayrollException(this.message, {this.isAuthError = false});

  @override
  String toString() => message;
}

class PayrollService {
  PayrollService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  // ============================================================
  // GET /companies/:id/payroll?month=&year=
  // The company id is the logged-in admin's, from SecureStorage.
  // ============================================================

  Future<List<PayrollSlip>> fetchPayroll(int month, int year) async {
    final companyId = await _companyId();

    final data = await _guard(
      () =>
          _client.get(PayrollEndpoints.companyPayroll(companyId, month, year)),
    );

    if (data == null) return const [];

    if (data is! List && data is! Map) {
      throw const PayrollException('Invalid payroll response.');
    }

    return PayrollSlip.listFromResponse(data);
  }

  // ============================================================
  // POST /salary/generate?month=&year=
  // Documented: returns the generated slips; slips that are already
  // "paid" are skipped, never recomputed.
  // ============================================================

  Future<List<PayrollSlip>> generate(int month, int year) async {
    final data = await _guard(
      () => _client.post(PayrollEndpoints.generate(month, year)),
    );

    return PayrollSlip.listFromResponse(data);
  }

  // ============================================================
  // POST /salary/send-emails   (body is a guess: see payroll_request.dart)
  // ============================================================

  Future<void> sendEmails(SendPayslipEmailsRequest request) async {
    await _guard(
      () => _client.post(PayrollEndpoints.sendEmails, body: request.toJson()),
    );
  }

  // ============================================================
  // GET /salary/structure/by-company/:companyId
  // ============================================================

  Future<List<SalaryStructure>> fetchStructures() async {
    final companyId = await _companyId();

    final data = await _guard(
      () => _client.get(PayrollEndpoints.structuresByCompany(companyId)),
    );

    return SalaryStructure.listFromResponse(data);
  }

  // ============================================================
  // POST /salary/structure/:employeeId
  // ============================================================

  Future<void> saveStructure(
    String employeeId,
    SalaryStructureRequest request,
  ) async {
    if (employeeId.isEmpty) {
      throw const PayrollException('Missing employee id.');
    }

    await _guard(
      () => _client.post(
        PayrollEndpoints.structure(employeeId),
        body: request.toJson(),
      ),
    );
  }

  // ============================================================
  // GET /salary/reports/pt/:companyId?month=&year=
  // (response shape not documented: see payroll_reports_model.dart)
  // ============================================================

  Future<PtReport> fetchPtReport(int month, int year) async {
    final companyId = await _companyId();

    final data = await _guard(
      () => _client.get(PayrollEndpoints.ptReport(companyId, month, year)),
    );

    return PtReport.fromResponse(data);
  }

  // ============================================================
  // GET /salary/reports/pf/:companyId?month=&year=
  // ============================================================

  Future<PfReport> fetchPfReport(int month, int year) async {
    final companyId = await _companyId();

    final data = await _guard(
      () => _client.get(PayrollEndpoints.pfReport(companyId, month, year)),
    );

    return PfReport.fromResponse(data);
  }

  // ============================================================
  // POST /salary/pf/refund   (body is a guess: see payroll_request.dart)
  // ============================================================

  Future<void> refundPf(PfRefundRequest request) async {
    if (request.employeeId.isEmpty) {
      throw const PayrollException('Missing employee id.');
    }

    await _guard(
      () => _client.post(PayrollEndpoints.pfRefund, body: request.toJson()),
    );
  }

  // ============================================================

  Future<String> _companyId() async {
    final id = await SecureStorage.getCompanyId();

    if (id == null || id.isEmpty) {
      throw const PayrollException(
        'Company not found. Please log in again.',
        isAuthError: true,
      );
    }

    return id;
  }

  // ApiClient throws Exception('<server message>') for non-2xx responses
  // ({success:false, message}), so toString() is "Exception: <message>".
  // Anything else (no internet, timeout) gets a friendly message.
  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PayrollException {
      rethrow;
    } catch (e) {
      const prefix = 'Exception: ';
      final text = e.toString();

      if (text.startsWith(prefix)) {
        final message = text.substring(prefix.length).trim();

        final isAuth =
            message.startsWith('Session expired') ||
            message.startsWith('Authentication required');

        throw PayrollException(message, isAuthError: isAuth);
      }

      throw const PayrollException(
        'Could not reach the server. Check your connection and try again.',
      );
    }
  }
}

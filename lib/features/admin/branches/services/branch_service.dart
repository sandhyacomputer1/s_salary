import '../../../../core/network/api_client.dart';
import '../endpoints/branch_endpoints.dart';
import '../models/branch_model.dart';

/// Message is safe to show directly to the user.
class BranchException implements Exception {
  final String message;

  /// True when the session is gone and the UI should send the user to login.
  final bool isAuthError;

  const BranchException(this.message, {this.isAuthError = false});

  @override
  String toString() => message;
}

class BranchAdminService {
  BranchAdminService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  // ============================================================
  // GET /companies/branches
  // ============================================================

  Future<List<BranchModel>> fetchBranches() async {
    final data = await _guard(() => _client.get(BranchEndpoints.branches));

    if (data is! List) {
      throw const BranchException('Invalid branches response.');
    }

    return BranchModel.listFromResponse(data);
  }

  // ============================================================
  // POST /companies/branches
  // The request body is not documented; the map comes from
  // BranchRequest.toJson().
  // ============================================================

  Future<dynamic> createBranch(Map<String, dynamic> body) {
    return _guard(
          () => _client.post(BranchEndpoints.branches, body: body),
    );
  }

  // ============================================================
  // PUT /companies/branches/:branchId
  // ============================================================

  Future<dynamic> updateBranch(String branchId, Map<String, dynamic> body) {
    if (branchId.isEmpty) {
      throw const BranchException('Missing branch id.');
    }

    return _guard(
          () => _client.put(BranchEndpoints.branchById(branchId), body: body),
    );
  }

  // ============================================================
  // ERROR HANDLING
  //
  // ApiClient throws Exception('<server message>') for non-2xx
  // responses ({success:false, message}), so toString() is
  // "Exception: <message>". Anything else (no internet, timeout)
  // gets a friendly connectivity message.
  // ============================================================

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on BranchException {
      rethrow;
    } catch (e) {
      const prefix = 'Exception: ';
      final text = e.toString();

      if (text.startsWith(prefix)) {
        final message = text.substring(prefix.length).trim();

        final isAuth = message.startsWith('Session expired') ||
            message.startsWith('Authentication required');

        throw BranchException(message, isAuthError: isAuth);
      }

      throw const BranchException(
        'Could not reach the server. Check your connection and try again.',
      );
    }
  }
}
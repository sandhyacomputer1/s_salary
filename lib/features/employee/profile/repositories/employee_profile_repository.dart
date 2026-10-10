// lib/features/employee/profile/repositories/employee_profile_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/employee_profile_details_model.dart';
import '../models/employee_profile_model.dart';
import '../services/employee_profile_service.dart';

class EmployeeProfileRepository {
  final EmployeeProfileService _service;

  EmployeeProfileRepository(this._service);

  Future<EmployeeProfileModel> getMyProfile() {
    return _service.fetchMyProfile();
  }

  Future<void> updatePersonalAndBankDetails({
    required String employeeDocId,
    required PersonalDetails personal,
    required BankDetails bank,
    String? phone,
  }) {
    return _service.updatePersonalDetails(
      employeeDocId: employeeDocId,
      personal: personal,
      bank: bank,
      phone: phone,
    );
  }
}

final employeeProfileRepositoryProvider =
Provider<EmployeeProfileRepository>((ref) {
  return EmployeeProfileRepository(
    ref.watch(employeeProfileServiceProvider),
  );
});

/// Loads GET /employees/me. Refresh with `ref.invalidate(...)`.
final employeeProfileProvider =
FutureProvider.autoDispose<EmployeeProfileModel>((ref) async {
  final repo = ref.watch(employeeProfileRepositoryProvider);
  return repo.getMyProfile();
});

/// Handles the save action. `state` is AsyncValue<void>.
class ProfileUpdateController extends StateNotifier<AsyncValue<void>> {
  ProfileUpdateController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<bool> save({
    required String employeeDocId,
    required PersonalDetails personal,
    required BankDetails bank,
    String? phone,
  }) async {
    state = const AsyncLoading();
    try {
      await _ref
          .read(employeeProfileRepositoryProvider)
          .updatePersonalAndBankDetails(
        employeeDocId: employeeDocId,
        personal: personal,
        bank: bank,
        phone: phone,
      );
      state = const AsyncData(null);
      _ref.invalidate(employeeProfileProvider);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final profileUpdateControllerProvider =
StateNotifierProvider<ProfileUpdateController, AsyncValue<void>>((ref) {
  return ProfileUpdateController(ref);
});
// lib/features/employee/salary/repositories/employee_salary_repository.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/secure_storage.dart';
import '../models/employee_salary_breakdown_model.dart';
import '../models/employee_salary_slip_model.dart';
import '../models/employee_salary_structure_model.dart';
import '../services/employee_salary_service.dart';

/// Resolves the authenticated employee's document id from SecureStorage.
final currentEmployeeIdProvider = FutureProvider<String>((ref) async {
  final id = await SecureStorage.getEmployeeId();
  if (id == null || id.isEmpty) {
    throw Exception(
      'Employee profile is not linked to this account. Please contact HR.',
    );
  }
  return id;
});

class EmployeeSalaryRepository {
  final EmployeeSalaryService _service;
  EmployeeSalaryRepository(this._service);

  Future<EmployeeSalaryStructureModel> getStructure(String employeeId) {
    return _service.fetchStructure(employeeId);
  }

  Future<List<EmployeeSalarySlipModel>> getSlips(String employeeId) async {
    final list = await _service.fetchSlips(employeeId);
    list.sort((a, b) {
      final y = b.year.compareTo(a.year);
      if (y != 0) return y;
      return b.month.compareTo(a.month);
    });
    return list;
  }

  Future<EmployeeSalaryBreakdownModel> getSlipDetail({
    required String employeeId,
    required int month,
    required int year,
  }) {
    return _service.fetchSlipDetail(
      employeeId: employeeId,
      month: month,
      year: year,
    );
  }

  Future<String> getSlipHtml({
    required String employeeId,
    required int month,
    required int year,
  }) {
    return _service.fetchSlipHtml(
      employeeId: employeeId,
      month: month,
      year: year,
    );
  }
}

final employeeSalaryRepositoryProvider = Provider<EmployeeSalaryRepository>((
  ref,
) {
  return EmployeeSalaryRepository(ref.watch(employeeSalaryServiceProvider));
});

final salaryStructureProvider =
    FutureProvider.autoDispose<EmployeeSalaryStructureModel>((ref) async {
      final employeeId = await ref.watch(currentEmployeeIdProvider.future);
      return ref
          .watch(employeeSalaryRepositoryProvider)
          .getStructure(employeeId);
    });

final salarySlipsProvider =
    FutureProvider.autoDispose<List<EmployeeSalarySlipModel>>((ref) async {
      final employeeId = await ref.watch(currentEmployeeIdProvider.future);
      return ref.watch(employeeSalaryRepositoryProvider).getSlips(employeeId);
    });

/// Family provider for a specific slip's breakdown. Key = (month, year).
final salarySlipDetailProvider = FutureProvider.autoDispose
    .family<EmployeeSalaryBreakdownModel, ({int month, int year})>((
      ref,
      key,
    ) async {
      final employeeId = await ref.watch(currentEmployeeIdProvider.future);
      return ref
          .watch(employeeSalaryRepositoryProvider)
          .getSlipDetail(
            employeeId: employeeId,
            month: key.month,
            year: key.year,
          );
    });

// lib/features/employee/profile/widgets/profile_tab_expense_claims.dart

import 'package:flutter/material.dart';

import '../../expense_claims/screens/employee_submit_expense_claim_screen.dart';


class ProfileTabExpenseClaims extends StatelessWidget {
  const ProfileTabExpenseClaims({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuses the existing Expense Claims feature rather than reimplementing it.
    return const EmployeeSubmitExpenseClaimScreen(embedded: true);
  }
}
import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/two_factor_screen.dart';
import 'features/admin/dashboard/screens/admin_dashboard_screen.dart';
import 'features/admin/employees/screens/employees_screen.dart';
import 'features/employee/dashboard/screens/emp_dashboard_screen.dart';
import 'features/employee/dashboard/screens/emp_dashboard_shell.dart';
import 'features/employee/leave/screens/emp_apply_leave_screen.dart';
import 'features/employee/daily_report/screens/emp_daily_report_screen.dart';
import 'features/employee/expense_claims/screens/employee_submit_expense_claim_screen.dart';
import 'features/employee/expense_claims/screens/employee_expense_claims_screen.dart';
class SSalaryApp extends StatelessWidget {
  const SSalaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'S Salary',

      theme: AppTheme.lightTheme,

      initialRoute: AppRoutes.splash,

      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.employeeSubmitExpenseClaim: (context) =>
        const EmployeeSubmitExpenseClaimScreen(),
        AppRoutes.employeeExpenseClaims: (context) =>
        const EmployeeExpenseClaimsScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.employeeDailyReport: (context) => const EmpDailyReportScreen(),
        AppRoutes.twoFactor: (context) => const TwoFactorScreen(),
        AppRoutes.employeeApplyLeave: (context) => const EmpApplyLeaveScreen(),
        AppRoutes.adminDashboard: (context) =>
        const AdminDashboardScreen(),

        AppRoutes.employees: (context) =>
        const EmployeesScreen(),

        // Employee Dashboard
        AppRoutes.employeeDashboard: (context) =>
        const EmpDashboardShell(),
      },
    );
  }
}
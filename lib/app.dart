import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/session/session_events.dart';
import 'core/theme/app_theme.dart';

// 👇 Import all screens
import 'features/auth/screens/no_internet_screen.dart';
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
      navigatorKey: SessionEvents.navigatorKey,

      // 👇 ALWAYS START HERE (Check internet first)
      initialRoute: AppRoutes.noInternet,

      routes: {
        AppRoutes.noInternet: (context) => const NoInternetScreen(),
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.twoFactor: (context) => const TwoFactorScreen(),
        AppRoutes.adminDashboard: (context) => const AdminDashboardScreen(),
        AppRoutes.employeeDashboard: (context) => const EmpDashboardShell(),
        AppRoutes.employees: (context) => const EmployeesScreen(),
        AppRoutes.employeeApplyLeave: (context) => const EmpApplyLeaveScreen(),
        AppRoutes.employeeDailyReport: (context) => const EmpDailyReportScreen(),
        AppRoutes.employeeSubmitExpenseClaim: (context) => const EmployeeSubmitExpenseClaimScreen(),
        AppRoutes.employeeExpenseClaims: (context) => const EmployeeExpenseClaimsScreen(),
      },
    );
  }
}
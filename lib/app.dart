import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/two_factor_screen.dart';
import 'features/admin/dashboard/screens/admin_dashboard_screen.dart';
import 'features/admin/employees/screens/employees_screen.dart';
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
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.twoFactor: (context) => const TwoFactorScreen(),

        AppRoutes.adminDashboard:
            (context) => const AdminDashboardScreen(),

        AppRoutes.employees:
            (context) => const EmployeesScreen(),

        AppRoutes.employeeDashboard: (context) => const Scaffold(
          body: Center(
            child: Text('Employee Dashboard'),
          ),
        ),
      },    );
  }
}
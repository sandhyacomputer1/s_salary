import 'package:flutter/material.dart';

// Adjust these imports to match your actual folder structure
import '../../core/routes/app_routes.dart';
import '../storage/secure_storage.dart'; // 👈 MAKE SURE THIS PATH IS CORRECT

class SessionEvents {
  SessionEvents._();

  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  static bool _redirecting = false;

  static void sessionExpired() async {
    if (_redirecting) return;
    _redirecting = true;

    // Clear the expired tokens before redirecting!
    await SecureStorage.clearSession();

    final navigator = navigatorKey.currentState;

    // If navigator is null, the app hasn't set the navigatorKey yet.
    navigator?.pushNamedAndRemoveUntil(
      AppRoutes.login,
          (route) => false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;

      if (context != null) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('Your session has ended. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    Future.delayed(const Duration(seconds: 3), () => _redirecting = false);
  }
}
import 'package:flutter/material.dart';

import '../routes/app_routes.dart';

/// One place that can send the user to the Login screen from anywhere
/// (for example from ApiClient, which has no BuildContext).
///
/// Used ONLY when the session can no longer be restored, i.e. the server
/// rejected the refresh token. A normal Logout button still clears the
/// session by itself, as before.
class SessionEvents {
  SessionEvents._();

  /// Give this key to MaterialApp:  navigatorKey: SessionEvents.navigatorKey
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  static bool _redirecting = false;

  static void sessionExpired() {
    // Several requests can fail together; redirect only once.
    if (_redirecting) return;
    _redirecting = true;

    final navigator = navigatorKey.currentState;

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
          ),
        );
      }
    });

    Future.delayed(const Duration(seconds: 3), () => _redirecting = false);
  }
}
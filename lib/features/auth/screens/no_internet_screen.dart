import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/services/connectivity_service.dart';

class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({super.key});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  static const Color kOrange = Color(0xFFE8622C);
  static const Color kText = Color(0xFF1A1A1A);
  static const Color kGrey = Color(0xFF9A9A9F);

  StreamSubscription<bool>? _subscription;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    // Listen for connection coming back automatically
    _subscription = ConnectivityService.onStatusChange().listen((hasInternet) {
      if (hasInternet && mounted) {
        _goToSplash();
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // 👇 Just go to Splash. Splash will handle the rest.
  void _goToSplash() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.splash);
  }

  Future<void> _retry() async {
    setState(() => _isRetrying = true);

    final hasInternet = await ConnectivityService.hasInternet();

    if (!mounted) return;

    setState(() => _isRetrying = false);

    if (hasInternet) {
      _goToSplash();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Still no internet connection.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: kOrange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 50,
                    color: kOrange,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Internet Connection',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please check your internet connection\nand try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: kGrey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 46,
                  width: 200,
                  child: ElevatedButton.icon(
                    onPressed: _isRetrying ? null : _retry,
                    icon: _isRetrying
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(_isRetrying ? 'Checking...' : 'Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
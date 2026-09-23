import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/storage/secure_storage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ============================
  // THEME COLORS (matches login screen / web dashboard)
  // ============================
  static const Color kOrange = Color(0xFFFF6B2C);
  static const Color kOrangeDark = Color(0xFFE85A1A);
  static const Color kBlack = Color(0xFF1C1C1E);
  static const Color kGrey = Color(0xFF8E8E93);

  // Entrance animation (logo + title pop/fade/slide in)
  late final AnimationController _entranceController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _loaderFade;

  // Continuous gentle pulse for the logo badge
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _logoScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
      ),
    );
    _logoFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );

    _titleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.30, 0.65, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.30, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _loaderFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );

    _entranceController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.96, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkSession();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    // Small delay so splash screen is visible
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final accessToken = await SecureStorage.getAccessToken();

    if (!mounted) return;

    if (accessToken == null || accessToken.isEmpty) {
      // User is not logged in
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.login,
      );
      return;
    }

    // User is already logged in
    final role = await SecureStorage.getUserRole();

    if (!mounted) return;

    if (_isEmployee(role)) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.employeeDashboard,
      );
    } else {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.adminDashboard,
      );
    }
  }

  bool _isEmployee(String? role) {
    return role?.toLowerCase() == 'employee';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ============================
            // LOGO — pop-in then continuous gentle pulse
            // ============================
            FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: AnimatedBuilder(
                  animation: _pulseScale,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseScale.value,
                      child: child,
                    );
                  },
                  child: Container(
                    height: 84,
                    width: 84,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: const LinearGradient(
                        colors: [kOrange, kOrangeDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kOrange.withOpacity(0.35),
                          blurRadius: 26,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ============================
            // TITLE — fade + slide up
            // ============================
            FadeTransition(
              opacity: _titleFade,
              child: SlideTransition(
                position: _titleSlide,
                child: const Text(
                  'S Salary',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: kBlack,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 6),

            FadeTransition(
              opacity: _titleFade,
              child: Text(
                'Payroll made simple',
                style: TextStyle(
                  fontSize: 14,
                  color: kGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 36),

            // ============================
            // LOADER — orange themed, fades in last
            // ============================
            FadeTransition(
              opacity: _loaderFade,
              child: const SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.8,
                  valueColor: AlwaysStoppedAnimation(kOrange),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/services/connectivity_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Color kOrange = Color(0xFFE8622C);
  static const Color kOrangeLight = Color(0xFFFF7A3D);
  static const Color kDark = Color(0xFF14100E);
  static const String kLogoAsset = 'lib/assets/images/imglo.jpeg';

  late final AnimationController _entranceController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _loaderFade;

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

    _pulseScale = Tween<double>(begin: 0.96, end: 1.06).animate(
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
    // 1. Double-check internet immediately
    final hasInternet = await ConnectivityService.hasInternet();

    if (!mounted) return;

    // If internet dropped while on splash, go back to No Internet screen
    if (!hasInternet) {
      Navigator.pushReplacementNamed(context, AppRoutes.noInternet);
      return;
    }

    // 2. Wait 2 seconds so splash animation finishes
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 3. Check for saved login session
    String? accessToken;
    String? role;

    try {
      accessToken = await SecureStorage.getAccessToken()
          .timeout(const Duration(seconds: 6));

      if (accessToken != null && accessToken.isNotEmpty) {
        role = await SecureStorage.getUserRole()
            .timeout(const Duration(seconds: 6));
      }
    } catch (e) {
      debugPrint('SPLASH SESSION ERROR: $e');
      accessToken = null;
      try {
        await SecureStorage.clearSession();
      } catch (_) {}
    }

    if (!mounted) return;

    // 4. Route based on session
    if (accessToken == null || accessToken.isEmpty) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }

    if (_isEmployee(role)) {
      Navigator.pushReplacementNamed(context, AppRoutes.employeeDashboard);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
    }
  }

  bool _isEmployee(String? role) {
    return role?.toLowerCase() == 'employee';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: -140,
            top: -100,
            child: _Glow(size: 480, color: kOrange.withValues(alpha: 0.26)),
          ),
          Positioned(
            right: -200,
            bottom: -200,
            child: _Glow(size: 560, color: kOrange.withValues(alpha: 0.14)),
          ),
          const Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                      child: const _LogoMark(size: 92),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                FadeTransition(
                  opacity: _titleFade,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: const Text(
                      'Sandhya Salary',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeTransition(
                  opacity: _titleFade,
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: 'Payroll, ',
                          style: TextStyle(color: Colors.white70),
                        ),
                        TextSpan(
                          text: 'simplified.',
                          style: TextStyle(color: kOrangeLight),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                FadeTransition(
                  opacity: _loaderFade,
                  child: const SizedBox(
                    height: 26,
                    width: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      valueColor: AlwaysStoppedAnimation(kOrange),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: SafeArea(
              top: false,
              child: FadeTransition(
                opacity: _loaderFade,
                child: Text(
                  'Sandhya Softtech',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.4,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;
  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    const step = 44.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LogoMark extends StatelessWidget {
  final double size;
  const _LogoMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: [
          BoxShadow(
            color: _SplashScreenState.kOrange.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: ClipRect(
          child: Align(
            alignment: const Alignment(-0.2, -0.22),
            widthFactor: 0.5,
            heightFactor: 0.5,
            child: Image.asset(
              _SplashScreenState.kLogoAsset,
              width: 1000,
              height: 1000,
              fit: BoxFit.cover,
              errorBuilder: (_, error, __) {
                debugPrint('LOGO ASSET ERROR: $error');
                return const SizedBox(
                  width: 1000,
                  height: 1000,
                  child: Icon(
                    Icons.bolt_rounded,
                    color: _SplashScreenState.kOrange,
                    size: 500,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
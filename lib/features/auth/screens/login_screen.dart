import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/services/connectivity_service.dart'; // 👈 Added
import '../../../data/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // ============================
  // THEME COLORS (match web)
  // ============================

  static const Color kOrange = Color(0xFFE8622C);
  static const Color kOrangeLight = Color(0xFFFF7A3D);
  static const Color kDark = Color(0xFF14100E);
  static const Color kText = Color(0xFF1A1A1A);
  static const Color kGrey = Color(0xFF9A9A9F);
  static const Color kFormBg = Color(0xFFF7F7F7);
  static const Color kBorder = Color(0xFFE6E6E6);

  static const String kLogoAsset = 'lib/assets/images/imglo.jpeg';

  // ============================
  // LEFT PANEL SLIDES
  // ============================

  static const List<_Slide> _slides = [
    _Slide(
      lineOne: 'Payroll,',
      lineTwo: 'simplified.',
      description:
      'One platform to manage employees,\nleaves, and salary — effortlessly.',
    ),
    _Slide(
      lineOne: 'Attendance,',
      lineTwo: 'automated.',
      description:
      'Track check-ins, late marks and leaves\nand let payroll calculate itself.',
    ),
    _Slide(
      lineOne: 'Reports,',
      lineTwo: 'real-time.',
      description:
      'Payslips, expenses and daily reports\nready the moment you need them.',
    ),
  ];

  int _slideIndex = 0;
  Timer? _slideTimer;

  late final AnimationController _entranceController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );
    _entranceController.forward();

    _slideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() => _slideIndex = (_slideIndex + 1) % _slides.length);
    });
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _entranceController.dispose();

    _emailController.dispose();
    _passwordController.dispose();

    _emailFocus.dispose();
    _passwordFocus.dispose();

    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: kText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Text(
            'Please enter email and password',
          ),
        ),
      );

      return;
    }

    // 👇 ADDED: Check internet connection before sending request
    final hasInternet = await ConnectivityService.hasInternet();
    if (!mounted) return;

    if (!hasInternet) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: kOrange),
              SizedBox(width: 8),
              Text('No Internet'),
            ],
          ),
          content: const Text(
            'Please check your internet connection and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'OK',
                style: TextStyle(color: kOrange, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _authService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      final require2FA = data['require2FA'] == true;

      // ========================================================
      // 2FA REQUIRED
      // ========================================================

      if (require2FA) {
        final tempToken = data['tempToken'] ?? data['tokens']?['tempToken'];

        if (tempToken == null || tempToken.toString().isEmpty) {
          throw Exception(
            '2FA is required but temp token was not received.',
          );
        }

        await SecureStorage.saveTempToken(
          tempToken.toString(),
        );

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        Navigator.pushReplacementNamed(
          context,
          AppRoutes.twoFactor,
        );

        return;
      }

      // ========================================================
      // NORMAL LOGIN
      // ========================================================

      await _saveUserSession(data);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      await _goToDashboard(
        data['user']?['role'],
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      debugPrint(
        'LOGIN ERROR: $e',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: kText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    }
  }

  // ============================================================
  // SAVE USER SESSION
  // ============================================================

  Future<void> _saveUserSession(
      Map<String, dynamic> data,
      ) async {
    final user = Map<String, dynamic>.from(
      data['user'] ?? {},
    );

    final tokens = Map<String, dynamic>.from(
      data['tokens'] ?? {},
    );

    final accessToken = tokens['accessToken']?.toString();

    final refreshToken = tokens['refreshToken']?.toString();

    final userId = user['_id']?.toString();

    final role = user['role']?.toString();

    final companyId = user['companyId']?.toString();

    // Employee ID is required for:
    // GET /attendance/employee/{employeeId}
    final employeeId = user['employeeId']?.toString();

    // ==========================================================
    // VALIDATION
    // ==========================================================

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception(
        'Access token was not received.',
      );
    }

    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception(
        'Refresh token was not received.',
      );
    }

    if (userId == null || userId.isEmpty) {
      throw Exception(
        'User ID was not received.',
      );
    }

    if (role == null || role.isEmpty) {
      throw Exception(
        'User role was not received.',
      );
    }

    // Employee users must have employeeId
    // because attendance API requires it.
    if (role.toLowerCase() == 'employee' &&
        (employeeId == null || employeeId.isEmpty)) {
      throw Exception(
        'Employee ID was not received.',
      );
    }

    // ==========================================================
    // SAVE SESSION
    // ==========================================================

    await SecureStorage.saveLoginSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      role: role,
      companyId: companyId,
      employeeId: employeeId,
    );
  }

  // ============================================================
  // ROLE-BASED DASHBOARD
  // ============================================================

  Future<void> _goToDashboard(
      String? role,
      ) async {
    final normalizedRole = role?.toLowerCase();

    if (!mounted) return;

    if (normalizedRole == 'employee') {
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFormBg,
      body: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 900;

          if (!wide) {
            return _buildMobile();
          }

          return Row(
            children: [
              Expanded(flex: 48, child: _buildBrandPanel()),
              Expanded(flex: 52, child: _buildFormSide(compact: false)),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // LEFT BRAND PANEL
  // ============================================================

  Widget _buildBrandPanel() {
    final slide = _slides[_slideIndex];

    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: kDark),

        // orange glows
        Positioned(
          left: -120,
          top: -60,
          child: _Glow(size: 560, color: kOrange.withValues(alpha: 0.22)),
        ),
        Positioned(
          right: -200,
          bottom: -180,
          child: _Glow(size: 640, color: kOrange.withValues(alpha: 0.12)),
        ),

        // subtle grid
        const Positioned.fill(child: CustomPaint(painter: _GridPainter())),

        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 450),
                    child: Column(
                      key: ValueKey(_slideIndex),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slide.lineOne,
                          style: const TextStyle(
                            fontSize: 46,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        Text(
                          slide.lineTwo,
                          style: const TextStyle(
                            fontSize: 46,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: kOrangeLight,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          slide.description,
                          style: const TextStyle(
                            fontSize: 14.5,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Row(
                    children: [
                      _StatChip(value: '100%', label: 'AUTOMATED'),
                      SizedBox(width: 12),
                      _StatChip(value: 'Real-time', label: 'REPORTS'),
                      SizedBox(width: 12),
                      _StatChip(value: 'Multi-co', label: 'SUPPORT'),
                    ],
                  ),
                  const SizedBox(height: 34),
                  Row(
                    children: [
                      for (var i = 0; i < _slides.length; i++)
                        GestureDetector(
                          onTap: () => setState(() => _slideIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(right: 6),
                            height: 4,
                            width: i == _slideIndex ? 22 : 4,
                            decoration: BoxDecoration(
                              color: i == _slideIndex
                                  ? kOrange
                                  : Colors.white.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RIGHT FORM SIDE
  // ============================================================

  Widget _buildFormSide({required bool compact}) {
    return Container(
      color: kFormBg,
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 375),
          child: _formColumn(compact: compact),
        ),
      ),
    );
  }

  Widget _formColumn({required bool compact}) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // logo + name
            if (!compact) ...[
              Row(
                children: [
                  const _LogoMark(size: 44),
                  const SizedBox(width: 10),
                  const Text(
                    'Sandhya Salary',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: kText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],

            const Text(
              'Welcome back',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: kText,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sign in to your portal',
              style: TextStyle(fontSize: 13, color: kGrey),
            ),
            const SizedBox(height: 18),

            _label('Email address'),
            const SizedBox(height: 6),
            TextField(
              controller: _emailController,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _passwordFocus.requestFocus(),
              style: _inputTextStyle,
              cursorColor: kOrange,
              decoration: _fieldDecoration(
                hint: 'you@company.com',
                icon: Icons.mail_outline_rounded,
              ),
            ),

            const SizedBox(height: 16),

            _label('Password'),
            const SizedBox(height: 6),
            TextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!_isLoading) _login();
              },
              style: _inputTextStyle,
              cursorColor: kOrange,
              decoration: _fieldDecoration(
                hint: 'Enter your password',
                icon: Icons.lock_outline_rounded,
                suffixIcon: IconButton(
                  splashRadius: 18,
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: kGrey,
                    size: 18,
                  ),
                  onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kOrange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                  kOrange.withValues(alpha: 0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor:
                    AlwaysStoppedAnimation(Colors.white),
                  ),
                )
                    : const Text(
                  'Sign in',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            Text(
              'Super Admin access only  ·  Sandhya Salary © ${DateTime.now().year}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: kGrey.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE LAYOUT (dark brand header + white form sheet)
  // ============================================================

  Widget _buildMobile() {
    final slide = _slides[0];

    return LayoutBuilder(
      builder: (context, c) {
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---------- dark brand header ----------
                  Stack(
                    children: [
                      const Positioned.fill(child: ColoredBox(color: kDark)),
                      Positioned(
                        left: -100,
                        top: -80,
                        child: _Glow(
                          size: 380,
                          color: kOrange.withValues(alpha: 0.30),
                        ),
                      ),
                      Positioned(
                        right: -140,
                        bottom: -160,
                        child: _Glow(
                          size: 360,
                          color: kOrange.withValues(alpha: 0.14),
                        ),
                      ),
                      const Positioned.fill(
                        child: CustomPaint(painter: _GridPainter()),
                      ),
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 56),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const _LogoMark(size: 42),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Sandhya Salary',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 34),
                              Text(
                                slide.lineOne,
                                style: const TextStyle(
                                  fontSize: 34,
                                  height: 1.1,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              Text(
                                slide.lineTwo,
                                style: const TextStyle(
                                  fontSize: 34,
                                  height: 1.1,
                                  fontWeight: FontWeight.w800,
                                  color: kOrangeLight,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                slide.description.replaceAll('\n', ' '),
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ---------- white form sheet ----------
                  Expanded(
                    child: Transform.translate(
                      offset: const Offset(0, -28),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: kFormBg,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        child: _formColumn(compact: true),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static const TextStyle _inputTextStyle = TextStyle(
    fontSize: 13.5,
    color: kText,
    fontWeight: FontWeight.w500,
  );

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: kText,
    ),
  );

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: kGrey.withValues(alpha: 0.85),
        fontSize: 13.5,
      ),
      prefixIcon: Icon(icon, color: kGrey, size: 18),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
      border: border(kBorder),
      enabledBorder: border(kBorder),
      focusedBorder: border(kOrange, 1.4),
    );
  }
}

// ================================================================
// SMALL WIDGETS
// ================================================================

class _Slide {
  final String lineOne;
  final String lineTwo;
  final String description;
  const _Slide({
    required this.lineOne,
    required this.lineTwo,
    required this.description,
  });
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

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the "S" mark from lib/assets/images/imglo.jpeg
/// (the jpeg also contains the "SANDHYA SOFTTECH PVT LTD" text,
/// so only the icon part is cropped out).
class _LogoMark extends StatelessWidget {
  final double size;
  const _LogoMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.06),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: ClipRect(
          child: Align(
            // window = 50% of the image, centred on the S icon
            alignment: const Alignment(-0.2, -0.22),
            widthFactor: 0.5,
            heightFactor: 0.5,
            child: Image.asset(
              _LoginScreenState.kLogoAsset,
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
                    color: _LoginScreenState.kOrange,
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
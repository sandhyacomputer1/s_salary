import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../data/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // ============================
  // THEME COLORS (matches web dashboard)
  // ============================
  static const Color kOrange = Color(0xFFFF6B2C);
  static const Color kOrangeDark = Color(0xFFE85A1A);
  static const Color kBlack = Color(0xFF1C1C1E);
  static const Color kGrey = Color(0xFF8E8E93);
  static const Color kBgWhite = Color(0xFFFAFAFA);
  static const Color kCardBorder = Color(0xFFEDEDED);

  // Staggered entrance controller
  late final AnimationController _entranceController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;

  late final Animation<double> _subtitleFade;

  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  late final Animation<double> _footerFade;

  // Continuous gentle pulse for the logo badge
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  // Field focus scale animations
  double _emailFieldScale = 1.0;
  double _passwordFieldScale = 1.0;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
      ),
    );
    _logoFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );

    _titleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.20, 0.5, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.20, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.6, curve: Curves.easeOut),
    );

    _cardFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _footerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
    );

    _entranceController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.96, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _emailFocus.addListener(() {
      setState(() {
        _emailFieldScale = _emailFocus.hasFocus ? 1.02 : 1.0;
      });
    });

    _passwordFocus.addListener(() {
      setState(() {
        _passwordFieldScale = _passwordFocus.hasFocus ? 1.02 : 1.0;
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: kBlack,
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

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _authService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      final require2FA =
          data['require2FA'] == true;

      // ============================
      // 2FA REQUIRED
      // ============================

      if (require2FA) {
        final tempToken =
            data['tempToken'] ??
                data['tokens']?['tempToken'];

        if (tempToken == null ||
            tempToken.toString().isEmpty) {
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

      // ============================
      // NORMAL LOGIN
      // ============================

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
          backgroundColor: kBlack,
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

  Future<void> _saveUserSession(
      Map<String, dynamic> data,
      ) async {
    final user =
    Map<String, dynamic>.from(
      data['user'] ?? {},
    );

    final tokens =
    Map<String, dynamic>.from(
      data['tokens'] ?? {},
    );

    final accessToken =
    tokens['accessToken']?.toString();

    final refreshToken =
    tokens['refreshToken']?.toString();

    final userId =
    user['_id']?.toString();

    final role =
    user['role']?.toString();

    final companyId =
    user['companyId']?.toString();

    if (accessToken == null ||
        accessToken.isEmpty) {
      throw Exception(
        'Access token was not received.',
      );
    }

    if (refreshToken == null ||
        refreshToken.isEmpty) {
      throw Exception(
        'Refresh token was not received.',
      );
    }

    if (userId == null ||
        userId.isEmpty) {
      throw Exception(
        'User ID was not received.',
      );
    }

    if (role == null ||
        role.isEmpty) {
      throw Exception(
        'User role was not received.',
      );
    }

    await SecureStorage.saveLoginSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      role: role,
      companyId: companyId,
    );
  }

  Future<void> _goToDashboard(
      String? role,
      ) async {
    final normalizedRole =
    role?.toLowerCase();

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

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: kGrey,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(color: kGrey.withOpacity(0.6)),
      prefixIcon: Icon(icon, color: kGrey, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: kBgWhite,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kCardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kCardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kOrange, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ============================
                  // LOGO ROW — scale/fade in, then gentle infinite pulse
                  // ============================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                            child: Container(
                              height: 46,
                              width: 46,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [kOrange, kOrangeDark],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: kOrange.withOpacity(0.35),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.bolt_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FadeTransition(
                        opacity: _titleFade,
                        child: SlideTransition(
                          position: _titleSlide,
                          child: const Text(
                            'S Salary',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: kBlack,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  FadeTransition(
                    opacity: _subtitleFade,
                    child: Text(
                      'Sign in to your dashboard',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: kGrey,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ============================
                  // FLAT CARD — fades and slides up after the header
                  // ============================
                  FadeTransition(
                    opacity: _cardFade,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: Container(
                        padding:
                        const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kCardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kGrey,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            AnimatedScale(
                              scale: _emailFieldScale,
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              child: TextField(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
                                  color: kBlack,
                                  fontWeight: FontWeight.w500,
                                ),
                                cursorColor: kOrange,
                                decoration: _fieldDecoration(
                                  label: '',
                                  hint: 'Enter your email',
                                  icon: Icons.mail_outline_rounded,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            const Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: kGrey,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            AnimatedScale(
                              scale: _passwordFieldScale,
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              child: TextField(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                obscureText: _obscurePassword,
                                style: const TextStyle(
                                  color: kBlack,
                                  fontWeight: FontWeight.w500,
                                ),
                                cursorColor: kOrange,
                                decoration: _fieldDecoration(
                                  label: '',
                                  hint: 'Enter your password',
                                  icon: Icons.lock_outline_rounded,
                                  suffixIcon: IconButton(
                                    icon: AnimatedSwitcher(
                                      duration:
                                      const Duration(milliseconds: 200),
                                      transitionBuilder:
                                          (child, animation) =>
                                          ScaleTransition(
                                            scale: animation,
                                            child: child,
                                          ),
                                      child: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons
                                            .visibility_off_outlined,
                                        key: ValueKey(_obscurePassword),
                                        color: kGrey,
                                        size: 20,
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword =
                                        !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            _AnimatedLoginButton(
                              isLoading: _isLoading,
                              onPressed: _isLoading ? null : _login,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  FadeTransition(
                    opacity: _footerFade,
                    child: Text(
                      'Sandhya Softtech',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: kGrey.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Login button — solid orange fill matching the dashboard's "+ Add Employee"
/// button, with a tap-scale animation, a subtle shimmer sweep, and an
/// animated loading state.
class _AnimatedLoginButton extends StatefulWidget {
  const _AnimatedLoginButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback? onPressed;

  static const Color kOrange = Color(0xFFFF6B2C);
  static const Color kOrangeDark = Color(0xFFE85A1A);

  @override
  State<_AnimatedLoginButton> createState() => _AnimatedLoginButtonState();
}

class _AnimatedLoginButtonState extends State<_AnimatedLoginButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _setScale(double value) {
    if (widget.onPressed == null) return;
    setState(() => _scale = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setScale(0.97),
      onTapUp: (_) => _setScale(1.0),
      onTapCancel: () => _setScale(1.0),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 52,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: widget.onPressed == null
                ? const Color(0xFFD9D9D9)
                : _AnimatedLoginButton.kOrange,
            boxShadow: widget.onPressed == null
                ? []
                : [
              BoxShadow(
                color: _AnimatedLoginButton.kOrange.withOpacity(0.30),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Soft diagonal shimmer sweep, only while enabled
              if (widget.onPressed != null)
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return Positioned.fill(
                      child: FractionalTranslation(
                        translation: Offset(
                          -1.5 + (_shimmerController.value * 3),
                          0,
                        ),
                        child: Transform.rotate(
                          angle: -0.4,
                          child: Container(
                            width: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.0),
                                  Colors.white.withOpacity(0.22),
                                  Colors.white.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: widget.isLoading
                    ? const SizedBox(
                  key: ValueKey('loading'),
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor:
                    AlwaysStoppedAnimation(Colors.white),
                  ),
                )
                    : const Text(
                  'Login',
                  key: ValueKey('label'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
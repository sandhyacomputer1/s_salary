import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/services/connectivity_service.dart';

/// Shown ONLY when the phone / browser is really offline.
///
/// - Checks the connection immediately. If it is online it jumps straight to
///   the splash screen, so this screen is never visible when internet exists.
/// - While offline it re-checks by itself (stream + every 4 seconds).
/// - When the connection is back it goes to Splash, and Splash decides
///   between Login and Dashboard.
class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({super.key});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen>
    with SingleTickerProviderStateMixin {
  static const Color kOrange = Color(0xFFE8622C);
  static const Color kOrangeLight = Color(0xFFFF7A3D);
  static const Color kDark = Color(0xFF14100E);

  StreamSubscription<bool>? _subscription;
  Timer? _poll;
  late final AnimationController _pulse;

  /// true until the first connection check has finished (nothing is shown
  /// except the dark background, so there is no flash of "No Internet").
  bool _checking = true;
  bool _isRetrying = false;
  bool _stillOffline = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _firstCheck();

    // connection comes back -> continue automatically
    _subscription = ConnectivityService.onStatusChange().listen((online) {
      if (online) _continueToApp();
    });

    // safety net: some platforms (web) do not emit stream events reliably
    _poll = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_navigated || _isRetrying) return;
      if (await ConnectivityService.hasInternet()) _continueToApp();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _poll?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _firstCheck() async {
    final online = await ConnectivityService.hasInternet();
    if (!mounted) return;

    if (online) {
      _continueToApp();
    } else {
      setState(() => _checking = false);
    }
  }

  /// Splash checks the saved session and opens Login or the Dashboard.
  void _continueToApp() {
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.pushReplacementNamed(context, AppRoutes.splash);
  }

  Future<void> _retry() async {
    setState(() {
      _isRetrying = true;
      _stillOffline = false;
    });

    final online = await ConnectivityService.hasInternet();
    if (!mounted) return;

    if (online) {
      _continueToApp();
    } else {
      setState(() {
        _isRetrying = false;
        _stillOffline = true;
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

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
            child: _Glow(size: 460, color: kOrange.withValues(alpha: 0.22)),
          ),
          Positioned(
            right: -200,
            bottom: -200,
            child: _Glow(size: 540, color: kOrange.withValues(alpha: 0.12)),
          ),
          const Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _checking ? _buildChecking() : _buildOffline(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecking() {
    return const Center(
      key: ValueKey('checking'),
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(
          strokeWidth: 2.6,
          valueColor: AlwaysStoppedAnimation(kOrange),
        ),
      ),
    );
  }

  Widget _buildOffline() {
    return Center(
      key: const ValueKey('offline'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(),
              const SizedBox(height: 34),
              const Text(
                'No Internet Connection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'We could not reach the server. Check your\nconnection and we will continue automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 26),
              _buildTips(),
              const SizedBox(height: 28),
              SizedBox(
                height: 48,
                width: double.infinity,
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
                      : const Icon(Icons.refresh_rounded, size: 19),
                  label: Text(
                    _isRetrying ? 'Checking...' : 'Try Again',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kOrange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: kOrange.withValues(alpha: 0.6),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AnimatedOpacity(
                opacity: _stillOffline ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: const Text(
                  'Still offline. Please check your network.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFFFF8A80)),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: kOrange, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Waiting for connection...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// White circle with a wifi-off icon and two expanding orange rings.
  Widget _buildIcon() {
    return SizedBox(
      width: 190,
      height: 190,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          Widget ring(double t) {
            final v = (_pulse.value + t) % 1.0;
            return Opacity(
              opacity: (1 - v) * 0.45,
              child: Container(
                width: 96 + v * 94,
                height: 96 + v * 94,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kOrangeLight, width: 1.6),
                ),
              ),
            );
          }

          return Stack(
            alignment: Alignment.center,
            children: [
              ring(0),
              ring(0.5),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kOrange.withValues(alpha: 0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.wifi_off_rounded, size: 46, color: kOrange),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTips() {
    Widget tip(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 17, color: kOrangeLight),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          tip(Icons.wifi_rounded, 'Check your Wi-Fi or mobile data'),
          tip(Icons.airplanemode_inactive_rounded, 'Turn off airplane mode'),
          tip(Icons.router_outlined, 'Move closer to your router'),
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
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
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
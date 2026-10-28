// lib/features/employee/dashboard/screens/emp_attendance_camera_screen.dart

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Full screen selfie screen used for Check In / Check Out.
///
///  1. Opens the FRONT camera automatically (live preview + face guide).
///  2. Employee taps the shutter -> photo preview.
///     If the camera is not available (or the employee prefers it) a photo
///     can be chosen from the GALLERY instead.
///  3. "Retake" or "Confirm" -> [onConfirm] is called with the photo
///     (data:image/jpeg;base64,...). While it runs the screen shows a
///     progress state. If it throws, the error is shown here and the
///     employee can retry. On success the screen closes with `true`.
///
/// Back / Cancel closes the screen with `false` (back to dashboard).
class EmpAttendanceCameraScreen extends StatefulWidget {
  final bool isCheckIn;

  /// Show the "Choose from gallery" option.
  final bool allowGallery;

  final Future<void> Function(String photoDataUri) onConfirm;

  const EmpAttendanceCameraScreen({
    super.key,
    required this.isCheckIn,
    required this.onConfirm,
    this.allowGallery = true,
  });

  @override
  State<EmpAttendanceCameraScreen> createState() =>
      _EmpAttendanceCameraScreenState();
}

class _EmpAttendanceCameraScreenState extends State<EmpAttendanceCameraScreen>
    with WidgetsBindingObserver {
  static const Color _bg = Color(0xFF0F0C0A);
  static const Color _checkInColor = Color(0xFFE8622C);
  static const Color _checkOutColor = Color(0xFFDC4A26);

  final ImagePicker _picker = ImagePicker();

  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  CameraController? _controller;

  bool _ready = false;
  bool _capturing = false;
  bool _submitting = false;
  bool _picking = false;
  bool _fromGallery = false;
  String? _initError;
  String? _submitError;

  Uint8List? _photo; // captured / picked image

  Color get _accent => widget.isCheckIn ? _checkInColor : _checkOutColor;
  String get _actionName => widget.isCheckIn ? 'Check In' : 'Check Out';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  // Release the camera when the app goes to background, reopen on return.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (state == AppLifecycleState.inactive) {
      if (c != null) {
        _controller = null;
        _ready = false;
        c.dispose();
        if (mounted) setState(() {});
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_controller == null && _photo == null && !_submitting) {
        _startCamera();
      }
    }
  }

  // ============================================================
  // CAMERA
  // ============================================================

  Future<void> _startCamera() async {
    if (!mounted) return;
    setState(() {
      _ready = false;
      _initError = null;
    });

    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
      }

      if (_cameras.isEmpty) {
        _fail('No camera was found on this device.');
        return;
      }

      // FRONT camera by default.
      if (_controller == null) {
        final front = _cameras.indexWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
        );
        _cameraIndex = front >= 0 ? front : 0;
      }

      final old = _controller;
      _controller = null;
      await old?.dispose();

      final controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.medium, // keeps the photo small
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {}

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _ready = true;
      });
    } on CameraException catch (e) {
      _fail(_messageFor(e));
    } catch (_) {
      _fail('Could not open the camera.');
    }
  }

  String _messageFor(CameraException e) {
    final code = e.code.toLowerCase();

    if (code.contains('denied') || code.contains('permission')) {
      return widget.allowGallery
          ? 'Camera permission is blocked.\n'
          'Allow Camera access in your phone settings, '
          'or choose a photo from your gallery.'
          : 'Camera permission is blocked.\n'
          'Please allow Camera access for this app in your phone settings.';
    }

    return e.description ?? 'Could not open the camera.';
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _initError = message;
      _ready = false;
    });
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _capturing || _submitting) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _startCamera();
  }

  Future<void> _capture() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _capturing) return;

    setState(() => _capturing = true);

    try {
      final file = await c.takePicture();
      final bytes = await file.readAsBytes();

      if (!mounted) return;
      setState(() {
        _photo = bytes;
        _fromGallery = false;
        _capturing = false;
        _submitError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _capturing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not capture the photo. Try again.')),
      );
    }
  }

  // ============================================================
  // GALLERY
  // ============================================================

  Future<void> _pickFromGallery() async {
    if (_capturing || _submitting || _picking) return;

    setState(() => _picking = true);

    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080, // keeps the upload small
        imageQuality: 80,
      );

      if (file == null) {
        // user cancelled
        if (mounted) setState(() => _picking = false);
        return;
      }

      final bytes = await file.readAsBytes();

      if (!mounted) return;
      setState(() {
        _photo = bytes;
        _fromGallery = true;
        _picking = false;
        _submitError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _picking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the gallery. Try again.')),
      );
    }
  }

  void _retake() {
    if (_submitting) return;
    setState(() {
      _photo = null;
      _fromGallery = false;
      _submitError = null;
    });

    if (_controller == null) _startCamera();
  }

  Future<void> _confirm() async {
    final photo = _photo;
    if (photo == null || _submitting) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      await widget.onConfirm('data:image/jpeg;base64,${base64Encode(photo)}');

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _close() {
    if (_submitting) return;
    Navigator.of(context).pop(false);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // soft accent glow
            Positioned(
              top: -140,
              left: -100,
              child: IgnorePointer(
                child: Container(
                  width: 420,
                  height: 420,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _accent.withValues(alpha: 0.22),
                        _accent.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(child: _buildCenter()),
                  _buildBottom(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back to dashboard',
            onPressed: _submitting ? null : _close,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _actionName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _photo == null
                      ? 'Take a selfie to verify your attendance'
                      : 'Review your photo',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accent.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isCheckIn ? Icons.login_rounded : Icons.logout_rounded,
                  size: 14,
                  color: _accent,
                ),
                const SizedBox(width: 5),
                Text(
                  widget.isCheckIn ? 'IN' : 'OUT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: _accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenter() {
    return LayoutBuilder(
      builder: (context, c) {
        // Portrait frame (3:4) that fits the free space.
        double w = (c.maxWidth - 40).clamp(200.0, 420.0);
        double h = w * 4 / 3;
        if (h > c.maxHeight - 56) {
          h = (c.maxHeight - 56).clamp(200.0, 560.0);
          w = h * 3 / 4;
        }

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: _submitError != null
                        ? const Color(0xFFEF4444)
                        : Colors.white.withValues(alpha: 0.14),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withValues(alpha: 0.18),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: _buildFrameContent(),
                ),
              ),
              const SizedBox(height: 16),
              _buildHint(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFrameContent() {
    // Captured / picked photo review
    if (_photo != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(_photo!, fit: BoxFit.cover, gaplessPlayback: true),
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _fromGallery
                        ? Icons.photo_library_rounded
                        : Icons.check_circle_rounded,
                    size: 14,
                    color: const Color(0xFF22C55E),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _fromGallery ? 'Photo selected' : 'Photo captured',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_submitting)
            Container(
              color: Colors.black.withValues(alpha: 0.45),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      );
    }

    // Camera problem
    if (_initError != null) {
      return Container(
        color: const Color(0xFF1A1512),
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_off_outlined,
                size: 44,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 14),
              Text(
                _initError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _startCamera,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (widget.allowGallery) ...[
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _picking ? null : _pickFromGallery,
                  icon: _picking
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Choose from gallery'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _accent.withValues(alpha: 0.6),
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Loading camera
    final controller = _controller;
    if (!_ready || controller == null || !controller.value.isInitialized) {
      return Container(
        color: const Color(0xFF1A1512),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            color: Color(0xFFE8622C),
          ),
        ),
      );
    }

    // Live preview + face guide
    final portrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;
    var ar = controller.value.aspectRatio;
    if (portrait && ar > 1) ar = 1 / ar;
    if (!portrait && ar < 1) ar = 1 / ar;

    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: 300,
            height: 300 / ar,
            child: CameraPreview(controller),
          ),
        ),
        IgnorePointer(
          child: CustomPaint(painter: _FaceGuidePainter(color: _accent)),
        ),
      ],
    );
  }

  Widget _buildHint() {
    if (_submitError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 16,
              color: Color(0xFFF87171),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _submitError!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF87171),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_submitting) {
      return Text(
        'Verifying location & submitting…',
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.75),
        ),
      );
    }

    return Text(
      _photo == null
          ? 'Keep your face inside the frame'
          : 'Make sure your face is clearly visible',
      style: TextStyle(
        fontSize: 12.5,
        color: Colors.white.withValues(alpha: 0.6),
      ),
    );
  }

  // ============================================================
  // BOTTOM CONTROLS
  // ============================================================

  Widget _buildBottom() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
      child: _photo == null ? _buildCaptureControls() : _buildReviewControls(),
    );
  }

  Widget _buildCaptureControls() {
    final canShoot = _ready && !_capturing && !_picking;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Cancel
        SizedBox(
          width: 96,
          child: TextButton.icon(
            onPressed: _close,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withValues(alpha: 0.85),
              textStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Shutter
        GestureDetector(
          onTap: canShoot ? _capture : null,
          child: AnimatedOpacity(
            opacity: canShoot ? 1 : 0.45,
            duration: const Duration(milliseconds: 150),
            child: Container(
              width: 78,
              height: 78,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _capturing ? Colors.white54 : _accent,
                ),
                alignment: Alignment.center,
                child: _capturing
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
                    : const Icon(
                  Icons.photo_camera_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),

        // Gallery + flip camera
        SizedBox(
          width: 96,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.allowGallery)
                IconButton(
                  tooltip: 'Choose from gallery',
                  onPressed: (_capturing || _picking) ? null : _pickFromGallery,
                  icon: const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white,
                  ),
                ),
              if (_cameras.length > 1)
                IconButton(
                  tooltip: 'Switch camera',
                  onPressed: _switchCamera,
                  icon: const Icon(
                    Icons.flip_camera_android_rounded,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewControls() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _submitting ? null : _retake,
              icon: const Icon(Icons.refresh_rounded, size: 19),
              label: const Text('Retake'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white30,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: _submitting ? 0.15 : 0.4),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _confirm,
              icon: _submitting
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
                  : Icon(
                _submitError != null
                    ? Icons.replay_rounded
                    : Icons.check_rounded,
                size: 20,
              ),
              label: Text(
                _submitting
                    ? 'Submitting…'
                    : _submitError != null
                    ? 'Try again'
                    : 'Confirm $_actionName',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _accent.withValues(alpha: 0.6),
                disabledForegroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ================================================================
// FACE GUIDE (dimmed edges + oval cut-out)
// ================================================================

class _FaceGuidePainter extends CustomPainter {
  final Color color;
  const _FaceGuidePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.45),
      width: size.width * 0.66,
      height: size.height * 0.56,
    );

    final overlay = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(ovalRect);

    canvas.drawPath(
      overlay,
      Paint()..color = Colors.black.withValues(alpha: 0.38),
    );

    canvas.drawOval(
      ovalRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = color.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(covariant _FaceGuidePainter oldDelegate) =>
      oldDelegate.color != color;
}
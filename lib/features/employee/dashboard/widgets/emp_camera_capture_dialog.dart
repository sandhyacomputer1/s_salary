// lib/features/employee/dashboard/widgets/emp_camera_capture_dialog.dart

import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Webcam capture window for the browser (Flutter web).
///
/// image_picker cannot open the webcam on a desktop browser (it only opens a
/// file chooser), so on web this dialog shows a live camera preview with a
/// Capture button. It returns the photo bytes, or null if cancelled.
///
/// Needs:  flutter pub add camera
/// The browser asks for camera permission (works on https or localhost).
class EmpCameraCaptureDialog extends StatefulWidget {
  final String title;

  const EmpCameraCaptureDialog({super.key, this.title = 'Take a photo'});

  static Future<Uint8List?> show(
      BuildContext context, {
        String title = 'Take a photo',
      }) {
    return showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => EmpCameraCaptureDialog(title: title),
    );
  }

  @override
  State<EmpCameraCaptureDialog> createState() => _EmpCameraCaptureDialogState();
}

class _EmpCameraCaptureDialogState extends State<EmpCameraCaptureDialog> {
  static const Color _primary = Color(0xFFE96832);
  static const Color _textDark = Color(0xFF18212F);
  static const Color _textMedium = Color(0xFF4B5563);
  static const Color _border = Color(0xFFE5E7EB);

  CameraController? _controller;
  bool _ready = false;
  bool _capturing = false;
  String? _error;
  String? _captureError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        _fail('No camera was found on this device.');
        return;
      }

      // Prefer the front (selfie) camera when there is one.
      final camera = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium, // keeps the photo small
        enableAudio: false,
      );

      await controller.initialize();

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
      return 'Camera access is blocked. Allow the camera in the browser '
          'address bar, then try again.';
    }

    return e.description ?? 'Could not open the camera.';
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() => _error = message);
  }

  Future<void> _capture() async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }

    setState(() {
      _capturing = true;
      _captureError = null;
    });

    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();

      if (!mounted) return;
      Navigator.of(context).pop(bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _capturing = false;
        _captureError = 'Could not capture the photo. Please try again.';
      });
    }
  }

  /// Fallback when there is no webcam or permission is blocked.
  Future<void> _chooseFile() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();

      if (!mounted) return;
      Navigator.of(context).pop(bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not read the selected photo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEE7),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.photo_camera_outlined,
                      size: 18,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed:
                    _capturing ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildPreview(),
              if (_captureError != null) ...[
                const SizedBox(height: 10),
                Text(
                  _captureError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.videocam_off_outlined,
              size: 36,
              color: Color(0xFF8A93A1),
            ),
            const SizedBox(height: 10),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _textMedium),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _chooseFile,
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: const Text('Choose a photo instead'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _textDark,
                side: const BorderSide(color: Color(0xFFD9DEE7)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final controller = _controller;

    if (!_ready || controller == null) {
      return Container(
        height: 240,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: _primary),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _buildButtons() {
    if (_error != null) {
      return OutlinedButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _capturing ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: _textDark,
              side: const BorderSide(color: Color(0xFFD9DEE7)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: (_ready && !_capturing) ? _capture : null,
            icon: _capturing
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.photo_camera_rounded, size: 18),
            label: const Text('Capture & Continue'),
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
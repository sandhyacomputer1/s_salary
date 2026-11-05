import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../employees/widgets/admin_employee_theme.dart';

/// Small photo box for check-in / check-out. Tap to view full screen.
/// Works with base64 data URIs ("data:image/jpeg;base64,...") and normal links.
class AttendancePhotoThumb extends StatefulWidget {
  final String? url;
  final String label; // "In" or "Out"
  final double size;

  const AttendancePhotoThumb({
    super.key,
    required this.url,
    required this.label,
    this.size = 40,
  });

  @override
  State<AttendancePhotoThumb> createState() => _AttendancePhotoThumbState();
}

class _AttendancePhotoThumbState extends State<AttendancePhotoThumb> {
  Uint8List? _bytes; // decoded once, not on every rebuild

  bool get _hasPhoto => widget.url != null && widget.url!.trim().isNotEmpty;
  bool get _isData => _hasPhoto && widget.url!.trim().startsWith('data:');

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(covariant AttendancePhotoThumb old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) _decode();
  }

  void _decode() {
    _bytes = null;
    if (!_isData) return;
    try {
      final s = widget.url!.trim();
      _bytes = base64Decode(s.substring(s.indexOf(',') + 1));
    } catch (_) {
      _bytes = null;
    }
  }

  Widget _image({BoxFit fit = BoxFit.cover, bool full = false}) {
    const broken = Icon(Icons.broken_image_outlined, size: 18, color: AdminEmpColors.muted);
    if (_isData) {
      if (_bytes == null) return broken;
      return Image.memory(_bytes!, fit: fit, gaplessPlayback: true, errorBuilder: (c, e, s) => broken);
    }
    return Image.network(
      widget.url!.trim(),
      fit: fit,
      loadingBuilder: (c, child, p) => p == null
          ? child
          : const Center(
        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorBuilder: (c, e, s) => broken,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return GestureDetector(
      onTap: _hasPhoto ? () => _openFull(context) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AdminEmpColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: _hasPhoto
                ? _image()
                : const Icon(Icons.no_photography_outlined, size: 18, color: AdminEmpColors.muted),
          ),
          const SizedBox(height: 2),
          Text(widget.label, style: const TextStyle(fontSize: 10.5, color: AdminEmpColors.muted)),
        ],
      ),
    );
  }

  void _openFull(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(child: _image(fit: BoxFit.contain, full: true)),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens a photo full screen (pinch to zoom). Works with base64 data URIs and links.
void showAttendancePhoto(BuildContext context, String url, {String? title}) {
  Uint8List? bytes;
  final u = url.trim();
  if (u.startsWith('data:')) {
    try {
      bytes = base64Decode(u.substring(u.indexOf(',') + 1));
    } catch (_) {}
  }

  const failed = Padding(
    padding: EdgeInsets.all(40),
    child: Text('Could not load photo', style: TextStyle(color: Colors.white)),
  );

  Widget img;
  if (u.startsWith('data:')) {
    img = bytes == null
        ? failed
        : Image.memory(bytes, fit: BoxFit.contain, errorBuilder: (c, e, s) => failed);
  } else {
    img = Image.network(u, fit: BoxFit.contain, errorBuilder: (c, e, s) => failed);
  }

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          InteractiveViewer(child: Center(child: img)),
          if (title != null)
            Positioned(
              top: 14,
              left: 16,
              child: Text(title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
        ],
      ),
    ),
  );
}
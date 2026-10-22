import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/admin_attendance_model.dart';
import '../utils/notification_theme.dart';

Future<void> showAttendancePhotoDialog(
    BuildContext context,
    AttendanceEvent event,
    ) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _PhotoDialog(event: event),
  );
}

class _PhotoDialog extends StatelessWidget {
  final AttendanceEvent event;
  const _PhotoDialog({required this.event});

  @override
  Widget build(BuildContext context) {
    final raw = event.photoUrl;

    Widget imageWidget;
    if (raw == null || raw.isEmpty) {
      imageWidget = const _EmptyPhoto();
    } else if (raw.startsWith('http')) {
      // Standard URL
      imageWidget = Image.network(
        raw,
        fit: BoxFit.contain,
        loadingBuilder: (c, child, p) {
          if (p == null) return child;
          return const Center(child: CircularProgressIndicator(color: NotificationColors.primary));
        },
        errorBuilder: (_, __, ___) => const _EmptyPhoto(message: 'Photo could not be loaded'),
      );
    } else {
      // Base64 String (from your backend)
      try {
        final base64Str = raw.contains(',') ? raw.split(',').last : raw;
        imageWidget = Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const _EmptyPhoto(message: 'Invalid photo format'),
        );
      } catch (_) {
        imageWidget = const _EmptyPhoto(message: 'Could not decode photo');
      }
    }

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Check-In / Check-Out Live Selfie Photo',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageWidget,
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

class _EmptyPhoto extends StatelessWidget {
  final String message;
  const _EmptyPhoto({this.message = 'No selfie photo on record'});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: NotificationColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_not_supported_outlined, size: 40, color: NotificationTableColors.dash),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontSize: 12, color: NotificationColors.textLight)),
          ],
        ),
      ),
    );
  }
}
import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationFailure implements Exception {
  final String message;

  /// True when the user must change a setting manually
  /// (permission permanently denied, or location services off).
  final bool needsSettings;
  final bool isServiceDisabled;

  const LocationFailure(
      this.message, {
        this.needsSettings = false,
        this.isServiceDisabled = false,
      });

  @override
  String toString() => message;
}

class BranchLocationService {
  BranchLocationService._();

  /// Returns the current position, or throws [LocationFailure] with a
  /// message that is safe to show directly to the user.
  static Future<Position> detect() async {
    final serviceOn = await Geolocator.isLocationServiceEnabled();

    if (!serviceOn) {
      throw const LocationFailure(
        'Location services are turned off. Enable them and try again.',
        needsSettings: true,
        isServiceDisabled: true,
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationFailure(
        'Location permission was denied. Allow it to detect the branch location.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        'Location permission is permanently denied. Enable it in app settings.',
        needsSettings: true,
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      throw const LocationFailure(
        'Could not get a GPS fix in time. Move to an open area and retry.',
      );
    } catch (_) {
      throw const LocationFailure(
        'Unable to read your location right now. Please try again.',
      );
    }
  }

  /// Opens the relevant system screen when [LocationFailure.needsSettings].
  static Future<void> openSettings(LocationFailure failure) async {
    if (failure.isServiceDisabled) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  /// 6 decimals is roughly 0.1 m, plenty for a geofence centre.
  static String format(double value) => value.toStringAsFixed(6);
}
import 'dart:async';
import 'dart:io' show InternetAddress;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Works with connectivity_plus 5.x (single result) and 6.x (list of results),
/// on Android, iOS and Web.
///
/// IMPORTANT for Web: `InternetAddress.lookup` does not exist in the browser.
/// If a service uses it on web it always fails and the app thinks it is
/// offline, so the browser's own online state is used there.
class ConnectivityService {
  ConnectivityService._();

  static final Connectivity _connectivity = Connectivity();

  static bool _isOnline(dynamic result) {
    if (result is List) {
      return result.any((r) => r != ConnectivityResult.none);
    }
    return result != ConnectivityResult.none;
  }

  /// true when the device can really reach the internet.
  static Future<bool> hasInternet() async {
    try {
      final dynamic result = await _connectivity.checkConnectivity();
      if (!_isOnline(result)) return false;

      // Web: the browser already tells us. (No raw sockets in a browser.)
      if (kIsWeb) return true;

      // Mobile / desktop: connected to Wi-Fi does not always mean internet,
      // so make one tiny DNS lookup.
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Emits true / false whenever the connection changes.
  static Stream<bool> onStatusChange() {
    return _connectivity.onConnectivityChanged.asyncMap((dynamic result) async {
      if (!_isOnline(result)) return false;
      return hasInternet();
    }).distinct();
  }
}
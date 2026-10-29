import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._();

  static final Connectivity _connectivity = Connectivity();

  /// Returns true if the device has an active network (Wi-Fi / Mobile / Ethernet)
  static Future<bool> hasInternet() async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  /// Stream that emits `true` when connection comes back, `false` when it drops.
  static Stream<bool> onStatusChange() {
    return _connectivity.onConnectivityChanged.map(_hasConnection);
  }

  static bool _hasConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;

    return results.any(
          (r) =>
      r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn,
    );
  }
}
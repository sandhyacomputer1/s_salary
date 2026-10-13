import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/field_employee_location_model.dart';
import '../models/location_history_model.dart';
import 'field_tracking_format.dart';

const Color _kPrimary = Color(0xFFE96832);
const Color _kTextDark = Color(0xFF18212F);
const Color _kBorder = Color(0xFFE5E7EB);

/// Google Map for the Field Tracking screen.
///
/// - No employee selected: one marker per employee that has a real location,
///   coloured by freshness (green live, yellow recent, red stale).
/// - Employee selected: their latest location marker (only when
///   [showLatestMarker]) plus the route for the chosen date: a polyline in
///   time order, a green start point, a red last point and small blue
///   intermediate points. A polyline is drawn only with 2+ valid points.
///
/// The camera is re-fitted when the selection / date / data availability
/// changes, NOT on every 30-second refresh, so it never fights the user's
/// panning and zooming.
class LocationHistoryMap extends StatefulWidget {
  const LocationHistoryMap({
    super.key,
    required this.employees,
    required this.selected,
    required this.history,
    required this.historyLoading,
    required this.showLatestMarker,
    required this.onSelectEmployee,
    required this.onClearSelection,
  });

  final List<FieldEmployeeLocation> employees;
  final FieldEmployeeLocation? selected;

  /// History of [selected] for the chosen date (null until loaded).
  final LocationHistory? history;
  final bool historyLoading;

  /// False when browsing a past date: the live "latest" marker would be
  /// misleading next to an old route.
  final bool showLatestMarker;

  final ValueChanged<FieldEmployeeLocation> onSelectEmployee;
  final VoidCallback onClearSelection;

  @override
  State<LocationHistoryMap> createState() => _LocationHistoryMapState();
}

class _LocationHistoryMapState extends State<LocationHistoryMap> {
  /// Only a default viewport for when there is no data. It is NOT used as an
  /// employee position.
  static const LatLng _defaultCenter = LatLng(20.5937, 78.9629);
  static const double _defaultZoom = 4.2;

  GoogleMapController? _controller;
  String _lastFocusKey = '';

  @override
  void initState() {
    super.initState();
    _lastFocusKey = _focusKey;
  }

  @override
  void didUpdateWidget(covariant LocationHistoryMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final key = _focusKey;
    if (key != _lastFocusKey) {
      _lastFocusKey = key;
      _applyFocus();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // ==========================================================
  // CAMERA
  // ==========================================================

  String get _focusKey {
    final sel = widget.selected;
    final hist = widget.history;
    final hasRoute = hist != null && !hist.isEmpty;
    final located = widget.employees.any((e) => e.hasLocation);

    return '${sel?.id}|${hist?.date}|$hasRoute|'
        '${sel == null ? located : sel.hasLocation}';
  }

  List<LatLng> _focusPoints() {
    final sel = widget.selected;
    final hist = widget.history;

    if (sel != null) {
      if (hist != null && !hist.isEmpty) {
        return hist.points.map((p) => LatLng(p.lat, p.lng)).toList();
      }

      final loc = sel.location;
      if (loc != null && widget.showLatestMarker) {
        return [LatLng(loc.lat, loc.lng)];
      }

      return const [];
    }

    return widget.employees
        .where((e) => e.hasLocation)
        .map((e) => LatLng(e.location!.lat, e.location!.lng))
        .toList();
  }

  Future<void> _applyFocus({bool retry = true}) async {
    final controller = _controller;
    if (controller == null) return;

    final points = _focusPoints();

    try {
      if (points.isEmpty) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(_defaultCenter, _defaultZoom),
        );
        return;
      }

      var minLat = points.first.latitude;
      var maxLat = points.first.latitude;
      var minLng = points.first.longitude;
      var maxLng = points.first.longitude;

      for (final p in points) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }

      // One point, or several at the same spot: zoom in instead of fitting.
      if (minLat == maxLat && minLng == maxLng) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(minLat, minLng), 16),
        );
        return;
      }

      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          64,
        ),
      );
    } catch (_) {
      // The map may not be laid out yet; try once more shortly.
      if (retry && mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (mounted) await _applyFocus(retry: false);
      }
    }
  }

  // ==========================================================
  // MARKERS + ROUTE
  // ==========================================================

  double _hue(LocationFreshness f) {
    switch (f) {
      case LocationFreshness.live:
        return BitmapDescriptor.hueGreen;
      case LocationFreshness.recent:
        return BitmapDescriptor.hueYellow;
      case LocationFreshness.stale:
        return BitmapDescriptor.hueRed;
      case LocationFreshness.unknownTime:
        return BitmapDescriptor.hueViolet;
      case LocationFreshness.noLocation:
        return BitmapDescriptor.hueAzure;
    }
  }

  String _snippet(LocationPoint p, {String? prefix}) {
    final parts = <String>[
      ?prefix,
      FieldTrackingFormat.dateTime(p.timestamp),
      if (p.address != null) p.address!,
      if (FieldTrackingFormat.hasBattery(p.batteryLevel))
        'Battery ${FieldTrackingFormat.battery(p.batteryLevel)}',
    ];

    return parts.join('  •  ');
  }

  Marker _employeeMarker(FieldEmployeeLocation e, LocationPoint p) {
    final freshness = FieldTrackingFormat.freshness(p);

    return Marker(
      markerId: MarkerId('emp-${e.id}'),
      position: LatLng(p.lat, p.lng),
      icon: BitmapDescriptor.defaultMarkerWithHue(_hue(freshness)),
      infoWindow: InfoWindow(
        title: e.name.isEmpty ? 'Unnamed Employee' : e.name,
        snippet: _snippet(
          p,
          prefix: FieldTrackingFormat.freshnessLabel(freshness),
        ),
      ),
      onTap: () => widget.onSelectEmployee(e),
    );
  }

  Set<Marker> _markers() {
    final markers = <Marker>{};
    final sel = widget.selected;
    final hist = widget.history;

    if (sel == null) {
      for (final e in widget.employees) {
        final p = e.location;
        if (p != null) markers.add(_employeeMarker(e, p));
      }
      return markers;
    }

    final latest = sel.location;

    if (widget.showLatestMarker && latest != null) {
      markers.add(_employeeMarker(sel, latest));
    }

    if (hist != null && !hist.isEmpty) {
      final pts = hist.points;

      for (var i = 0; i < pts.length; i++) {
        final p = pts[i];
        final isFirst = i == 0;
        final isLast = i == pts.length - 1;

        // Avoid stacking the last route point under the latest marker.
        if (isLast &&
            widget.showLatestMarker &&
            latest != null &&
            latest.lat == p.lat &&
            latest.lng == p.lng) {
          continue;
        }

        final prefix = pts.length < 2
            ? 'Recorded point'
            : (isFirst ? 'Start' : (isLast ? 'Last point' : 'Route point'));

        markers.add(
          Marker(
            markerId: MarkerId('hist-$i'),
            position: LatLng(p.lat, p.lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isFirst
                  ? BitmapDescriptor.hueGreen
                  : (isLast
                        ? BitmapDescriptor.hueRed
                        : BitmapDescriptor.hueAzure),
            ),
            alpha: (isFirst || isLast) ? 1 : 0.75,
            infoWindow: InfoWindow(title: prefix, snippet: _snippet(p)),
          ),
        );
      }
    }

    return markers;
  }

  Set<Polyline> _polylines() {
    final hist = widget.history;

    // Never invent geometry: a line needs at least two real points.
    if (widget.selected == null || hist == null || !hist.hasRoute) {
      return const <Polyline>{};
    }

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: hist.points.map((p) => LatLng(p.lat, p.lng)).toList(),
        color: _kPrimary,
        width: 5,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    final hist = widget.history;

    final hasHistoryPoints = hist != null && !hist.isEmpty;
    final hasLatestShown = widget.showLatestMarker && sel?.location != null;

    final showNoData =
        sel != null &&
        !widget.historyLoading &&
        !hasHistoryPoints &&
        !hasLatestShown;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        color: const Color(0xFFEAF2F8),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _defaultCenter,
                zoom: _defaultZoom,
              ),
              markers: _markers(),
              polylines: _polylines(),
              onMapCreated: (controller) {
                _controller = controller;
                Future<void>.delayed(
                  const Duration(milliseconds: 350),
                  _applyFocus,
                );
              },
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              compassEnabled: true,
            ),
          ),

          if (widget.historyLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 3,
                color: _kPrimary,
                backgroundColor: Colors.transparent,
              ),
            ),

          if (sel != null)
            Positioned(
              top: 12,
              left: 12,
              child: Material(
                color: Colors.white,
                elevation: 2,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: widget.onClearSelection,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_rounded, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'All employees',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _kTextDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          Positioned(
            top: 12,
            right: 12,
            child: Material(
              color: Colors.white,
              elevation: 2,
              borderRadius: BorderRadius.circular(10),
              child: IconButton(
                tooltip: sel == null ? 'Fit all employees' : 'Fit route',
                onPressed: _applyFocus,
                icon: const Icon(Icons.center_focus_strong_rounded),
              ),
            ),
          ),

          Positioned(left: 12, bottom: 44, child: _legend()),
          if (showNoData)
            Positioned(
              left: 12,
              right: 12,
              bottom: 92,              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Text(
                    'No location records for this employee on the selected '
                    'date.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: _kTextDark),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _legend() {
    Widget item(Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: _kTextDark)),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          item(
            FieldTrackingFormat.freshnessColor(LocationFreshness.live),
            'Live',
          ),
          const SizedBox(width: 10),
          item(
            FieldTrackingFormat.freshnessColor(LocationFreshness.recent),
            'Recent',
          ),
          const SizedBox(width: 10),
          item(
            FieldTrackingFormat.freshnessColor(LocationFreshness.stale),
            'Stale',
          ),
        ],
      ),
    );
  }
}

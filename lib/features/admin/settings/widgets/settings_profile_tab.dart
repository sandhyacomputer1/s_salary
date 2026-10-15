import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../branches/services/branch_location_service.dart';
import '../models/company_profile_model.dart';
import 'settings_common.dart';

/// "Profile & Location" tab: name, timezone, address, office pin on a Google
/// Map, geofence radius and the Active checkbox. The pin can be set by
/// tapping the map, dragging the marker, or "Use Current GPS Location".
class SettingsProfileTab extends StatefulWidget {
  const SettingsProfileTab({
    super.key,
    required this.profile,
    required this.onChanged,
    required this.dirty,
    required this.saving,
    required this.onSave,
  });

  /// The working copy; edited in place, then [onChanged] is called.
  final CompanyProfile profile;
  final VoidCallback onChanged;
  final bool dirty;
  final bool saving;
  final VoidCallback onSave;

  @override
  State<SettingsProfileTab> createState() => _SettingsProfileTabState();
}

class _SettingsProfileTabState extends State<SettingsProfileTab> {
  /// Viewport used only when no pin exists. It is not a company location.
  static const LatLng _defaultCenter = LatLng(20.5937, 78.9629);

  GoogleMapController? _map;
  bool _locating = false;
  String? _gpsError;
  LocationFailure? _gpsFailure;

  CompanyProfile get _p => widget.profile;

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  // ==========================================================
  // PIN
  // ==========================================================

  void _setPin(double lat, double lng) {
    if (!CompanyProfile.isValidPoint(lat, lng)) return;

    _p.latitude = lat;
    _p.longitude = lng;
    widget.onChanged();

    _map?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16));
  }

  void _clearPin() {
    _p.latitude = null;
    _p.longitude = null;
    widget.onChanged();
  }

  Future<void> _useCurrentLocation() async {
    if (_locating || widget.saving) return;

    setState(() {
      _locating = true;
      _gpsError = null;
      _gpsFailure = null;
    });

    try {
      final position = await BranchLocationService.detect();
      if (!mounted) return;
      _setPin(position.latitude, position.longitude);
    } on LocationFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _gpsError = e.message;
        _gpsFailure = e;
      });
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsRow(
          children: [
            SettingsLabeled(
              label: 'Company Name',
              child: SettingsTextField(
                initialValue: _p.name,
                onChanged: (v) {
                  _p.name = v;
                  widget.onChanged();
                },
              ),
            ),
            SettingsLabeled(
              label: 'Timezone',
              child: SettingsTextField(
                initialValue: _p.timezone,
                hint: 'e.g. UTC or Asia/Kolkata',
                onChanged: (v) {
                  _p.timezone = v;
                  widget.onChanged();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SettingsLabeled(
          label: 'Office Address',
          child: SettingsTextField(
            initialValue: _p.address,
            onChanged: (v) {
              _p.address = v;
              widget.onChanged();
            },
          ),
        ),
        const SizedBox(height: 18),
        _mapHeader(),
        const SizedBox(height: 10),
        _mapView(),
        const SizedBox(height: 8),
        _coordinatesRow(),
        if (_gpsError != null) ...[const SizedBox(height: 8), _gpsMessage()],
        const SizedBox(height: 18),
        SettingsRow(
          children: [
            SettingsLabeled(
              label: 'GPS Geofence Radius (meters)',
              helper:
                  'Maximum allowed check-in distance from office '
                  'coordinates.',
              child: SettingsTextField(
                initialValue: '${_p.radiusMeters}',
                keyboardType: TextInputType.number,
                inputFormatters: SettingsTextField.digits,
                onChanged: (v) {
                  _p.radiusMeters = parseInt(v);
                  widget.onChanged();
                  setState(() {}); // redraws the geofence circle
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 22),
              child: SettingsCheckTile(
                label: 'Company Active & Operational',
                value: _p.isActive,
                onChanged: (v) {
                  _p.isActive = v;
                  widget.onChanged();
                },
              ),
            ),
          ],
        ),
        SettingsSaveBar(
          dirty: widget.dirty,
          saving: widget.saving,
          onSave: widget.onSave,
        ),
      ],
    );
  }

  Widget _mapHeader() {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          const Text(
            'Office Geofence Coordinates & Pin (Google Maps)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kSetTextDark,
            ),
          ),
          OutlinedButton.icon(
            onPressed: (_locating || widget.saving)
                ? null
                : _useCurrentLocation,
            icon: _locating
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded, size: 17),
            label: const Text('Use Current GPS Location'),
            style: OutlinedButton.styleFrom(
              foregroundColor: kSetPrimary,
              side: const BorderSide(color: kSetBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapView() {
    final pin = _p.hasPin ? LatLng(_p.latitude!, _p.longitude!) : null;

    return SizedBox(
      height: 280,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: kSetBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: pin ?? _defaultCenter,
              zoom: pin == null ? 4.2 : 16,
            ),
            onMapCreated: (controller) => _map = controller,
            onTap: (point) => _setPin(point.latitude, point.longitude),
            markers: {
              if (pin != null)
                Marker(
                  markerId: const MarkerId('office'),
                  position: pin,
                  draggable: true,
                  onDragEnd: (point) =>
                      _setPin(point.latitude, point.longitude),
                ),
            },
            circles: {
              if (pin != null && _p.radiusMeters > 0)
                Circle(
                  circleId: const CircleId('geofence'),
                  center: pin,
                  radius: _p.radiusMeters.toDouble(),
                  fillColor: kSetPrimary.withValues(alpha: 0.12),
                  strokeColor: kSetPrimary,
                  strokeWidth: 1,
                ),
            },
            // Lets the map receive drags inside the scrolling page.
            gestureRecognizers: {
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),
        ),
      ),
    );
  }

  Widget _coordinatesRow() {
    final text = _p.hasPin
        ? 'Latitude: ${_p.latitude!.toStringAsFixed(6)}    '
              'Longitude: ${_p.longitude!.toStringAsFixed(6)}'
        : 'No location selected. Tap the map to place the office pin.';

    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
          ),
        ),
        if (_p.hasPin)
          TextButton(onPressed: _clearPin, child: const Text('Clear pin')),
      ],
    );
  }

  Widget _gpsMessage() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.location_off_outlined, size: 17, color: kSetDanger),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _gpsError!,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF9B1C1C)),
          ),
        ),
        if (_gpsFailure?.needsSettings ?? false)
          TextButton(
            onPressed: () => BranchLocationService.openSettings(_gpsFailure!),
            child: const Text('Open settings'),
          ),
      ],
    );
  }
}

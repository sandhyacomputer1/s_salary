import 'package:flutter/material.dart';

import '../models/field_employee_location_model.dart';
import '../models/location_history_model.dart';
import 'field_tracking_format.dart';

const Color _kPrimary = Color(0xFFE96832);
const Color _kTextDark = Color(0xFF18212F);
const Color _kBorder = Color(0xFFE5E7EB);
const Color _kMuted = Color(0xFF7A8494);

/// Details card for the selected employee: identity, latest known location,
/// a date picker, and the route summary + point list for that date.
class EmployeeLocationDetails extends StatelessWidget {
  const EmployeeLocationDetails({
    super.key,
    required this.employee,
    required this.history,
    required this.historyLoading,
    required this.historyError,
    required this.date,
    required this.onPickDate,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onToday,
    required this.onRetryHistory,
  });

  final FieldEmployeeLocation employee;

  /// History for [date]; null until the first load finishes.
  final LocationHistory? history;
  final bool historyLoading;
  final String? historyError;

  final DateTime date;
  final VoidCallback onPickDate;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onToday;
  final VoidCallback onRetryHistory;

  bool get _isToday => FieldTrackingFormat.isSameDay(date, DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _identity(),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEDEFF3)),
          const SizedBox(height: 14),
          _latestLocation(),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEDEFF3)),
          const SizedBox(height: 14),
          _dateControls(),
          const SizedBox(height: 12),
          _routeSection(context),
        ],
      ),
    );
  }

  // ==========================================================
  // IDENTITY
  // ==========================================================

  Widget _identity() {
    final lines = [
      employee.employeeCode,
      employee.designation,
      employee.department,
    ].where((s) => s.trim().isNotEmpty).join('  •  ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEEE7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              employee.initials,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                employee.name.isEmpty ? 'Unnamed Employee' : employee.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kTextDark,
                ),
              ),
              if (lines.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  lines,
                  style: const TextStyle(fontSize: 12.5, color: _kMuted),
                ),
              ],
              if (employee.phone.trim().isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  employee.phone,
                  style: const TextStyle(fontSize: 12.5, color: _kMuted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // LATEST KNOWN LOCATION (from the field-locations endpoint)
  // ==========================================================

  Widget _latestLocation() {
    final point = employee.location;

    if (point == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Latest known location'),
          const SizedBox(height: 8),
          const Text(
            'No location has been recorded for this employee yet.',
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: _kMuted,
            ),
          ),
        ],
      );
    }

    final freshness = FieldTrackingFormat.freshness(point);
    final color = FieldTrackingFormat.freshnessColor(freshness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle('Latest known location')),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                FieldTrackingFormat.freshnessLabel(freshness),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _kv(
          'Coordinates',
          FieldTrackingFormat.coordinates(point.lat, point.lng),
        ),
        _kv('Address', FieldTrackingFormat.address(point.address)),
        _kv(
          'Recorded',
          point.timestamp == null
              ? FieldTrackingFormat.unavailable
              : '${FieldTrackingFormat.dateTime(point.timestamp)} '
                    '(${FieldTrackingFormat.relative(point.timestamp)})',
        ),
        _kv('Battery', FieldTrackingFormat.battery(point.batteryLevel)),
        if (freshness == LocationFreshness.stale)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'This position is old. The employee may have stopped '
              'reporting, so it is not their current location.',
              style: TextStyle(fontSize: 12, color: Color(0xFFC62828)),
            ),
          ),
      ],
    );
  }

  // ==========================================================
  // DATE CONTROLS
  // ==========================================================

  Widget _dateControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Route history'),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              tooltip: 'Previous day',
              onPressed: onPreviousDay,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 16),
                label: Text(FieldTrackingFormat.date(date)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kTextDark,
                  side: const BorderSide(color: Color(0xFFD9DEE7)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next day',
              onPressed: _isToday ? null : onNextDay,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        if (!_isToday)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onToday,
              child: const Text('Back to today'),
            ),
          ),
      ],
    );
  }

  // ==========================================================
  // ROUTE SECTION
  // ==========================================================

  Widget _routeSection(BuildContext context) {
    final h = history;

    if (historyError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            historyError!,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9B1C1C)),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRetryHistory,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    if (h == null) {
      return const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text(
            'Loading route…',
            style: TextStyle(fontSize: 13, color: _kMuted),
          ),
        ],
      );
    }

    if (h.isEmpty) {
      return Text(
        h.totalRecords == 0
            ? 'No location records for this date.'
            : 'All ${h.totalRecords} records had invalid coordinates and '
                  'were ignored.',
        style: const TextStyle(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: _kMuted,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kv('Records', '${h.points.length}'),
        _kv('First point', FieldTrackingFormat.timeOnly(h.first?.timestamp)),
        _kv('Last point', FieldTrackingFormat.timeOnly(h.latest?.timestamp)),
        if (!h.hasRoute)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Only one point was recorded, so there is no route line.',
              style: TextStyle(fontSize: 12, color: _kMuted),
            ),
          ),
        if (h.skippedCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${h.skippedCount} record(s) ignored: invalid coordinates.',
              style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)),
            ),
          ),
        const SizedBox(height: 6),
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: Text(
              'Route points (${h.points.length})',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _kTextDark,
              ),
            ),
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: h.points.length,
                  separatorBuilder: (_, _) => const Divider( height: 1, color: Color(0xFFEDEFF3)),
                  itemBuilder: (context, index) => _pointRow(h.points[index]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // SMALL BUILDERS
  // ==========================================================

  Widget _pointRow(LocationPoint p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              FieldTrackingFormat.timeOnly(p.timestamp),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _kTextDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              p.address ?? FieldTrackingFormat.coordinates(p.lat, p.lng),
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF4B5563)),
            ),
          ),
          if (FieldTrackingFormat.hasBattery(p.batteryLevel)) ...[
            const SizedBox(width: 8),
            Text(
              FieldTrackingFormat.battery(p.batteryLevel),
              style: const TextStyle(fontSize: 12, color: _kMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: _kTextDark,
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: _kMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kTextDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

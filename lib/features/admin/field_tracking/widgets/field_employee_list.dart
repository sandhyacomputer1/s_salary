import 'package:flutter/material.dart';

import '../models/field_employee_location_model.dart';
import 'field_tracking_format.dart';

const Color _kPrimary = Color(0xFFE96832);
const Color _kTextDark = Color(0xFF18212F);
const Color _kBorder = Color(0xFFE5E7EB);
const Color _kMuted = Color(0xFF7A8494);

/// Left panel of the Field Tracking screen: header, search and the list of
/// field employees.
class FieldEmployeeList extends StatefulWidget {
  const FieldEmployeeList({
    super.key,
    required this.employees,
    required this.selectedId,
    required this.onSelect,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.shrinkWrap = false,
  });

  final List<FieldEmployeeLocation> employees;
  final String? selectedId;
  final ValueChanged<FieldEmployeeLocation> onSelect;

  /// True only for the first load, while there is nothing to show yet.
  final bool isLoading;

  /// Shown only when there is no data to fall back on.
  final String? error;
  final VoidCallback? onRetry;

  /// true: sized to its content (phone layout, inside a scrolling page).
  /// false: fills the available height and scrolls internally.
  final bool shrinkWrap;

  @override
  State<FieldEmployeeList> createState() => _FieldEmployeeListState();
}

class _FieldEmployeeListState extends State<FieldEmployeeList> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Employees with a location first (newest first), then the rest by name.
  List<FieldEmployeeLocation> _visible() {
    final q = _query.trim().toLowerCase();

    final list = widget.employees.where((e) {
      if (q.isEmpty) return true;
      return e.name.toLowerCase().contains(q) ||
          e.employeeCode.toLowerCase().contains(q);
    }).toList();

    list.sort((a, b) {
      if (a.hasLocation != b.hasLocation) return a.hasLocation ? -1 : 1;

      final ta = a.location?.timestamp;
      final tb = b.location?.timestamp;

      if (ta != null && tb != null) return tb.compareTo(ta);
      if (ta != null) return -1;
      if (tb != null) return 1;

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final showSearch = widget.employees.isNotEmpty;

    final body = _body();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        mainAxisSize: widget.shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          if (showSearch) _searchField(),
          const Divider(height: 1, color: Color(0xFFEDEFF3)),
          if (widget.shrinkWrap) body else Expanded(child: body),
        ],
      ),
    );
  }

  Widget _header() {
    final count = widget.isLoading && widget.employees.isEmpty
        ? ''
        : ' (${widget.employees.length})';

    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Field Employees$count',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _kTextDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Click an employee to view location route',
            style: TextStyle(fontSize: 12, color: _kMuted),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: TextField(
        controller: _search,
        onChanged: (v) => setState(() => _query = v),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search by name or code',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD9DEE7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD9DEE7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _kPrimary),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (widget.isLoading && widget.employees.isEmpty) {
      return _skeleton();
    }

    if (widget.error != null && widget.employees.isEmpty) {
      return _message(
        icon: Icons.error_outline_rounded,
        iconColor: const Color(0xFFDC2626),
        title: widget.error!,
        action: widget.onRetry == null
            ? null
            : FilledButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
                style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              ),
      );
    }

    if (widget.employees.isEmpty) {
      return _message(
        title: 'No Field Employees Found',
        subtitle:
            'Assign "Field Employee" work mode while creating or '
            'editing an employee.',
      );
    }

    final visible = _visible();

    if (visible.isEmpty) {
      return _message(title: 'No employees match "${_query.trim()}"');
    }

    if (widget.shrinkWrap) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _tile(visible[i]),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _tile(visible[index]),
    );
  }

  Widget _tile(FieldEmployeeLocation employee) {
    return FieldEmployeeTile(
      employee: employee,
      selected: employee.id == widget.selectedId,
      onTap: () => widget.onSelect(employee),
    );
  }

  Widget _skeleton() {
    Widget block(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          for (var i = 0; i < 5; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        block(140, 12),
                        const SizedBox(height: 8),
                        block(100, 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _message({
    required String title,
    String? subtitle,
    IconData? icon,
    Color? iconColor,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 34, color: iconColor ?? _kMuted),
            const SizedBox(height: 12),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: Colors.grey.shade500,
              ),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 16), action],
        ],
      ),
    );
  }
}

// =================================================================
// TILE
// =================================================================

class FieldEmployeeTile extends StatelessWidget {
  const FieldEmployeeTile({
    super.key,
    required this.employee,
    required this.selected,
    required this.onTap,
  });

  final FieldEmployeeLocation employee;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final point = employee.location;
    final freshness = FieldTrackingFormat.freshness(point);
    final color = FieldTrackingFormat.freshnessColor(freshness);

    final subtitle = [
      employee.employeeCode,
      employee.designation.isNotEmpty
          ? employee.designation
          : employee.department,
    ].where((s) => s.trim().isNotEmpty).join('  •  ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF4EE) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _kPrimary : _kBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      employee.initials,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.name.isEmpty ? 'Unnamed Employee' : employee.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected ? _kPrimary : _kTextDark,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: _kMuted),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (point == null)
                    const Text(
                      'No location history',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: _kMuted,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _FreshnessChip(freshness: freshness),
                        Text(
                          FieldTrackingFormat.relative(point.timestamp),
                          style: const TextStyle(fontSize: 12, color: _kMuted),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (point != null &&
                FieldTrackingFormat.hasBattery(point.batteryLevel)) ...[
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.battery_std_rounded,
                    size: 15,
                    color: _kMuted,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    FieldTrackingFormat.battery(point.batteryLevel),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FreshnessChip extends StatelessWidget {
  const _FreshnessChip({required this.freshness});

  final LocationFreshness freshness;

  @override
  Widget build(BuildContext context) {
    final color = FieldTrackingFormat.freshnessColor(freshness);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            FieldTrackingFormat.freshnessLabel(freshness),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

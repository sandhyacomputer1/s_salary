import 'dart:async';

import 'package:flutter/material.dart';

import '../models/emp_dash_attendance_model.dart';
import '../models/emp_dash_shift_model.dart';

enum EmpDashAttendanceState { notCheckedIn, checkedIn, checkedOut }

class EmpDashAttendanceCard extends StatefulWidget {
  final EmpDashAttendanceState state;
  final EmpDashAttendanceRecord? todayRecord;
  final EmpDashShiftModel? shift;
  final bool isActionLoading;
  final VoidCallback? onCheckIn;
  final VoidCallback? onCheckOut;
  final String? locationStatus;
  final bool locationOk;

  const EmpDashAttendanceCard({
    super.key,
    required this.state,
    required this.todayRecord,
    required this.shift,
    this.isActionLoading = false,
    this.onCheckIn,
    this.onCheckOut,
    this.locationStatus,
    this.locationOk = true,
  });

  static const Color primary = Color(0xFFE96832);
  static const Color primaryLight = Color(0xFFFFEEE7);
  static const Color checkOutRed = Color(0xFFDC4A26);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFE5E7EB);
  static const Color success = Color(0xFF159957);
  static const Color successLight = Color(0xFFE7F7EF);
  static const Color warning = Color(0xFFD99000);
  static const Color warningLight = Color(0xFFFFF4D6);
  static const Color indigo = Color(0xFF4F46E5);

  @override
  State<EmpDashAttendanceCard> createState() => _EmpDashAttendanceCardState();
}

class _EmpDashAttendanceCardState extends State<EmpDashAttendanceCard> {
  static const Color primary = EmpDashAttendanceCard.primary;
  static const Color textDark = EmpDashAttendanceCard.textDark;
  static const Color textMedium = EmpDashAttendanceCard.textMedium;
  static const Color textLight = EmpDashAttendanceCard.textLight;
  static const Color border = EmpDashAttendanceCard.border;
  static const Color success = EmpDashAttendanceCard.success;
  static const Color successLight = EmpDashAttendanceCard.successLight;
  static const Color warning = EmpDashAttendanceCard.warning;
  static const Color warningLight = EmpDashAttendanceCard.warningLight;

  Timer? _timer;
  DateTime _now = DateTime.now();

  bool get _active => widget.state == EmpDashAttendanceState.checkedIn;

  @override
  void initState() {
    super.initState();

    // Ticks every second, but only redraws while the employee is checked
    // in (that is when "Hours Worked" is counting live).
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _active) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ==========================================================
  // FORMATTING
  // ==========================================================

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  String _dateLabel(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';

  /// "2026-10-21T09:47:57.656Z" -> "03:17 pm" (local time).
  /// Values that are not a full date-time (for example "09:30") are shown
  /// as they are.
  String _time(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';

    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return raw;

    final d = parsed.toLocal();
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'pm' : 'am';

    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  String _plural(int n, String unit) => '$n $unit${n == 1 ? '' : 's'}';

  /// Live counter: "23 mins 46 secs" / "1 hr 5 mins 12 secs".
  String _liveDuration(Duration d) {
    if (d.isNegative) d = Duration.zero;

    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;

    final parts = <String>[];
    if (h > 0) parts.add(_plural(h, 'hr'));
    if (h > 0 || m > 0) parts.add(_plural(m, 'min'));
    parts.add(_plural(s, 'sec'));

    return parts.join(' ');
  }

  /// Finished day: 7.5 -> "7 hrs 30 mins".
  String _hoursLabel(double hours) {
    final totalMinutes = (hours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;

    if (h == 0) return _plural(m, 'min');
    if (m == 0) return _plural(h, 'hr');
    return '${_plural(h, 'hr')} ${_plural(m, 'min')}';
  }

  // ==========================================================
  // DERIVED TEXT
  // ==========================================================

  String get _title {
    final record = widget.todayRecord;

    switch (widget.state) {
      case EmpDashAttendanceState.notCheckedIn:
        return 'Ready for Check-In';
      case EmpDashAttendanceState.checkedIn:
        return 'Working Shift · Checked In at ${_time(record?.checkInTime)}';
      case EmpDashAttendanceState.checkedOut:
        return 'Day Completed · Checked Out at ${_time(record?.checkOutTime)}';
    }
  }

  /// Hours Worked tile: (text, color)
  (String, Color) _hoursValue(EmpDashAttendanceRecord? record) {
    if (record == null) return ('—', textDark);

    if (_active) {
      final start = DateTime.tryParse(record.checkInTime ?? '');

      if (start != null) {
        final elapsed = _now.difference(start.toLocal());
        return ('${_liveDuration(elapsed)} (Active)', EmpDashAttendanceCard.indigo);
      }
    }

    if (record.totalHours > 0) {
      return (_hoursLabel(record.totalHours), textDark);
    }

    return ('—', textDark);
  }

  /// Shift / Day Status tile: (text, color)
  (String, Color) _dayStatus(EmpDashAttendanceRecord? record, bool checkedIn) {
    if (record == null) return ('—', textDark);

    // A real check-in always counts as present, even if the day was
    // also flagged (for example as leave).
    if (checkedIn) {
      if (record.isHalfDay) return ('Half Day', EmpDashAttendanceCard.indigo);
      if (record.isLate) return ('Present (Late)', warning);
      return ('Present (On Time)', success);
    }

    if (record.isOnLeave) return ('On Leave', EmpDashAttendanceCard.indigo);
    if (record.isAbsent) return ('Absent', const Color(0xFFD64545));
    if (record.isHalfDay) return ('Half Day', EmpDashAttendanceCard.indigo);
    if (record.isPresent) return ('Present', success);

    return ('—', textDark);
  }

  /// Note shown ONLY when there is no real check-in (admin-marked days).
  String? _statusNote(EmpDashAttendanceRecord? record) {
    if (record == null) return null;

    if (record.isOnLeave) return 'Marked as On Leave';
    if (record.isAbsent) return 'Marked as Absent';
    if (record.isHalfDay) return 'Marked as Half Day';

    if (record.isPresent && record.punches.isEmpty) {
      return 'Marked Present (no check-in recorded)';
    }

    return null;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final record = widget.todayRecord;
    final hasCheckedIn = record?.checkInTime != null;
    final hasCheckedOut = record?.checkOutTime != null;
    final note = hasCheckedIn ? null : _statusNote(record);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 620;

          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 6,
                children: [
                  _buildStatusChip(record),
                  Text(
                    _dateLabel(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _title,
                style: TextStyle(
                  fontSize: narrow ? 18 : 22,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                  height: 1.2,
                ),
              ),
              if (widget.locationStatus != null) ...[
                const SizedBox(height: 8),
                _buildLocationLine(),
              ],
            ],
          );

          final buttons = _buildButtons(hasCheckedIn, hasCheckedOut, narrow);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (narrow) ...[
                titleBlock,
                const SizedBox(height: 16),
                buttons,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: titleBlock),
                    const SizedBox(width: 16),
                    buttons,
                  ],
                ),

              if (note != null) ...[
                const SizedBox(height: 14),
                _buildNote(note),
              ],

              const SizedBox(height: 18),
              _buildMetrics(record, hasCheckedIn, narrow),

              if (widget.shift != null) ...[
                const SizedBox(height: 14),
                _buildShiftBar(record),
              ],

              if (hasCheckedOut) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: successLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Attendance completed for today',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: success,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // ==========================================================
  // STATUS CHIP
  // ==========================================================

  Widget _buildStatusChip(EmpDashAttendanceRecord? record) {
    late final String label;
    late final Color fg;
    late final Color bg;
    var dot = false;

    switch (widget.state) {
      case EmpDashAttendanceState.notCheckedIn:
        label = 'NOT CHECKED IN YET';
        fg = textLight;
        bg = const Color(0xFFF1F2F4);
        break;
      case EmpDashAttendanceState.checkedIn:
        final late = record?.isLate == true;
        label = late ? 'LIVE · WORKING (LATE)' : 'LIVE · WORKING (ON TIME)';
        fg = late ? warning : success;
        bg = late ? warningLight : successLight;
        dot = true;
        break;
      case EmpDashAttendanceState.checkedOut:
        label = 'CHECKED OUT';
        fg = success;
        bg = successLight;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: fg,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationLine() {
    final ok = widget.locationOk;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          ok ? Icons.location_on_rounded : Icons.location_off_rounded,
          size: 15,
          color: ok ? success : primary,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Location Validation:  ',
                  style: TextStyle(color: textLight),
                ),
                TextSpan(
                  text: widget.locationStatus!,
                  style: TextStyle(
                    color: ok ? textDark : primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildNote(String note) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 14, color: textLight),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              note,
              style: const TextStyle(
                fontSize: 12,
                color: textMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BUTTONS (Check In + Check Out always visible)
  // ==========================================================

  Widget _buildButtons(bool hasCheckedIn, bool hasCheckedOut, bool narrow) {
    final canCheckIn = !hasCheckedIn && !widget.isActionLoading;
    final canCheckOut = hasCheckedIn && !hasCheckedOut && !widget.isActionLoading;

    Widget spinner() => const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );

    final checkIn = ElevatedButton.icon(
      onPressed: canCheckIn ? widget.onCheckIn : null,
      icon: (widget.isActionLoading && !hasCheckedIn)
          ? spinner()
          : const Icon(Icons.login_rounded, size: 18),
      label: const Text('Check In'),
      style: _buttonStyle(EmpDashAttendanceCard.primary),
    );

    final checkOut = ElevatedButton.icon(
      onPressed: canCheckOut ? widget.onCheckOut : null,
      icon: (widget.isActionLoading && hasCheckedIn)
          ? spinner()
          : const Icon(Icons.logout_rounded, size: 18),
      label: const Text('Check Out'),
      style: _buttonStyle(EmpDashAttendanceCard.checkOutRed),
    );

    if (narrow) {
      return Row(
        children: [
          Expanded(child: SizedBox(height: 46, child: checkIn)),
          const SizedBox(width: 10),
          Expanded(child: SizedBox(height: 46, child: checkOut)),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 44, child: checkIn),
        const SizedBox(width: 10),
        SizedBox(height: 44, child: checkOut),
      ],
    );
  }

  ButtonStyle _buttonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      disabledBackgroundColor: const Color(0xFFE5E7EB),
      disabledForegroundColor: const Color(0xFF9CA3AF),
      elevation: 0,
      // Override any app-wide ElevatedButton theme that may set
      // minimumSize.width to double.infinity. This prevents
      // "BoxConstraints forces an infinite width" in the desktop/web Row.
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  // ==========================================================
  // METRICS BOX
  // ==========================================================

  Widget _buildMetrics(
      EmpDashAttendanceRecord? record,
      bool checkedIn,
      bool narrow,
      ) {
    final hours = _hoursValue(record);
    final status = _dayStatus(record, checkedIn);

    final tiles = <Widget>[
      _InfoTile(
        label: 'FIRST CHECK-IN',
        value: _time(record?.checkInTime),
      ),
      _InfoTile(
        label: 'LAST CHECK-OUT',
        value: _time(record?.checkOutTime),
      ),
      _InfoTile(
        label: 'HOURS WORKED',
        value: hours.$1,
        valueColor: hours.$2,
      ),
      _InfoTile(
        label: 'SHIFT / DAY STATUS',
        value: status.$1,
        valueColor: status.$2,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEFF3)),
      ),
      child: narrow
          ? Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: tiles[0]),
              Expanded(child: tiles[1]),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: tiles[2]),
              Expanded(child: tiles[3]),
            ],
          ),
        ],
      )
          : Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final tile in tiles) Expanded(child: tile),
        ],
      ),
    );
  }

  // ==========================================================
  // SHIFT BAR
  // ==========================================================

  Widget _buildShiftBar(EmpDashAttendanceRecord? record) {
    final shift = widget.shift!;
    final name = shift.shiftName.trim().isEmpty ? 'Shift' : shift.shiftName;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, size: 17, color: textMedium),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$name · ${shift.startTime} - ${shift.endTime}',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: textDark,
              ),
            ),
          ),
          if (record?.isLate == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE8E8),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'LATE',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD64545),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            color: EmpDashAttendanceCard.textLight,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: valueColor ?? EmpDashAttendanceCard.textDark,
          ),
        ),
      ],
    );
  }
}

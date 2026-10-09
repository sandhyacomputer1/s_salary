import 'package:flutter/material.dart';

import '../models/emp_dash_attendance_model.dart';
import '../models/emp_dash_shift_model.dart';

enum EmpDashAttendanceState { notCheckedIn, checkedIn, checkedOut }

class EmpDashAttendanceCard extends StatelessWidget {
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
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFE1E5EA);
  static const Color success = Color(0xFF159957);
  static const Color successLight = Color(0xFFE7F7EF);

  String get _title {
    switch (state) {
      case EmpDashAttendanceState.notCheckedIn:
        return 'Ready for Check-In';
      case EmpDashAttendanceState.checkedIn:
        return 'You\'re Checked In';
      case EmpDashAttendanceState.checkedOut:
        return 'Day Completed';
    }
  }

  String get _statusLabel {
    switch (state) {
      case EmpDashAttendanceState.notCheckedIn:
        return 'NOT CHECKED IN YET';
      case EmpDashAttendanceState.checkedIn:
        return 'CHECKED IN';
      case EmpDashAttendanceState.checkedOut:
        return 'CHECKED OUT';
    }
  }

  Color get _statusColor {
    switch (state) {
      case EmpDashAttendanceState.notCheckedIn:
        return textLight;
      case EmpDashAttendanceState.checkedIn:
        return primary;
      case EmpDashAttendanceState.checkedOut:
        return success;
    }
  }

  Color get _statusBg {
    switch (state) {
      case EmpDashAttendanceState.notCheckedIn:
        return const Color(0xFFF1F2F4);
      case EmpDashAttendanceState.checkedIn:
        return primaryLight;
      case EmpDashAttendanceState.checkedOut:
        return successLight;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Badge shown for the day's status when there's no live check-in
  /// in progress — e.g. "present" (admin-marked, no punches),
  /// "on_leave", "absent", etc. Only shown when relevant.
  String? _statusNote(EmpDashAttendanceRecord? record) {
    if (record == null) return null;

    if (record.isOnLeave) return 'Marked as On Leave';
    if (record.isAbsent) return 'Marked as Absent';
    if (record.isHalfDay) return 'Marked as Half Day';

    // "present" but with no real punches means it was admin-marked,
    // not from an actual check-in/check-out.
    if (record.isPresent && record.punches.isEmpty) {
      return 'Marked Present (no check-in recorded)';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final record = todayRecord;
    final hasCheckedIn = record?.checkInTime != null;
    final hasCheckedOut = record?.checkOutTime != null;
    final note = _statusNote(record);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: _statusColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),

          if (note != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: textLight,
                  ),
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
            ),
          ],

          if (locationStatus != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  locationOk
                      ? Icons.location_on_rounded
                      : Icons.location_off_rounded,
                  size: 15,
                  color: locationOk ? success : primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    locationStatus!,
                    style: TextStyle(
                      fontSize: 12,
                      color: locationOk ? textMedium : primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 18),
          const Divider(height: 1, color: border),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'First Check-In',
                  value: record?.checkInTime ?? '—',
                ),
              ),
              Expanded(
                child: _InfoTile(
                  label: 'Last Check-Out',
                  value: record?.checkOutTime ?? '—',
                ),
              ),
              Expanded(
                child: _InfoTile(
                  label: 'Hours Worked',
                  value: record != null && record.totalHours > 0
                      ? '${record.totalHours.toStringAsFixed(1)}h'
                      : '—',
                ),
              ),
            ],
          ),

          if (shift != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 17,
                    color: textMedium,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${shift!.shiftName} · ${shift!.startTime} - ${shift!.endTime}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                  ),
                  if (record?.isLate == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
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
            ),
          ],

          const SizedBox(height: 20),

          Row(
            children: [
              if (!hasCheckedIn)
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: isActionLoading ? null : onCheckIn,
                      icon: isActionLoading
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.login_rounded, size: 18),
                      label: const Text(
                        'Check In',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                )
              else if (hasCheckedIn && !hasCheckedOut)
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: isActionLoading ? null : onCheckOut,
                      icon: isActionLoading
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.logout_rounded, size: 18),
                      label: const Text(
                        'Check Out',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: textDark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Container(
                    height: 48,
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
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: EmpDashAttendanceCard.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: EmpDashAttendanceCard.textDark,
          ),
        ),
      ],
    );
  }
}
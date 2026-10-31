import 'package:flutter/material.dart';

import '../../../../core/storage/secure_storage.dart'; // TODO: fix path if different
import '../models/admin_employee_model.dart';
import '../models/admin_employee_profile_models.dart';
import '../services/admin_employee_profile_service.dart';
import 'admin_attendance_calendar.dart';
import 'admin_employee_theme.dart';
import 'admin_mark_attendance_dialog.dart';
import 'admin_profile_common.dart';
import 'admin_profile_metrics_card.dart';

typedef _AttData = (
AdminAttendanceSummary,
List<AdminAttendanceLog>,
List<AdminCalendarDay>,
);

/// Attendance & Logs tab (matches the web):
/// metrics card, Monthly Attendance Planner (calendar) and the daily log.
class AdminProfileAttendanceTab extends StatefulWidget {
  final AdminEmployeeModel employee;
  final AdminEmployeeProfileService service;

  const AdminProfileAttendanceTab({super.key, required this.employee, required this.service});

  @override
  State<AdminProfileAttendanceTab> createState() => _AdminProfileAttendanceTabState();
}

class _AdminProfileAttendanceTabState extends State<AdminProfileAttendanceTab> {
  late int _month;
  late int _year;

  _AttData? _data;
  bool _loading = true;
  String? _error;
  int _request = 0; // ignores answers of an older month

  final Set<String> _selected = {};
  String? _companyId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    _fetch();
  }

  // ------------------------------------------------------------
  // data
  // ------------------------------------------------------------

  Future<String> _readCompanyId() async {
    if (_companyId != null) return _companyId!;
    try {
      _companyId = (await SecureStorage.getCompanyId()) ?? '';
    } catch (_) {
      _companyId = '';
    }
    return _companyId!;
  }

  Future<void> _fetch() async {
    final req = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      _data = null;
      _selected.clear();
    });

    try {
      final cid = await _readCompanyId();
      final id = widget.employee.id;

      final results = await Future.wait([
        widget.service.getAttendanceSummary(id, _month, _year),
        widget.service.getAttendanceLogs(id, _month, _year),
        cid.isEmpty
            ? Future.value(<AdminCalendarDay>[])
            : widget.service.getCalendarDays(cid, _year),
      ]);

      if (!mounted || req != _request) return;
      setState(() {
        _data = (
        results[0] as AdminAttendanceSummary,
        results[1] as List<AdminAttendanceLog>,
        results[2] as List<AdminCalendarDay>,
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted || req != _request) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _setMonth(int month, int year) {
    if (month == _month && year == _year) return;
    _month = month;
    _year = year;
    _fetch();
  }

  void _shift(int delta) {
    var m = _month + delta;
    var y = _year;
    if (m < 1) {
      m = 12;
      y--;
    } else if (m > 12) {
      m = 1;
      y++;
    }
    _setMonth(m, y);
  }

  // ------------------------------------------------------------
  // actions
  // ------------------------------------------------------------

  Future<void> _mark(List<String> keys) async {
    if (keys.isEmpty) return;
    keys.sort();
    final saved = await AdminMarkAttendanceDialog.show(
      context,
      service: widget.service,
      employee: widget.employee,
      dateKeys: keys,
    );
    if (saved == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance updated'), behavior: SnackBarBehavior.floating),
      );
      _fetch();
    }
  }

  void _toggle(String key) {
    setState(() {
      if (!_selected.remove(key)) _selected.add(key);
    });
  }

  void _toggleWorkingDays(List<AdminAttendanceDay> days) {
    setState(() {
      if (_selected.isNotEmpty) {
        _selected.clear();
      } else {
        _selected.addAll(days.where((d) => d.isWorkingDay).map((d) => d.key));
      }
    });
  }

  // ------------------------------------------------------------
  // build
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final data = _data;

    return Column(
      children: [
        if (data != null) ...[
          AdminProfileMetricsCard(summary: data.$1),
          const SizedBox(height: 28),
        ],
        _planner(),
        if (data != null) ...[
          const SizedBox(height: 28),
          _logCard(data.$2),
        ],
      ],
    );
  }

  // ------------------------------------------------------------
  // planner (calendar)
  // ------------------------------------------------------------

  Widget _planner() {
    final data = _data;
    final days = data == null
        ? const <AdminAttendanceDay>[]
        : AdminAttendanceCalendarData.build(
      month: _month,
      year: _year,
      logs: data.$2,
      calendar: data.$3,
    );

    final todayKey = AdminAttendanceCalendarData.keyOf(DateTime.now());

    return AdminProfileCard(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 14,
            spacing: 14,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Monthly Attendance Planner',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AdminEmpColors.text,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Click on any date below to manually mark Present, Late, Absent, or On Leave for this employee.',
                    style: TextStyle(fontSize: 13.5, color: AdminEmpColors.muted),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: () => _mark([todayKey]),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  foregroundColor: AdminEmpColors.text,
                  side: const BorderSide(color: AdminEmpColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Mark Attendance Today', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminEmpColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _controls(days),
                const SizedBox(height: 18),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator(color: AdminEmpColors.primary)),
                  )
                else if (_error != null)
                  _errorBox()
                else ...[
                    _chips(days),
                    if (_selected.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _selectionBar(),
                    ],
                    const SizedBox(height: 22),
                    AdminAttendanceCalendar(
                      days: days,
                      selected: _selected,
                      onToggle: _toggle,
                      onTapDay: (d) => _mark([d.key]),
                    ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls(List<AdminAttendanceDay> days) {
    final now = DateTime.now();

    Widget navBtn(IconData icon, VoidCallback onTap) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AdminEmpColors.border),
        ),
        child: Icon(icon, size: 20, color: AdminEmpColors.text),
      ),
    );

    final picker = Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminEmpColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _month,
              isDense: true,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AdminEmpColors.text),
              items: [
                for (var m = 1; m <= 12; m++)
                  DropdownMenuItem(value: m, child: Text(adminProfMonthName(m))),
              ],
              onChanged: (m) {
                if (m != null) _setMonth(m, _year);
              },
            ),
          ),
          const SizedBox(width: 14),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _year,
              isDense: true,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AdminEmpColors.primary),
              items: [
                for (var y = now.year - 3; y <= now.year + 1; y++)
                  DropdownMenuItem(value: y, child: Text('$y')),
              ],
              onChanged: (y) {
                if (y != null) _setMonth(_month, y);
              },
            ),
          ),
        ],
      ),
    );

    final selectBtn = ElevatedButton(
      onPressed: (_loading || _data == null) ? null : () => _toggleWorkingDays(days),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(0, 42),
        elevation: 0,
        backgroundColor: const Color(0xFFEEF2F7),
        foregroundColor: AdminEmpColors.text,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFD9DEE7)),
        ),
      ),
      child: Text(
        _selected.isEmpty ? 'Select Working Days' : 'Clear Selection',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 14,
      runSpacing: 12,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            navBtn(Icons.chevron_left_rounded, () => _shift(-1)),
            const SizedBox(width: 12),
            picker,
            const SizedBox(width: 12),
            navBtn(Icons.chevron_right_rounded, () => _shift(1)),
          ],
        ),
        selectBtn,
      ],
    );
  }

  Widget _chips(List<AdminAttendanceDay> days) {
    final inMonth = days.where((d) => d.inMonth).toList();
    int count(bool Function(AdminAttendanceDay) t) => inMonth.where(t).length;

    final items = <(String, int, Color)>[
      ('Present', count((d) => d.kind == 'present' || d.kind == 'late' || d.kind == 'half_day'), const Color(0xFF22C55E)),
      ('Late', count((d) => d.kind == 'late'), const Color(0xFFF59E0B)),
      ('Absent', count((d) => d.kind == 'absent'), const Color(0xFFEF4444)),
      ('Leaves', count((d) => d.kind == 'on_leave'), const Color(0xFF8B5CF6)),
      ('Holidays', count((d) => d.kind == 'holiday'), const Color(0xFF3B82F6)),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 900 ? 5 : (c.maxWidth >= 560 ? 3 : 2);
        const gap = 14.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final it in items)
              Container(
                width: w,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEDEFF3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(color: it.$3, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        it.$1,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AdminEmpColors.muted),
                      ),
                    ),
                    Text(
                      '${it.$2}',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AdminEmpColors.text),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _selectionBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AdminEmpColors.primarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          Text(
            '${_selected.length} date(s) selected',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AdminEmpColors.primary),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => setState(_selected.clear),
                child: const Text('Clear'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _mark(_selected.toList()),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  backgroundColor: AdminEmpColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Mark Selected', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _errorBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AdminEmpColors.danger, size: 34),
            const SizedBox(height: 10),
            Text(_error ?? '', textAlign: TextAlign.center, style: const TextStyle(color: AdminEmpColors.muted)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _fetch,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // daily check-in / check-out log
  // ------------------------------------------------------------

  Widget _logCard(List<AdminAttendanceLog> source) {
    final logs = [...source]..sort((a, b) => a.dateKey.compareTo(b.dateKey));

    String lowerTime(DateTime? d) => d == null ? '—' : adminProfTime(d).toLowerCase();
    String statusOf(AdminAttendanceLog l) =>
        l.isLate && l.status.toLowerCase() == 'present' ? 'late' : l.status;

    return AdminProfileCard(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: AdminProfileSectionTitle('Daily Check-In & Check-Out Log'),
          ),
          const SizedBox(height: 22),
          if (logs.isEmpty)
            const AdminProfileEmpty('No attendance records for this month.')
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AdminSimpleTable(
                headers: const ['DATE', 'CHECK-IN', 'CHECK-OUT', 'WORK HOURS', 'STATUS'],
                flex: const [3, 3, 3, 3, 2],
                rows: [
                  for (final l in logs)
                    [
                      Text(l.dateKey, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      Text(lowerTime(l.checkIn)),
                      Text(lowerTime(l.checkOut)),
                      Text(l.totalHours == null ? '—' : '${adminProfHours(l.totalHours!)} hrs'),
                      _LogStatusPill(statusOf(l)),
                    ],
                ],
                compactBuilder: (i) {
                  final l = logs[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AdminEmpColors.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.dateKey, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(
                                '${lowerTime(l.checkIn)}  →  ${lowerTime(l.checkOut)}'
                                    '${l.totalHours == null ? '' : '  •  ${adminProfHours(l.totalHours!)} hrs'}',
                                style: const TextStyle(fontSize: 12.5, color: AdminEmpColors.muted),
                              ),
                            ],
                          ),
                        ),
                        _LogStatusPill(statusOf(l)),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// Lower-case status with a dot: "● present", "○ late" (as on the web).
class _LogStatusPill extends StatelessWidget {
  final String status;
  const _LogStatusPill(this.status);

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    final isPresent = s == 'present';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPresent ? AdminEmpColors.primarySoft : const Color(0xFFF1F2F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isPresent ? AdminEmpColors.primary : Colors.transparent,
              shape: BoxShape.circle,
              border: isPresent ? null : Border.all(color: AdminEmpColors.muted, width: 1.3),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            s.replaceAll('_', ' '),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isPresent ? AdminEmpColors.primary : AdminEmpColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
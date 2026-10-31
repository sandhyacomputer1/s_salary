import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../../employees/models/admin_employee_model.dart';
import '../../employees/widgets/admin_employee_theme.dart';
import '../../employees/widgets/admin_profile_common.dart';
import '../models/admin_overview_models.dart';
import '../services/admin_overview_service.dart';

/// "Daily Check-In & Check-Out": every active employee with check-in time,
/// check-out time, total hours and status for the chosen day.
/// Changing the day reloads the list.
class AdminDailyAttendanceCard extends StatefulWidget {
  final List<AdminEmployeeModel> employees;
  final String companyId;
  final AdminOverviewService service;

  const AdminDailyAttendanceCard({
    super.key,
    required this.employees,
    required this.companyId,
    required this.service,
  });

  @override
  State<AdminDailyAttendanceCard> createState() => _AdminDailyAttendanceCardState();
}

class _AdminDailyAttendanceCardState extends State<AdminDailyAttendanceCard> {
  static const int _collapsedRows = 8;

  late DateTime _date; // local calendar day
  List<AdminDailyAttendance> _records = [];
  bool _loading = true;
  String? _error;
  bool _showAll = false;
  int _request = 0; // ignores answers of a previous day

  // ---- live counter ----
  // _now ticks every second (only while today is shown); only the "Working"
  // cells listen to it, so the rest of the card is not rebuilt.
  final ValueNotifier<DateTime> _now = ValueNotifier<DateTime>(DateTime.now());
  Timer? _ticker; // 1 second: moves the running time
  Timer? _poll; // 15 seconds: silent refresh -> notices the check-out

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
    _load();
    _syncTimers();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _poll?.cancel();
    _now.dispose();
    super.dispose();
  }

  /// Timers run only while TODAY is shown (past days are final numbers).
  void _syncTimers() {
    _ticker?.cancel();
    _poll?.cancel();
    _ticker = null;
    _poll = null;

    if (!_isToday) return;

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _now.value = DateTime.now();
    });

    // When someone checks out, the record gets a check-out time. This quiet
    // refresh sees it and the counter of that person stops by itself.
    _poll = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted && !_loading) _load(silent: true);
    });
  }

  // ------------------------------------------------------------
  // helpers
  // ------------------------------------------------------------

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool get _isToday => _date == _today();

  String get _dateKey {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${_date.year}-${two(_date.month)}-${two(_date.day)}';
  }

  String get _dateLabel {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[_date.weekday - 1]}, ${_date.day} ${months[_date.month - 1]} ${_date.year}';
  }

  // ------------------------------------------------------------
  // data
  // ------------------------------------------------------------

  Future<void> _load({bool silent = false}) async {
    final req = ++_request;
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    if (widget.companyId.isEmpty) {
      if (silent) return;
      setState(() {
        _loading = false;
        _error = 'Company id not found. Please login again.';
      });
      return;
    }

    try {
      final list = await widget.service.getDailyAttendance(widget.companyId, _dateKey);
      if (!mounted || req != _request) return;
      setState(() {
        _records = list;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || req != _request) return;
      if (silent) return; // keep showing the last data
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _setDate(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    if (day == _date) return;
    setState(() {
      _date = day;
      _showAll = false;
    });
    _load();
    _syncTimers();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 3),
      lastDate: _today(),
    );
    if (picked != null) _setDate(picked);
  }

  // ------------------------------------------------------------
  // rows
  // ------------------------------------------------------------

  /// One row per active employee (matched with the day's record).
  List<_Row> _rows() {
    final byId = <String, AdminDailyAttendance>{};
    for (final r in _records) {
      if (r.employeeId.isNotEmpty) byId[r.employeeId] = r;
    }

    final rows = widget.employees
        .map((e) => _Row(e, byId[e.id] ?? byId[e.userId]))
        .toList();

    // checked-in people first (earliest first), the rest by employee code
    rows.sort((a, b) {
      final ai = a.record?.checkIn;
      final bi = b.record?.checkIn;
      if (ai != null && bi != null) return ai.compareTo(bi);
      if (ai != null) return -1;
      if (bi != null) return 1;
      return a.employee.employeeCode.compareTo(b.employee.employeeCode);
    });
    return rows;
  }

  String _statusKey(AdminDailyAttendance? r) {
    if (r == null) return _isToday ? 'not_checked_in' : 'no_record';
    final s = r.status.toLowerCase();
    if (s.isEmpty || s == 'present') return r.isLate ? 'late' : 'present';
    return s;
  }

  /// 8h 15m
  String _hoursText(double h) {
    var hours = h.floor();
    var minutes = ((h - hours) * 60).round();
    if (minutes == 60) {
      hours += 1;
      minutes = 0;
    }
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  // ------------------------------------------------------------
  // build
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEFF3)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 6),
            child: _header(),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 56),
              child: Center(child: CircularProgressIndicator(color: AdminEmpColors.primary)),
            )
          else if (_error != null)
            _errorBox()
          else
            _content(),
        ],
      ),
    );
  }

  Widget _header() {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Daily Check-In & Check-Out',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AdminEmpColors.text),
        ),
        const SizedBox(height: 4),
        Text(
          _isToday ? 'Today · $_dateLabel' : _dateLabel,
          style: const TextStyle(fontSize: 13.5, color: AdminEmpColors.muted),
        ),
      ],
    );

    Widget navBtn(IconData icon, VoidCallback? onTap) => InkWell(
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
        child: Icon(
          icon,
          size: 20,
          color: onTap == null ? const Color(0xFFC9CED6) : AdminEmpColors.text,
        ),
      ),
    );

    final dateButton = InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(8),
      child: Container(
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
            const Icon(Icons.calendar_today_outlined, size: 16, color: AdminEmpColors.primary),
            const SizedBox(width: 8),
            Text(
              adminEmpFormatDate(DateTime.utc(_date.year, _date.month, _date.day)),
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AdminEmpColors.text),
            ),
          ],
        ),
      ),
    );

    final controls = Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        navBtn(Icons.chevron_left_rounded, () => _setDate(_date.subtract(const Duration(days: 1)))),
        dateButton,
        navBtn(
          Icons.chevron_right_rounded,
          _isToday ? null : () => _setDate(_date.add(const Duration(days: 1))),
        ),
        if (!_isToday)
          OutlinedButton(
            onPressed: () => _setDate(_today()),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 42),
              foregroundColor: AdminEmpColors.primary,
              side: const BorderSide(color: AdminEmpColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Today', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 700) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 14), controls],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [title, controls],
        );
      },
    );
  }

  Widget _errorBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AdminEmpColors.danger, size: 34),
            const SizedBox(height: 10),
            Text(_error ?? '', textAlign: TextAlign.center, style: const TextStyle(color: AdminEmpColors.muted)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _load,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    final rows = _rows();

    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text('No active employees.', style: TextStyle(color: AdminEmpColors.muted, fontSize: 15)),
        ),
      );
    }

    final visible = (_showAll || rows.length <= _collapsedRows) ? rows : rows.take(_collapsedRows).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 16),
          child: _summary(rows),
        ),
        LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= 760;
            return Padding(
              padding: EdgeInsets.fromLTRB(wide ? 24 : 14, 0, wide ? 24 : 14, 6),
              child: wide
                  ? ClipRRect(borderRadius: BorderRadius.circular(8), child: _table(visible))
                  : Column(children: [for (final r in visible) _compactCard(r)]),
            );
          },
        ),
        if (rows.length > _collapsedRows)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 18),
            child: Center(
              child: TextButton(
                onPressed: () => setState(() => _showAll = !_showAll),
                child: Text(
                  _showAll ? 'Show less' : 'Show all (${rows.length})',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AdminEmpColors.primary),
                ),
              ),
            ),
          )
        else
          const SizedBox(height: 16),
      ],
    );
  }

  // ------------------------------------------------------------
  // summary chips
  // ------------------------------------------------------------

  Widget _summary(List<_Row> rows) {
    int count(bool Function(String) t) => rows.where((r) => t(_statusKey(r.record))).length;

    Widget chip(String label, int value, Color dot) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDEFF3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: AdminEmpColors.muted)),
          const SizedBox(width: 10),
          Text('$value', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AdminEmpColors.text)),
        ],
      ),
    );

    final working = rows.where((r) => _isWorking(r.record)).length;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (_isToday) chip('Working now', working, AdminEmpColors.primary),
        chip('Present', count((s) => s == 'present' || s == 'late' || s == 'half_day'), const Color(0xFF22C55E)),
        chip('Late', count((s) => s == 'late'), const Color(0xFFF59E0B)),
        chip('Absent', count((s) => s == 'absent'), const Color(0xFFEF4444)),
        chip('On Leave', count((s) => s == 'on_leave' || s == 'leave'), const Color(0xFF8B5CF6)),
        chip(_isToday ? 'Not checked in' : 'No record', count((s) => s == 'not_checked_in' || s == 'no_record'), const Color(0xFF9CA3AF)),
      ],
    );
  }

  // ------------------------------------------------------------
  // table (web / tablet)
  // ------------------------------------------------------------

  Widget _table(List<_Row> rows) {
    const h = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: AdminEmpColors.muted,
    );

    return Column(
      children: [
        Container(
          color: AdminEmpColors.headerBg,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: const Row(
            children: [
              Expanded(flex: 30, child: Text('EMPLOYEE', style: h)),
              Expanded(flex: 16, child: Text('DEPARTMENT', style: h)),
              Expanded(flex: 14, child: Text('CHECK-IN', style: h)),
              Expanded(flex: 14, child: Text('CHECK-OUT', style: h)),
              Expanded(flex: 14, child: Text('TOTAL HOURS', style: h)),
              Expanded(flex: 16, child: Text('STATUS', style: h)),
            ],
          ),
        ),
        for (var i = 0; i < rows.length; i++) ...[
          _tableRow(rows[i]),
          if (i != rows.length - 1) const Divider(height: 1, color: AdminEmpColors.border),
        ],
      ],
    );
  }

  Widget _tableRow(_Row r) {
    final e = r.employee;
    const cell = TextStyle(fontSize: 14, color: AdminEmpColors.text);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 30,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AdminEmpColors.primarySoft,
                  child: Text(
                    e.initials,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminEmpColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AdminEmpColors.text),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        e.employeeCode,
                        style: const TextStyle(fontSize: 12.5, color: AdminEmpColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 16, child: Text(adminProfOrDash(e.department), style: cell)),
          Expanded(flex: 14, child: Text(adminProfTime(r.record?.checkIn), style: cell.copyWith(fontWeight: FontWeight.w600))),
          Expanded(flex: 14, child: Text(adminProfTime(r.record?.checkOut), style: cell.copyWith(fontWeight: FontWeight.w600))),
          Expanded(flex: 14, child: _hoursCell(r)),
          Expanded(
            flex: 16,
            child: Align(alignment: Alignment.centerLeft, child: _statusPill(_statusKey(r.record))),
          ),
        ],
      ),
    );
  }

  /// true = checked in today and not checked out yet (counter is running).
  bool _isWorking(AdminDailyAttendance? rec) =>
      _isToday && rec?.checkIn != null && rec?.checkOut == null;

  /// 02:15:30
  String _clock(Duration d) {
    final total = d.isNegative ? 0 : d.inSeconds;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(total ~/ 3600)}:${two((total % 3600) ~/ 60)}:${two(total % 60)}';
  }

  Widget _hoursCell(_Row r) {
    final rec = r.record;

    // LIVE: started at check-in, stops when the check-out arrives
    if (_isWorking(rec)) {
      final start = rec!.checkIn!;
      return ValueListenableBuilder<DateTime>(
        valueListenable: _now,
        builder: (context, now, _) {
          final blink = now.second.isEven;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedOpacity(
                opacity: blink ? 1 : 0.3,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AdminEmpColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                _clock(now.difference(start)),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AdminEmpColors.primary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          );
        },
      );
    }

    // FINISHED: total hours from the server, or check-out minus check-in
    var total = rec?.totalHours;
    if ((total == null || total <= 0) && rec?.checkIn != null && rec?.checkOut != null) {
      total = rec!.checkOut!.difference(rec.checkIn!).inSeconds / 3600;
    }

    if (total != null && total > 0) {
      return Text(
        _hoursText(total),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AdminEmpColors.text),
      );
    }

    return const Text('—', style: TextStyle(fontSize: 14, color: AdminEmpColors.muted));
  }

  // ------------------------------------------------------------
  // compact card (phone)
  // ------------------------------------------------------------

  Widget _compactCard(_Row r) {
    final e = r.employee;
    final rec = r.record;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AdminEmpColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AdminEmpColors.primarySoft,
                child: Text(
                  e.initials,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminEmpColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AdminEmpColors.text),
                    ),
                    Text(
                      '${e.employeeCode}  •  ${adminProfOrDash(e.department)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AdminEmpColors.muted),
                    ),
                  ],
                ),
              ),
              _statusPill(_statusKey(rec)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _mini('CHECK-IN', adminProfTime(rec?.checkIn))),
              Expanded(child: _mini('CHECK-OUT', adminProfTime(rec?.checkOut))),
              Expanded(child: _miniWidget('TOTAL', _hoursCell(r))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mini(String label, String value) => _miniWidget(
    label,
    Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AdminEmpColors.text)),
  );

  Widget _miniWidget(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AdminEmpColors.muted,
          ),
        ),
        const SizedBox(height: 3),
        child,
      ],
    );
  }

  // ------------------------------------------------------------
  // status pill
  // ------------------------------------------------------------

  Widget _statusPill(String key) {
    Color fg;
    Color bg;
    String label;

    switch (key) {
      case 'present':
        fg = const Color(0xFF15803D);
        bg = const Color(0xFFDCFCE7);
        label = 'Present';
        break;
      case 'late':
        fg = const Color(0xFFB45309);
        bg = const Color(0xFFFEF3C7);
        label = 'Late';
        break;
      case 'half_day':
        fg = const Color(0xFF1D4ED8);
        bg = const Color(0xFFDBEAFE);
        label = 'Half Day';
        break;
      case 'absent':
        fg = const Color(0xFFC62828);
        bg = const Color(0xFFFDE2E2);
        label = 'Absent';
        break;
      case 'on_leave':
      case 'leave':
        fg = const Color(0xFF6D28D9);
        bg = const Color(0xFFEDE9FE);
        label = 'On Leave';
        break;
      case 'holiday':
        fg = const Color(0xFF1D4ED8);
        bg = const Color(0xFFDBEAFE);
        label = 'Holiday';
        break;
      case 'week_off':
        fg = const Color(0xFF6B7280);
        bg = const Color(0xFFF1F2F4);
        label = 'Week Off';
        break;
      case 'not_checked_in':
        fg = const Color(0xFF6B7280);
        bg = const Color(0xFFF1F2F4);
        label = 'Not checked in';
        break;
      default:
        fg = const Color(0xFF6B7280);
        bg = const Color(0xFFF1F2F4);
        label = key == 'no_record' ? 'No record' : adminProfTitle(key);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _Row {
  final AdminEmployeeModel employee;
  final AdminDailyAttendance? record;
  const _Row(this.employee, this.record);
}
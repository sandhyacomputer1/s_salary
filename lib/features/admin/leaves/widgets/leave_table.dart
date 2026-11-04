import 'package:flutter/material.dart';

import '../models/leave_model.dart';

/// Web style table for the admin Leave screen:
///   Leave Requests (3)                                   [ Export CSV ]
///   1 pending request(s) awaiting approval
///   [1 leave request(s) selected]   [Approve Selected (1)] [Reject Selected (1)]
///   [ ] EMPLOYEE  LEAVE TYPE  DATES  DAYS  REASON  STATUS
///   [ ] amit      Casual      03 Nov 2026   0.5  ...  pending  [Approve] [Reject]
///
/// Tap a row = open the details (same as the cards).
class LeaveTable extends StatelessWidget {
  final List<LeaveModel> leaves;
  final int totalPending;
  final Set<String> selectedIds;
  final bool canManage;
  final bool busy;

  final void Function(String id) onToggle;
  final void Function(bool selectAll) onToggleAll;
  final void Function(LeaveModel leave) onTap;
  final Future<bool> Function(LeaveModel leave) onApprove;
  final Future<bool> Function(LeaveModel leave) onReject;
  final VoidCallback onExport;
  final VoidCallback onBulkApprove;
  final VoidCallback onBulkReject;

  const LeaveTable({
    super.key,
    required this.leaves,
    required this.totalPending,
    required this.selectedIds,
    required this.canManage,
    required this.busy,
    required this.onToggle,
    required this.onToggleAll,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
    required this.onExport,
    required this.onBulkApprove,
    required this.onBulkReject,
  });

  static const Color primary = Color(0xFFE96832);
  static const Color danger = Color(0xFFD64545);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFE1E5EA);
  static const Color headerBg = Color(0xFFF1F2F4);

  static const double _checkW = 44;
  static const double _actionsW = 190;

  bool _isPending(LeaveModel l) => l.status.toLowerCase() == 'pending';
  bool _selectable(LeaveModel l) => canManage && _isPending(l);

  @override
  Widget build(BuildContext context) {
    final selectable = leaves.where(_selectable).toList();
    final selectedCount = selectable.where((l) => selectedIds.contains(l.id)).length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
            child: _titleRow(),
          ),
          if (selectedCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
              child: _bulkBar(selectedCount),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Column(
                children: [
                  _headerRow(selectable, selectedCount),
                  for (var i = 0; i < leaves.length; i++) ...[
                    _row(leaves[i]),
                    if (i != leaves.length - 1) const Divider(height: 1, color: border),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // title + export
  // ------------------------------------------------------------

  Widget _titleRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leave Requests (${leaves.length})',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textDark),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalPending pending request(s) awaiting approval',
                style: const TextStyle(fontSize: 13, color: textMedium),
              ),
            ],
          ),
        ),
        OutlinedButton(
          onPressed: onExport,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 46),
            foregroundColor: textDark,
            side: const BorderSide(color: border),
            padding: const EdgeInsets.symmetric(horizontal: 22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Export CSV', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // bulk bar (blue)
  // ------------------------------------------------------------

  Widget _bulkBar(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$count leave request(s) selected',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D4ED8),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: busy ? null : onBulkApprove,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 46),
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: busy
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : Text('Approve Selected ($count)', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: busy ? null : onBulkReject,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 46),
              foregroundColor: danger,
              backgroundColor: Colors.white,
              side: BorderSide(color: danger.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Reject Selected ($count)', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // header row
  // ------------------------------------------------------------

  Widget _headerRow(List<LeaveModel> selectable, int selectedCount) {
    const h = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: textMedium,
    );

    final bool? headerValue = selectable.isEmpty || selectedCount == 0
        ? false
        : (selectedCount == selectable.length ? true : null);

    return Container(
      color: headerBg,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: _checkW,
            child: canManage && selectable.isNotEmpty
                ? Checkbox(
              value: headerValue,
              tristate: true,
              activeColor: primary,
              onChanged: busy ? null : (_) => onToggleAll(headerValue != true),
            )
                : const SizedBox.shrink(),
          ),
          const Expanded(flex: 22, child: Text('EMPLOYEE', style: h)),
          const Expanded(flex: 14, child: Text('LEAVE TYPE', style: h)),
          const Expanded(flex: 24, child: Text('DATES', style: h)),
          const Expanded(flex: 8, child: Text('DAYS', style: h)),
          const Expanded(flex: 20, child: Text('REASON', style: h)),
          const Expanded(flex: 13, child: Text('STATUS', style: h)),
          const SizedBox(width: _actionsW),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // data row
  // ------------------------------------------------------------

  Widget _row(LeaveModel l) {
    const cell = TextStyle(fontSize: 14.5, color: textDark);
    final pending = _isPending(l);
    final selectable = _selectable(l);
    final selected = selectedIds.contains(l.id);

    return Material(
      color: selected ? const Color(0xFFFFF8F4) : Colors.white,
      child: InkWell(
        onTap: () => onTap(l),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: _checkW,
                child: selectable
                    ? Checkbox(
                  value: selected,
                  activeColor: primary,
                  onChanged: busy ? null : (_) => onToggle(l.id),
                )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                flex: 22,
                child: Text(
                  l.employeeDisplayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: cell.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                flex: 14,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        l.leaveType.isEmpty ? 'Leave' : l.leaveType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: cell,
                      ),
                    ),
                    if (l.isHalfDay) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9F0FF),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'Half',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(flex: 24, child: Text(_dates(l), maxLines: 1, overflow: TextOverflow.ellipsis, style: cell)),
              Expanded(
                flex: 8,
                child: Text(_days(l.totalDays), style: cell.copyWith(fontWeight: FontWeight.w700)),
              ),
              Expanded(
                flex: 20,
                child: Text(
                  l.reason.trim().isEmpty ? '—' : l.reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: cell,
                ),
              ),
              Expanded(
                flex: 13,
                child: Align(alignment: Alignment.centerLeft, child: _statusPill(l.status)),
              ),
              SizedBox(
                width: _actionsW,
                child: (canManage && pending)
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: busy ? null : () => onApprove(l),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Approve', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: busy ? null : () => onReject(l),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        foregroundColor: textDark,
                        side: const BorderSide(color: border),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Reject', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 12),
                  ],
                )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // helpers
  // ------------------------------------------------------------

  Widget _statusPill(String status) {
    final s = status.toLowerCase();
    Color fg;
    Color bg;
    if (s == 'approved') {
      fg = const Color(0xFF15803D);
      bg = const Color(0xFFE9F8EF);
    } else if (s == 'rejected') {
      fg = const Color(0xFFC62828);
      bg = const Color(0xFFFDECEC);
    } else if (s == 'cancelled') {
      fg = textLight;
      bg = const Color(0xFFF1F2F4);
    } else {
      fg = const Color(0xFFB45309);
      bg = const Color(0xFFFFF6E5);
    }

    final hollow = s == 'rejected' || s == 'cancelled';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: hollow ? Colors.transparent : fg,
              shape: BoxShape.circle,
              border: hollow ? Border.all(color: fg, width: 1.3) : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(s, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }

  String _days(double d) => d.truncateToDouble() == d ? d.toStringAsFixed(0) : d.toStringAsFixed(1);

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _one(DateTime d) {
    final u = d.toUtc();
    return '${u.day.toString().padLeft(2, '0')} ${_months[u.month - 1]} ${u.year}';
  }

  /// "03 Nov 2026"  or  "03 Nov 2026 → 04 Nov 2026"
  String _dates(LeaveModel l) {
    final s = l.startDate;
    final e = l.endDate;
    if (s == null) return '-';
    if (e == null || l.isHalfDay) return _one(s);

    final sameDay = s.toUtc().year == e.toUtc().year &&
        s.toUtc().month == e.toUtc().month &&
        s.toUtc().day == e.toUtc().day;
    return sameDay ? _one(s) : '${_one(s)} → ${_one(e)}';
  }
}
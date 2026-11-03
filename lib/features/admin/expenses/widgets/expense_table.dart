import 'package:flutter/material.dart';

import '../models/expense_model.dart';

/// Web style table for the admin Expenses screen:
///   Expense Reimbursement Claims (4)                    [ Export CSV ]
///   3 pending claim(s) awaiting approval
///   [3 expense claim(s) selected]   [Approve Selected (3)] [Reject Selected (3)]
///   [ ] EMPLOYEE  CATEGORY  AMOUNT  DATE  DESCRIPTION  STATUS
///   [ ] Sandhya   Food      ₹5555   ...                pending  [Approve] [Reject]
///
/// Tap a row = open the details (same as the cards).
class ExpenseTable extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final int totalPending;
  final Set<String> selectedIds;
  final bool canManage;
  final bool busy;

  final void Function(String id) onToggle;
  final void Function(bool selectAll) onToggleAll;
  final void Function(ExpenseModel expense) onTap;
  final Future<bool> Function(ExpenseModel expense) onApprove;
  final Future<bool> Function(ExpenseModel expense) onReject;
  final VoidCallback onExport;
  final VoidCallback onBulkApprove;
  final VoidCallback onBulkReject;

  const ExpenseTable({
    super.key,
    required this.expenses,
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
  static const Color primaryLight = Color(0xFFFFEEE7);
  static const Color danger = Color(0xFFD64545);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFE1E5EA);
  static const Color headerBg = Color(0xFFF1F2F4);

  static const double _checkW = 44;
  static const double _actionsW = 190;

  bool _isPending(ExpenseModel e) => e.status.toLowerCase() == 'pending';
  bool _selectable(ExpenseModel e) => canManage && _isPending(e);

  @override
  Widget build(BuildContext context) {
    final selectable = expenses.where(_selectable).toList();
    final selectedCount = selectable.where((e) => selectedIds.contains(e.id)).length;

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
                  for (var i = 0; i < expenses.length; i++) ...[
                    _row(expenses[i]),
                    if (i != expenses.length - 1) const Divider(height: 1, color: border),
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
                'Expense Reimbursement Claims (${expenses.length})',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textDark),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalPending pending claim(s) awaiting approval',
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
              '$count expense claim(s) selected',
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

  Widget _headerRow(List<ExpenseModel> selectable, int selectedCount) {
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
          const Expanded(flex: 24, child: Text('EMPLOYEE', style: h)),
          const Expanded(flex: 14, child: Text('CATEGORY', style: h)),
          const Expanded(flex: 12, child: Text('AMOUNT', style: h)),
          const Expanded(flex: 14, child: Text('DATE', style: h)),
          const Expanded(flex: 22, child: Text('DESCRIPTION', style: h)),
          const Expanded(flex: 13, child: Text('STATUS', style: h)),
          const SizedBox(width: _actionsW),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // data row
  // ------------------------------------------------------------

  Widget _row(ExpenseModel e) {
    const cell = TextStyle(fontSize: 14.5, color: textDark);
    final pending = _isPending(e);
    final selectable = _selectable(e);
    final selected = selectedIds.contains(e.id);

    return Material(
      color: selected ? const Color(0xFFFFF8F4) : Colors.white,
      child: InkWell(
        onTap: () => onTap(e),
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
                  onChanged: busy ? null : (_) => onToggle(e.id),
                )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                flex: 24,
                child: Text(
                  e.employeeDisplayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: cell.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(flex: 14, child: Text(e.category, maxLines: 1, overflow: TextOverflow.ellipsis, style: cell)),
              Expanded(
                flex: 12,
                child: Text('₹${_amount(e.amount)}', style: cell.copyWith(fontWeight: FontWeight.w700)),
              ),
              Expanded(flex: 14, child: Text(_date(e.expenseDate), style: cell)),
              Expanded(
                flex: 22,
                child: Text(
                  e.description.trim().isEmpty ? '—' : e.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: cell,
                ),
              ),
              Expanded(
                flex: 13,
                child: Align(alignment: Alignment.centerLeft, child: _statusPill(e.status)),
              ),
              SizedBox(
                width: _actionsW,
                child: (canManage && pending)
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: busy ? null : () => onApprove(e),
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
                      onPressed: busy ? null : () => onReject(e),
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
    } else {
      fg = const Color(0xFFB45309);
      bg = const Color(0xFFFFF6E5);
    }

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
              color: s == 'rejected' ? Colors.transparent : fg,
              shape: BoxShape.circle,
              border: s == 'rejected' ? Border.all(color: fg, width: 1.3) : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(s, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }

  String _amount(double v) => v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// "03 Nov 2026" (the web shows the raw 2026-11-03T00:00:00.000Z text)
  String _date(DateTime? d) {
    if (d == null) return '-';
    final u = d.toUtc();
    return '${u.day.toString().padLeft(2, '0')} ${_months[u.month - 1]} ${u.year}';
  }
}
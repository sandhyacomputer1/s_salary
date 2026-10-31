import 'package:flutter/material.dart';

import '../models/admin_employee_model.dart';
import '../models/admin_employee_profile_models.dart';
import '../services/admin_employee_profile_service.dart';
import 'admin_employee_theme.dart';
import 'admin_profile_common.dart';

/// Leave balances (this year) + leave request history.
class AdminProfileLeaveTab extends StatefulWidget {
  final AdminEmployeeModel employee;
  final AdminEmployeeProfileService service;

  const AdminProfileLeaveTab({super.key, required this.employee, required this.service});

  @override
  State<AdminProfileLeaveTab> createState() => _AdminProfileLeaveTabState();
}

class _AdminProfileLeaveTabState extends State<AdminProfileLeaveTab> {
  int _reload = 0;

  Future<void> _decide(Future<void> Function() call, String message) async {
    await call();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
    setState(() => _reload++); // reload balances + history
  }

  Future<(List<AdminLeaveBalance>, List<AdminLeaveRequest>)> _load() async {
    final year = DateTime.now().year;
    final results = await Future.wait([
      widget.service.getLeaveBalances(widget.employee.id, year),
      widget.service.getLeaveHistory(widget.employee.id),
    ]);
    return (results[0] as List<AdminLeaveBalance>, results[1] as List<AdminLeaveRequest>);
  }

  String _days(double d) => d == d.roundToDouble() ? d.round().toString() : d.toString();

  String _range(AdminLeaveRequest r) {
    final start = adminEmpFormatDate(r.startDate);
    if (r.isHalfDay) return '$start (half day)';
    final same = r.endDate == null ||
        (r.startDate != null && r.endDate!.toUtc().difference(r.startDate!.toUtc()).inDays == 0);
    return same ? start : '$start  →  ${adminEmpFormatDate(r.endDate)}';
  }

  @override
  Widget build(BuildContext context) {
    return AdminProfileFuture<(List<AdminLeaveBalance>, List<AdminLeaveRequest>)>(
      key: ValueKey('leave-$_reload'),
      load: _load,
      builder: (context, data) {
        final (balances, history) = data;
        return Column(
          children: [
            AdminProfileCard(
              padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminProfileSectionTitle('Leave Balance ${DateTime.now().year}'),
                  const SizedBox(height: 22),
                  if (balances.isEmpty)
                    const AdminProfileEmpty('No leave types configured.')
                  else
                    _balanceCards(balances),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AdminProfileCard(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: AdminProfileSectionTitle('Leave History'),
                  ),
                  const SizedBox(height: 18),
                  if (history.isEmpty)
                    const AdminProfileEmpty('No leave requests yet.')
                  else
                    ClipRRect(borderRadius: BorderRadius.circular(10), child: _history(history)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _balanceCards(List<AdminLeaveBalance> balances) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 900 ? 4 : (c.maxWidth >= 560 ? 3 : 2);
        const gap = 16.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final b in balances)
              Container(
                width: w,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AdminEmpColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminProfileSmallCaps(b.leaveType.toUpperCase()),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _days(b.remaining),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AdminEmpColors.primary,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 3),
                          child: Text('left', style: TextStyle(fontSize: 12.5, color: AdminEmpColors.muted)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: b.allotted == 0 ? 0 : (b.used / b.allotted).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(AdminEmpColors.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Used ${_days(b.used)} of ${_days(b.allotted)}',
                      style: const TextStyle(fontSize: 12, color: AdminEmpColors.muted),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _actions(AdminLeaveRequest r) {
    if (!r.isPending) return const Text('—');
    return AdminApproveRejectButtons(
      onApprove: () => _decide(() => widget.service.approveLeave(r.id), 'Leave approved'),
      onReject: () => _decide(() => widget.service.rejectLeave(r.id), 'Leave rejected'),
    );
  }

  Widget _history(List<AdminLeaveRequest> list) {
    return AdminSimpleTable(
      headers: const ['TYPE', 'DATES', 'DAYS', 'REASON', 'STATUS', 'ACTIONS'],
      flex: const [2, 4, 1, 3, 2, 4],
      rows: [
        for (final r in list)
          [
            Text(adminProfOrDash(r.leaveType), style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(_range(r)),
            Text(_days(r.totalDays)),
            Text(adminProfOrDash(r.reason), maxLines: 2, overflow: TextOverflow.ellipsis),
            AdminStatusPill(r.status),
            _actions(r),
          ],
      ],
      compactBuilder: (i) {
        final r = list[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AdminEmpColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${adminProfOrDash(r.leaveType)}  •  ${_days(r.totalDays)} day(s)',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  AdminStatusPill(r.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(_range(r), style: const TextStyle(fontSize: 12.5, color: AdminEmpColors.muted)),
              if (r.reason.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(r.reason, style: const TextStyle(fontSize: 12.5)),
              ],
              if (r.isPending) ...[
                const SizedBox(height: 10),
                _actions(r),
              ],
            ],
          ),
        );
      },
    );
  }
}
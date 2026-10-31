import 'package:flutter/material.dart';

import '../models/admin_employee_model.dart';
import '../models/admin_employee_profile_models.dart';
import '../services/admin_employee_profile_service.dart';
import 'admin_employee_theme.dart';
import 'admin_profile_common.dart';

/// Expense claims of the employee with totals.
class AdminProfileExpensesTab extends StatefulWidget {
  final AdminEmployeeModel employee;
  final AdminEmployeeProfileService service;

  const AdminProfileExpensesTab({super.key, required this.employee, required this.service});

  @override
  State<AdminProfileExpensesTab> createState() => _AdminProfileExpensesTabState();
}

class _AdminProfileExpensesTabState extends State<AdminProfileExpensesTab> {
  int _reload = 0;

  Future<void> _decide(Future<void> Function() call, String message) async {
    await call();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
    setState(() => _reload++);
  }

  Widget _actions(AdminExpenseItem e) {
    if (!e.isPending) return const Text('—');
    return AdminApproveRejectButtons(
      onApprove: () => _decide(() => widget.service.approveExpense(e.id), 'Expense approved'),
      onReject: () => _decide(() => widget.service.rejectExpense(e.id), 'Expense rejected'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminProfileFuture<List<AdminExpenseItem>>(
      key: ValueKey('expenses-$_reload'),
      load: () => widget.service.getExpenses(widget.employee.id),
      builder: (context, list) {
        double sum(bool Function(AdminExpenseItem) test) =>
            list.where(test).fold<double>(0, (s, e) => s + e.amount);

        final approved = sum((e) => e.status == 'approved');
        final pending = sum((e) => e.status == 'pending');

        return AdminProfileCard(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: AdminProfileSectionTitle('Expense Claims'),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _total('Approved', adminEmpRupees(approved), const Color(0xFF16A34A), const Color(0xFFF0FDF4)),
                    _total('Pending', adminEmpRupees(pending), const Color(0xFFD97706), const Color(0xFFFFFBEB)),
                    _total('Claims', '${list.length}', AdminEmpColors.muted, const Color(0xFFF3F4F6)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (list.isEmpty)
                const AdminProfileEmpty('No expense claims yet.', icon: Icons.receipt_long_outlined)
              else
                ClipRRect(borderRadius: BorderRadius.circular(10), child: _table(list)),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _total(String label, String value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 10),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AdminEmpColors.text)),
        ],
      ),
    );
  }

  Widget _table(List<AdminExpenseItem> list) {
    return AdminSimpleTable(
      headers: const ['DATE', 'CATEGORY', 'DESCRIPTION', 'AMOUNT', 'STATUS', 'ACTIONS'],
      flex: const [2, 2, 4, 2, 2, 4],
      rows: [
        for (final e in list)
          [
            Text(adminEmpFormatDate(e.expenseDate), style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(adminProfTitle(e.category)),
            Text(adminProfOrDash(e.description), maxLines: 2, overflow: TextOverflow.ellipsis),
            Text(adminEmpRupees(e.amount), style: const TextStyle(fontWeight: FontWeight.w800)),
            AdminStatusPill(e.status),
            _actions(e),
          ],
      ],
      compactBuilder: (i) {
        final e = list[i];
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
                    Text(
                      '${adminProfTitle(e.category)}  •  ${adminEmpRupees(e.amount)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${adminEmpFormatDate(e.expenseDate)}${e.description.isEmpty ? '' : '  •  ${e.description}'}',
                      style: const TextStyle(fontSize: 12.5, color: AdminEmpColors.muted),
                    ),
                    if (e.isPending) ...[
                      const SizedBox(height: 10),
                      _actions(e),
                    ],
                  ],
                ),
              ),
              AdminStatusPill(e.status),
            ],
          ),
        );
      },
    );
  }
}
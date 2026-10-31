import 'package:flutter/material.dart';

import '../../employees/widgets/admin_employee_theme.dart';
import '../../employees/widgets/admin_profile_common.dart';

/// One row of a pending list.
class AdminPendingRowData {
  final String title;
  final String subtitle;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;

  const AdminPendingRowData({
    required this.title,
    required this.subtitle,
    required this.onApprove,
    required this.onReject,
  });
}

/// "Pending Leaves (0)" / "Pending Expenses (1)" card with Approve / Reject.
class AdminOverviewPendingCard extends StatelessWidget {
  final String title;
  final int count;
  final String emptyText;
  final VoidCallback onViewAll;
  final List<AdminPendingRowData> rows;

  const AdminOverviewPendingCard({
    super.key,
    required this.title,
    required this.count,
    required this.emptyText,
    required this.onViewAll,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  '$title ($count)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AdminEmpColors.text,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: onViewAll,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  foregroundColor: AdminEmpColors.text,
                  side: const BorderSide(color: AdminEmpColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('View All', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEDEFF3)),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 44),
              child: Center(
                child: Text(
                  emptyText,
                  style: const TextStyle(fontSize: 15, color: AdminEmpColors.muted),
                ),
              ),
            )
          else
            for (var i = 0; i < rows.length; i++) ...[
              _row(rows[i]),
              if (i != rows.length - 1) const Divider(height: 1, color: Color(0xFFEDEFF3)),
            ],
        ],
      ),
    );
  }

  Widget _row(AdminPendingRowData r) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          r.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AdminEmpColors.text,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          r.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13.5, color: AdminEmpColors.muted),
        ),
      ],
    );

    final buttons = AdminApproveRejectButtons(onApprove: r.onApprove, onReject: r.onReject);

    return LayoutBuilder(
      builder: (context, c) {
        // narrow (phone): buttons go under the text
        if (c.maxWidth < 420) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [text, const SizedBox(height: 10), buttons],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: 12),
              buttons,
            ],
          ),
        );
      },
    );
  }
}
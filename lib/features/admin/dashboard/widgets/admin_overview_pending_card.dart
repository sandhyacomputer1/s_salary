import 'package:flutter/material.dart';

import '../../employees/widgets/admin_employee_theme.dart';

// ---- tweak sizes here ----
const double _btnHeight = 34;
const double _approveWidth = 76;
const double _rejectWidth = 66;
const double _btnFont = 12.5;
// --------------------------

class AdminPendingRowData {
  final String title;
  final String subtitle;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const AdminPendingRowData({
    required this.title,
    required this.subtitle,
    required this.onApprove,
    required this.onReject,
  });
}

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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$title ($count)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AdminEmpColors.text,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: onViewAll,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AdminEmpColors.text,
                    side: const BorderSide(color: AdminEmpColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('View All',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEDEFF3)),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(emptyText,
                    style: const TextStyle(color: AdminEmpColors.muted, fontSize: 14)),
              ),
            )
          else
            for (int i = 0; i < rows.length; i++) ...[
              _row(rows[i]),
              if (i != rows.length - 1)
                const Divider(height: 1, color: Color(0xFFEDEFF3), indent: 16, endIndent: 16),
            ],
        ],
      ),
    );
  }

  Widget _row(AdminPendingRowData r) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // left: name + details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AdminEmpColors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  r.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AdminEmpColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // right: Approve + Reject side by side
          SizedBox(
            width: _approveWidth,
            height: _btnHeight,
            child: ElevatedButton(
              onPressed: r.onApprove,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: AdminEmpColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Approve',
                  style: TextStyle(fontSize: _btnFont, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: _rejectWidth,
            height: _btnHeight,
            child: OutlinedButton(
              onPressed: r.onReject,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AdminEmpColors.danger,
                side: const BorderSide(color: AdminEmpColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Reject',
                  style: TextStyle(fontSize: _btnFont, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../models/expense_claim_summary_model.dart';
import '../utils/expense_colors.dart';
import '../utils/expense_formatters.dart';

class ExpenseClaimSummaryCards extends StatelessWidget {
  final ExpenseClaimSummaryModel summary;

  const ExpenseClaimSummaryCards({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final half = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryTile(
                  width: constraints.maxWidth,
                  title: 'Total Claimed',
                  amount: summary.totalAmount,
                  count: summary.totalCount,
                  color: ExpenseColors.primary,
                  icon: Icons.receipt_long_outlined,
                ),
                _SummaryTile(
                  width: half,
                  title: 'Pending',
                  amount: summary.pendingAmount,
                  count: summary.pendingCount,
                  color: const Color(0xFFB26A00),
                  icon: Icons.schedule,
                ),
                _SummaryTile(
                  width: half,
                  title: 'Approved',
                  amount: summary.approvedAmount,
                  count: summary.approvedCount,
                  color: const Color(0xFF2E7D32),
                  icon: Icons.check_circle_outline,
                ),
                _SummaryTile(
                  width: half,
                  title: 'Reimbursed',
                  amount: summary.reimbursedAmount,
                  count: summary.reimbursedCount,
                  color: const Color(0xFF1565C0),
                  icon: Icons.payments_outlined,
                ),
                _SummaryTile(
                  width: half,
                  title: 'Rejected',
                  amount: summary.rejectedAmount,
                  count: summary.rejectedCount,
                  color: const Color(0xFFC62828),
                  icon: Icons.cancel_outlined,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'Calculated from your claims list',
          style: TextStyle(fontSize: 11, color: ExpenseColors.textSecondary),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final double width;
  final String title;
  final double amount;
  final int count;
  final Color color;
  final IconData icon;

  const _SummaryTile({
    required this.width,
    required this.title,
    required this.amount,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ExpenseColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ExpenseColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              ExpenseFormatters.inr(amount),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            count == 1 ? '1 claim' : '$count claims',
            style: const TextStyle(
              fontSize: 12,
              color: ExpenseColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
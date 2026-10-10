import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/expense_claim_model.dart';
import '../utils/expense_colors.dart';
import '../utils/expense_formatters.dart';
import 'expense_claim_status_badge.dart';

class ExpenseClaimCard extends StatelessWidget {
  final ExpenseClaimModel claim;

  const ExpenseClaimCard({super.key, required this.claim});

  @override
  Widget build(BuildContext context) {
    final expenseDate = ExpenseFormatters.calendarDate(claim.expenseDate);
    final submitted = ExpenseFormatters.instantDate(claim.submittedAt);
    final actioned = ExpenseFormatters.instantDate(claim.actionedAt);
    final actionLabel = _actionLabel(claim.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ExpenseColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ExpenseColors.primaryTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _categoryIcon(claim.category),
                  color: ExpenseColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claim.category.isEmpty ? 'Expense' : claim.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ExpenseColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ExpenseFormatters.inr(claim.amount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: ExpenseColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ExpenseClaimStatusBadge(
                status: claim.status,
                rawStatus: claim.rawStatus,
              ),
            ],
          ),
          if (claim.description != null) ...[
            const SizedBox(height: 12),
            Text(
              claim.description!,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.35,
                color: ExpenseColors.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: ExpenseColors.border),
          const SizedBox(height: 10),
          if (expenseDate.isNotEmpty)
            _InfoRow(
              icon: Icons.event_outlined,
              label: 'Expense date',
              value: expenseDate,
            ),
          if (submitted.isNotEmpty)
            _InfoRow(
              icon: Icons.send_outlined,
              label: 'Submitted',
              value: submitted,
            ),
          if (actionLabel != null && actioned.isNotEmpty)
            _InfoRow(
              icon: Icons.flag_outlined,
              label: actionLabel,
              value: actioned,
            ),
          if (claim.hasBillLink)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: ExpenseColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(48, 40),
                  tapTargetSize: MaterialTapTargetSize.padded,
                ),
                onPressed: () => _copyLink(context, claim.billUrl!),
                icon: const Icon(Icons.link, size: 18),
                label: const Text('Copy receipt link'),
              ),
            )
          else if (claim.hasInlineBill)
            const _InfoRow(
              icon: Icons.attach_file,
              label: 'Receipt',
              value: 'Attached',
            ),
        ],
      ),
    );
  }

  Future<void> _copyLink(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: url));
    messenger.showSnackBar(
      const SnackBar(content: Text('Receipt link copied')),
    );
  }

  String? _actionLabel(ExpenseClaimStatus s) {
    switch (s) {
      case ExpenseClaimStatus.approved:
        return 'Approved on';
      case ExpenseClaimStatus.rejected:
        return 'Rejected on';
      case ExpenseClaimStatus.reimbursed:
        return 'Reimbursed on';
      case ExpenseClaimStatus.cancelled:
        return 'Cancelled on';
      case ExpenseClaimStatus.pending:
      case ExpenseClaimStatus.unknown:
        return null;
    }
  }

  IconData _categoryIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('travel') || c.contains('transport') || c.contains('fuel')) {
      return Icons.directions_car_outlined;
    }
    if (c.contains('food')) return Icons.restaurant_outlined;
    if (c.contains('suppl')) return Icons.inventory_2_outlined;
    if (c.contains('medical')) return Icons.medical_services_outlined;
    return Icons.receipt_long_outlined;
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: ExpenseColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              color: ExpenseColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ExpenseColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
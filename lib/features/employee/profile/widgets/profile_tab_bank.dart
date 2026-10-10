// lib/features/employee/profile/widgets/profile_tab_bank.dart

import 'package:flutter/material.dart';

import '../models/employee_profile_details_model.dart';
import '../utils/profile_colors.dart';
import '../utils/profile_formatters.dart';
import 'profile_grid.dart';
import 'profile_section_card.dart';

class ProfileTabBank extends StatelessWidget {
  final BankDetails details;
  final VoidCallback onUpdate;

  const ProfileTabBank({
    super.key,
    required this.details,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      title: 'Bank Account & Payment Payout Details',
      subtitle:
      'Official bank account numbers used for direct salary transfers & reimbursements',
      actionLabel: 'Update Bank Details',
      actionStyle: ProfileCardActionStyle.tonal,
      onAction: onUpdate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileGrid(
            cellWidth: 200,
            items: [
              ProfileGridItem('Bank Name', details.bankName),
              ProfileGridItem(
                'Bank Account Number',
                details.accountNumber,
              ),
              ProfileGridItem('IFSC Code', details.ifsc),
              ProfileGridItem('UPI ID', details.upiId),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: ProfileColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Salary payments & expense claim reimbursements are deposited '
                  'directly into this bank account.',
              style: TextStyle(
                fontSize: 12.5,
                color: ProfileColors.textMedium.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
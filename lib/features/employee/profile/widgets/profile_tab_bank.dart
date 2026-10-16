import 'package:flutter/material.dart';

import '../models/employee_profile_details_model.dart';
import '../utils/profile_colors.dart';
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
return Padding(
padding: EdgeInsets.zero,
child: ProfileSectionCard(
icon: Icons.account_balance_outlined,
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
const SizedBox(height: 16),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 14,
vertical: 12,
),
decoration: BoxDecoration(
color: ProfileColors.primaryLight,
borderRadius: BorderRadius.circular(10),
),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Icon(
Icons.info_outline_rounded,
size: 18,
color: ProfileColors.primary,
),
const SizedBox(width: 10),
Expanded(
child: Text(
'Salary payments & expense claim reimbursements are '
'deposited directly into this bank account.',
style: TextStyle(
fontSize: 12.5,
color: ProfileColors.textMedium
    .withValues(alpha: 0.95),
height: 1.4,
),
),
),
],
),
),
],
),
),
);
}
}

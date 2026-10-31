import 'package:flutter/material.dart';

import '../models/admin_employee_model.dart';
import 'admin_profile_common.dart';

/// Personal details + bank details (data already loaded with the employee).
class AdminProfilePersonalTab extends StatelessWidget {
  final AdminEmployeeModel employee;
  const AdminProfilePersonalTab({super.key, required this.employee});

  /// "5885845888555" -> "•••••••••8555"
  String _mask(String v) {
    if (v.isEmpty) return '—';
    if (v.length <= 4) return v;
    return '${'•' * (v.length - 4)}${v.substring(v.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final e = employee;

    return Column(
      children: [
        AdminProfileCard(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminProfileSectionTitle('Personal Details'),
              const SizedBox(height: 24),
              AdminInfoGrid(
                maxColumns: 3,
                items: [
                  ('DATE OF BIRTH', adminEmpFormatDate(e.dob)),
                  ('GENDER', adminProfTitle(e.gender)),
                  ('MARITAL STATUS', adminProfTitle(e.maritalStatus)),
                  ('BLOOD GROUP', adminProfOrDash(e.bloodGroup)),
                  ('EMERGENCY CONTACT', adminProfOrDash(e.emergencyContact)),
                  ('WORK MODE', e.workModeLabel),
                  ('ADDRESS', adminProfOrDash(e.address)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AdminProfileCard(
          padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminProfileSectionTitle('Bank Details'),
              const SizedBox(height: 24),
              AdminInfoGrid(
                maxColumns: 3,
                items: [
                  ('BANK NAME', adminProfOrDash(e.bankName)),
                  ('ACCOUNT NUMBER', _mask(e.accountNumber)),
                  ('IFSC CODE', adminProfOrDash(e.ifsc)),
                  ('UPI ID', adminProfOrDash(e.upiId)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
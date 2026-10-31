import 'package:flutter/material.dart';

import '../models/admin_employee_model.dart';
import '../models/admin_employee_profile_models.dart';
import 'admin_employee_theme.dart';
import 'admin_profile_metrics_card.dart';
import 'admin_profile_common.dart';

/// "Attendance & Work Hours Metrics" + "Account & Company Info".
class AdminProfileOverviewTab extends StatelessWidget {
  final AdminEmployeeModel employee;
  final AdminAttendanceSummary summary;
  final AdminProfileExtra extra;

  const AdminProfileOverviewTab({
    super.key,
    required this.employee,
    required this.summary,
    required this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminProfileMetricsCard(summary: summary),
        const SizedBox(height: 28),
        _accountInfo(),
      ],
    );
  }

  // ------------------------------------------------------------
  // account & company info
  // ------------------------------------------------------------

  Widget _accountInfo() {
    final e = employee;
    final status = e.status.isEmpty ? '—' : adminProfTitle(e.status);

    return AdminProfileCard(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminProfileSectionTitle('Account & Company Info'),
          const SizedBox(height: 26),
          const Divider(height: 1, color: Color(0xFFEDEFF3)),
          const SizedBox(height: 22),
          AdminInfoGrid(
            items: [
              ('EMAIL', adminProfOrDash(e.email)),
              ('PHONE', adminProfOrDash(e.phone)),
              ('ACCOUNT STATUS', status),
              ('LAST LOGIN', adminProfDateTime(extra.lastLogin)),
              ('COMPANY', adminProfOrDash(extra.companyName)),
              ('COMPANY TIMEZONE', adminProfOrDash(extra.timezone)),
            ],
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../models/company_settings_model.dart';
import 'settings_common.dart';

String _ordinal(int n) {
  final lastTwo = n % 100;
  if (lastTwo >= 11 && lastTwo <= 13) return '${n}th';

  switch (n % 10) {
    case 1:
      return '${n}st';
    case 2:
      return '${n}nd';
    case 3:
      return '${n}rd';
    default:
      return '${n}th';
  }
}

// =================================================================
// LEAVE TYPES & QUOTAS
// =================================================================

class SettingsLeaveTab extends StatelessWidget {
  const SettingsLeaveTab({
    super.key,
    required this.settings,
    required this.onChanged,
    required this.dirty,
    required this.saving,
    required this.onSave,
  });

  final CompanySettings settings;
  final VoidCallback onChanged;
  final bool dirty;
  final bool saving;
  final VoidCallback onSave;

  CompanySettings get _s => settings;

  @override
  Widget build(BuildContext context) {
    final paid = _s.maxPaidLeavesPerMonth;
    final run = _s.maxConsecutiveLeaveDays;
    final trigger = run + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsNote(
          title: 'Monthly Paid Leave & Consecutive Sandwich Rule',
          text:
              'Maximum $paid paid leaves allowed per calendar month. '
              'Maximum $run consecutive non-working / leave days in a row. '
              'If an employee takes $trigger or more consecutive non-working '
              '/ leave days (including surrounding holidays & week-offs), any '
              '${_ordinal(trigger)} and subsequent day is automatically '
              'processed as an Unpaid Leave (Salary Cut).',
        ),
        const SizedBox(height: 16),
        SettingsRow(
          children: [
            SettingsLabeled(
              label: 'Max Paid Leaves Allowed Per Month',
              helper: 'Maximum paid leaves permitted per calendar month.',
              child: SettingsTextField(
                initialValue: '${_s.maxPaidLeavesPerMonth}',
                keyboardType: TextInputType.number,
                inputFormatters: SettingsTextField.digits,
                onChanged: (v) {
                  _s.maxPaidLeavesPerMonth = parseInt(v);
                  onChanged();
                },
              ),
            ),
            SettingsLabeled(
              label: 'Max Consecutive Leave / Absence Days',
              helper:
                  '${_ordinal(trigger)} consecutive day triggers unpaid '
                  'leave salary cut.',
              child: SettingsTextField(
                initialValue: '${_s.maxConsecutiveLeaveDays}',
                keyboardType: TextInputType.number,
                inputFormatters: SettingsTextField.digits,
                onChanged: (v) {
                  _s.maxConsecutiveLeaveDays = parseInt(v);
                  onChanged();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SettingsCheckTile(
          label: 'Enforce Consecutive Non-Working & Sandwich Leave Rule',
          value: _s.enforceSandwichRule,
          onChanged: (v) {
            _s.enforceSandwichRule = v;
            onChanged();
          },
        ),
        const SizedBox(height: 18),
        const Divider(height: 1, color: Color(0xFFEDEFF3)),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Leave Types & Annual Quotas',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kSetTextDark,
                ),
              ),
            ),
            SettingsOutlineButton(
              label: 'Add Leave Type',
              onPressed: () {
                _s.leaveTypes.add(
                  LeaveTypeRule(name: '', daysPerYear: 0, isPaid: true),
                );
                onChanged();
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_s.leaveTypes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No leave types configured.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          )
        else
          for (final type in _s.leaveTypes) _leaveRow(type),
        const SizedBox(height: 12),
        SettingsCheckTile(
          label:
              'Auto-approve leave requests if employee has sufficient '
              'balance',
          value: _s.autoApproveLeave,
          onChanged: (v) {
            _s.autoApproveLeave = v;
            onChanged();
          },
        ),
        SettingsSaveBar(dirty: dirty, saving: saving, onSave: onSave),
      ],
    );
  }

  Widget _leaveRow(LeaveTypeRule type) {
    return Padding(
      key: ObjectKey(type),
      padding: const EdgeInsets.only(bottom: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final name = SettingsTextField(
            initialValue: type.name,
            hint: 'Leave type name (e.g. Casual Leave)',
            onChanged: (v) {
              type.name = v;
              onChanged();
            },
          );

          final days = SettingsTextField(
            initialValue: showNumber(type.daysPerYear),
            hint: 'Days per year',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: SettingsTextField.decimals,
            onChanged: (v) {
              type.daysPerYear = parseDouble(v);
              onChanged();
            },
          );

          final paid = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: type.isPaid,
                activeColor: kSetPrimary,
                onChanged: (v) {
                  type.isPaid = v ?? false;
                  onChanged();
                },
              ),
              const Text('Paid', style: TextStyle(fontSize: 13)),
            ],
          );

          final remove = IconButton(
            tooltip: 'Remove leave type',
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () {
              _s.leaveTypes.remove(type);
              onChanged();
            },
          );

          if (constraints.maxWidth >= 560) {
            return Row(
              children: [
                Expanded(flex: 4, child: name),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: days),
                const SizedBox(width: 6),
                paid,
                remove,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              name,
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: days),
                  const SizedBox(width: 6),
                  paid,
                  remove,
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// =================================================================
// SECURITY & 2FA
// =================================================================

class SettingsSecurityTab extends StatelessWidget {
  const SettingsSecurityTab({
    super.key,
    required this.settings,
    required this.onChanged,
    required this.dirty,
    required this.saving,
    required this.onSave,
  });

  final CompanySettings settings;
  final VoidCallback onChanged;
  final bool dirty;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4EE),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF8D4C2)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Two-Factor Authentication (2FA / OTP) Enforcement',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kSetPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Enforce mandatory 6-digit email OTP verification for all '
                'admin accounts in this organization. When enabled, logging '
                'in will require entering a security verification code sent '
                "to the admin's email.",
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: kSetTextDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: SettingsCheckTile(
            label: 'Enforce Mandatory 2FA OTP for All Admin Accounts',
            subtitle:
                'Applies to primary company owner and assigned branch admins.',
            value: settings.enforce2FA,
            onChanged: (v) {
              settings.enforce2FA = v;
              onChanged();
            },
          ),
        ),
        if (settings.enforce2FA) ...[
          const SizedBox(height: 10),
          const Text(
            "Before saving, make sure every admin's email address is correct: "
            'they will need it to receive the login code.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFFB45309)),
          ),
        ],
        SettingsSaveBar(dirty: dirty, saving: saving, onSave: onSave),
      ],
    );
  }
}

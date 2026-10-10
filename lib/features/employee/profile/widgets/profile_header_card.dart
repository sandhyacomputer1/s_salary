// lib/features/employee/profile/widgets/profile_header_card.dart

import 'package:flutter/material.dart';

import '../utils/profile_colors.dart';
import '../utils/profile_formatters.dart';

class ProfileHeaderCard extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final String employeeCode;
  final String designation;
  final String department;
  final String status;
  final VoidCallback onEditAll;

  const ProfileHeaderCard({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.employeeCode,
    required this.designation,
    required this.department,
    required this.status,
    required this.onEditAll,
  });

  @override
  Widget build(BuildContext context) {
    final roleLine = [designation, department]
        .where((s) => s.trim().isNotEmpty)
        .join(' • ');
    final contactLine = [email, phone]
        .where((s) => s.trim().isNotEmpty)
        .join('  •  ');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ProfileColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ProfileColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final compact = c.maxWidth < 720;
          final left = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: const BoxDecoration(
                  color: ProfileColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  ProfileFormatters.initials(name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        Text(
                          name.trim().isEmpty
                              ? '—'
                              : name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: ProfileColors.textDark,
                            letterSpacing: 0.2,
                          ),
                        ),
                        if (employeeCode.isNotEmpty)
                          _IdPill(code: employeeCode),
                        _StatusPill(status: status),
                      ],
                    ),
                    if (roleLine.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        roleLine,
                        style: const TextStyle(
                          fontSize: 13,
                          color: ProfileColors.textMedium,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (contactLine.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        contactLine,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: ProfileColors.textLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );

          final button = FilledButton(
            onPressed: onEditAll,
            style: FilledButton.styleFrom(
              backgroundColor: ProfileColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Edit Profile & Bank Details',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                left,
                const SizedBox(height: 16),
                button,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _IdPill extends StatelessWidget {
  final String code;
  const _IdPill({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ProfileColors.primaryLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'ID: $code',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: ProfileColors.primary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    Color fg = ProfileColors.success;
    Color bg = ProfileColors.successBg;
    if (s == 'on_leave') {
      fg = ProfileColors.warning;
      bg = ProfileColors.warningBg;
    } else if (s == 'terminated') {
      fg = ProfileColors.danger;
      bg = ProfileColors.dangerBg;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            ProfileFormatters.titleCase(s),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
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
    final mobile = MediaQuery.of(context).size.width < 700;

    final roleLine = [designation, department]
        .where((s) => s.trim().isNotEmpty)
        .join(' • ');

    return Container(
      padding: EdgeInsets.all(mobile ? 16 : 22),
      decoration: BoxDecoration(
        color: ProfileColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ProfileColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final compact = c.maxWidth < 720;
          final avatar = compact ? 54.0 : 66.0;

          final left = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: avatar,
                height: avatar,
                decoration: BoxDecoration(
                  color: ProfileColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ProfileColors.primaryLight,
                    width: 4,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  ProfileFormatters.initials(name),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: compact ? 18 : 22,
                  ),
                ),
              ),
              SizedBox(width: compact ? 12 : 18),
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
                          name.trim().isEmpty ? '—' : name.toUpperCase(),
                          style: TextStyle(
                            fontSize: compact ? 16 : 19,
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
                    if (email.trim().isNotEmpty ||
                        phone.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          if (email.trim().isNotEmpty)
                            _ContactItem(
                              icon: Icons.mail_outline_rounded,
                              text: email,
                            ),
                          if (phone.trim().isNotEmpty)
                            _ContactItem(
                              icon: Icons.phone_outlined,
                              text: phone,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );

          final button = FilledButton.icon(
            onPressed: onEditAll,
            icon: const Icon(Icons.edit_outlined, size: 17),
            label: const Text('Edit Profile & Bank Details'),
            style: FilledButton.styleFrom(
              backgroundColor: ProfileColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
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

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: ProfileColors.textLight),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              color: ProfileColors.textMedium,
            ),
          ),
        ),
      ],
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
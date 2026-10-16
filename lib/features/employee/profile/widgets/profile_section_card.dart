// lib/features/employee/profile/widgets/profile_section_card.dart

import 'package:flutter/material.dart';

import '../utils/profile_colors.dart';

enum ProfileCardActionStyle { link, tonal }

class ProfileSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final ProfileCardActionStyle actionStyle;
  final Widget child;

  /// Optional icon shown in a tinted box before the title.
  final IconData? icon;

  const ProfileSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionStyle = ProfileCardActionStyle.link,
    this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width < 700;
    final hasAction = actionLabel != null && onAction != null;

    final titleBlock = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: ProfileColors.primaryLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: ProfileColors.primary),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: ProfileColors.textDark,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: ProfileColors.textLight,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    Widget? action;
    if (hasAction) {
      action = actionStyle == ProfileCardActionStyle.link
          ? TextButton.icon(
        onPressed: onAction,
        icon: const Icon(Icons.edit_outlined, size: 15),
        label: Text(actionLabel!),
        style: TextButton.styleFrom(
          foregroundColor: ProfileColors.primary,
          backgroundColor: ProfileColors.primaryLight,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          textStyle: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      )
          : TextButton.icon(
        onPressed: onAction,
        icon: const Icon(Icons.edit_outlined, size: 15),
        label: Text(actionLabel!),
        style: TextButton.styleFrom(
          backgroundColor: ProfileColors.primaryLight,
          foregroundColor: ProfileColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 11,
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
    }

    // Phone: action goes under the title so nothing gets squeezed.
    final Widget header;
    if (action == null) {
      header = titleBlock;
    } else if (mobile) {
      header = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 12),
          action,
        ],
      );
    } else {
      header = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: titleBlock),
          const SizedBox(width: 12),
          action,
        ],
      );
    }

    return Container(
      padding: EdgeInsets.all(mobile ? 14 : 20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          SizedBox(height: mobile ? 14 : 16),
          const Divider(height: 1, color: ProfileColors.border),
          SizedBox(height: mobile ? 14 : 18),
          child,
        ],
      ),
    );
  }
}
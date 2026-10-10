// lib/features/employee/profile/widgets/profile_tab_personal.dart

import 'package:flutter/material.dart';

import '../models/employee_profile_details_model.dart';
import '../models/employee_profile_model.dart';
import '../utils/profile_colors.dart';
import '../utils/profile_formatters.dart';
import 'profile_grid.dart';
import 'profile_section_card.dart';

class ProfileTabPersonal extends StatelessWidget {
  final ProfileUser user;
  final PersonalDetails details;
  final VoidCallback onEditPersonal;
  final VoidCallback onEditEmergency;

  const ProfileTabPersonal({
    super.key,
    required this.user,
    required this.details,
    required this.onEditPersonal,
    required this.onEditEmergency,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileSectionCard(
          title: 'Personal Details',
          actionLabel: 'Edit Personal Info',
          onAction: onEditPersonal,
          child: ProfileGrid(
            items: [
              ProfileGridItem('Full Name', user.name),
              ProfileGridItem('Work Email', user.email),
              ProfileGridItem('Phone Number', user.phone),
              ProfileGridItem(
                'Date of Birth',
                ProfileFormatters.prettyDate(details.dob),
              ),
              ProfileGridItem(
                'Gender',
                ProfileFormatters.titleCase(details.gender),
              ),
              ProfileGridItem(
                'Marital Status',
                ProfileFormatters.titleCase(details.maritalStatus),
              ),
              ProfileGridItem('Blood Group', details.bloodGroup),
              ProfileGridItem(
                'Residential Address',
                details.address,
                fullWidth: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ProfileSectionCard(
          title: 'Emergency Contacts',
          actionLabel: 'Edit Emergency Contact',
          onAction: onEditEmergency,
          child: ProfileGrid(
            cellWidth: 260,
            items: [
              ProfileGridItem(
                'Primary Emergency Contact',
                details.emergencyContact,
                valueIsAccent: true,
              ),
              const ProfileGridItem(
                'Relationship / Note',
                'Primary Contact for Emergency Urgent Notifications',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
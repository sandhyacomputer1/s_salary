// lib/features/employee/profile/widgets/profile_tab_employment.dart

import 'package:flutter/material.dart';

import '../models/employee_profile_model.dart';
import '../utils/profile_colors.dart';
import '../utils/profile_formatters.dart';
import 'profile_grid.dart';
import 'profile_section_card.dart';

class ProfileTabEmployment extends StatelessWidget {
  final EmployeeDocument employee;
  final ProfileCompany? company;

  const ProfileTabEmployment({
    super.key,
    required this.employee,
    required this.company,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileSectionCard(
      title: 'Current Employment Information',
      child: ProfileGrid(
        items: [
          ProfileGridItem('Company', company?.name ?? ''),
          ProfileGridItem(
            'Employee Code ID',
            employee.employeeCode,
            valueIsAccent: true,
          ),
          ProfileGridItem('Designation', employee.designation),
          ProfileGridItem('Department', employee.department),
          ProfileGridItem(
            'Employment Type',
            ProfileFormatters.titleCase(employee.employmentType),
          ),
          ProfileGridItem('Portal System Role', 'Employee'),
          ProfileGridItem(
            'Employment Status',
            ProfileFormatters.titleCase(employee.status),
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
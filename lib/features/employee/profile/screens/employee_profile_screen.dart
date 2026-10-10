// lib/features/employee/profile/screens/employee_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/employee_profile_model.dart';
import '../repositories/employee_profile_repository.dart';
import '../utils/profile_colors.dart';
import '../widgets/edit_profile_dialog.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/profile_tab_bank.dart';
import '../widgets/profile_tab_employment.dart';
import '../widgets/profile_tab_expense_claims.dart';
import '../widgets/profile_tab_personal.dart';
import '../widgets/profile_tab_bar.dart';

class EmployeeProfileScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const EmployeeProfileScreen({super.key, this.embedded = false});

  @override
  ConsumerState<EmployeeProfileScreen> createState() =>
      _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState
    extends ConsumerState<EmployeeProfileScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(employeeProfileProvider);

    final body = profileAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: ProfileColors.primary),
      ),
      error: (err, _) => _ErrorState(
        message: err.toString().replaceFirst('Exception: ', ''),
        onRetry: () => ref.invalidate(employeeProfileProvider),
      ),
      data: (profile) => _Content(
        profile: profile,
        tabIndex: _tabIndex,
        onTabChanged: (i) => setState(() => _tabIndex = i),
        onEditAll: () => _openFullEdit(profile),
        onEditPersonal: () => _openFullEdit(profile, initialTab: 0),
        onEditEmergency: () => _openFullEdit(profile, initialTab: 0),
        onEditBank: () => _openFullEdit(profile, initialTab: 1),
      ),
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: ProfileColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ProfileColors.textDark),
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: ProfileColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      body: body,
    );
  }

  Future<void> _openFullEdit(
      EmployeeProfileModel profile, {
        int initialTab = 0,
      }) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => EditProfileDialog(
        profile: profile,
        initialTab: initialTab,
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final EmployeeProfileModel profile;
  final int tabIndex;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onEditAll;
  final VoidCallback onEditPersonal;
  final VoidCallback onEditEmergency;
  final VoidCallback onEditBank;

  const _Content({
    required this.profile,
    required this.tabIndex,
    required this.onTabChanged,
    required this.onEditAll,
    required this.onEditPersonal,
    required this.onEditEmergency,
    required this.onEditBank,
  });

  @override
  Widget build(BuildContext context) {
    final emp = profile.employee;
    final user = profile.user;

    Widget tabBody;
    switch (tabIndex) {
      case 0:
        tabBody = ProfileTabPersonal(
          user: user,
          details: emp.personalDetails,
          onEditPersonal: onEditPersonal,
          onEditEmergency: onEditEmergency,
        );
        break;
      case 1:
        tabBody = ProfileTabBank(
          details: emp.bankDetails,
          onUpdate: onEditBank,
        );
        break;
      case 2:
        tabBody = ProfileTabEmployment(
          employee: emp,
          company: profile.company,
        );
        break;
      case 3:
      default:
        tabBody = const ProfileTabExpenseClaims();
        break;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileHeaderCard(
                name: user.name,
                email: user.email,
                phone: user.phone,
                employeeCode: emp.employeeCode,
                designation: emp.designation,
                department: emp.department,
                status: emp.status,
                onEditAll: onEditAll,
              ),
              const SizedBox(height: 20),
              ProfileTabBar(
                selectedIndex: tabIndex,
                onChanged: onTabChanged,
              ),
              const SizedBox(height: 20),
              tabBody,
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: ProfileColors.primary, size: 40),
            const SizedBox(height: 12),
            Text(
              message.isEmpty ? 'Failed to load profile.' : message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: ProfileColors.textMedium,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: ProfileColors.primary,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
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

const double _mobileBreakpoint = 700;

/// Max width of the page content.
/// double.infinity = fill the screen. Use e.g. 1400 to limit it on
/// very large monitors.
const double _maxContentWidth = double.infinity;

const Color _border = Color(0xFFE5E7EB);

const List<BoxShadow> _cardShadow = [
  BoxShadow(
    color: Color(0x06000000),
    blurRadius: 10,
    offset: Offset(0, 3),
  ),
];

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

  Future<void> _refresh() async {
    ref.invalidate(employeeProfileProvider);
    try {
      await ref.read(employeeProfileProvider.future);
    } catch (_) {
      // The error state is shown by the provider itself.
    }
  }

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
      data: (profile) => RefreshIndicator(
        color: ProfileColors.primary,
        onRefresh: _refresh,
        child: _Content(
          profile: profile,
          tabIndex: _tabIndex,
          onTabChanged: (i) => setState(() => _tabIndex = i),
          onEditAll: () => _openFullEdit(profile),
          onEditPersonal: () => _openFullEdit(profile, initialTab: 0),
          onEditEmergency: () => _openFullEdit(profile, initialTab: 0),
          onEditBank: () => _openFullEdit(profile, initialTab: 1),
        ),
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
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: profileAsync.isLoading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
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

// ==============================================================
// CONTENT
// ==============================================================

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
    final mobile = MediaQuery.of(context).size.width < _mobileBreakpoint;

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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        mobile ? 14 : 22,
        mobile ? 16 : 22,
        mobile ? 14 : 22,
        32,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
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
              SizedBox(height: mobile ? 14 : 20),
              _TabMenu(
                selectedIndex: tabIndex,
                onChanged: onTabChanged,
                mobile: mobile,
              ),
              SizedBox(height: mobile ? 14 : 20),
              tabBody,
            ],
          ),
        ),
      ),
    );
  }
}

// ==============================================================
// TAB MENU (pill style, separate card)
//
// Index order must match the switch in _Content:
// 0 Personal, 1 Bank, 2 Employment, 3 Expense Claims
// ==============================================================

class _TabMenu extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool mobile;

  const _TabMenu({
    required this.selectedIndex,
    required this.onChanged,
    required this.mobile,
  });

  static const List<String> _labels = [
    'Personal Details',
    'Bank Details',
    'Employment',
    'Expense Claims',
  ];

  static const List<String> _labelsShort = [
    'Personal',
    'Bank',
    'Employment',
    'Claims',
  ];

  static const List<IconData> _icons = [
    Icons.person_outline_rounded,
    Icons.account_balance_outlined,
    Icons.work_outline_rounded,
    Icons.receipt_long_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final labels = mobile ? _labelsShort : _labels;

    final pills = [
      for (var i = 0; i < labels.length; i++) _pill(i, labels[i]),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 6 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: _cardShadow,
      ),
      child: mobile
      // Phone: scrolls sideways if the pills do not fit.
          ? SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < pills.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              pills[i],
            ],
          ],
        ),
      )
      // Tablet / web: pills share the full width evenly.
          : Row(
        children: [
          for (var i = 0; i < pills.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: pills[i]),
          ],
        ],
      ),
    );
  }

  Widget _pill(int index, String label) {
    final selected = selectedIndex == index;
    final fg = selected ? Colors.white : const Color(0xFF596273);

    return Material(
      color: selected ? ProfileColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onChanged(index),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 12 : 16,
            vertical: mobile ? 9 : 12,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_icons[index], size: 17, color: fg),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: mobile ? 12.5 : 13.5,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==============================================================
// ERROR STATE
// ==============================================================

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
          boxShadow: _cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFDC2626),
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to load profile',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: ProfileColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message.isEmpty ? 'Failed to load profile.' : message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: ProfileColors.textMedium,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: ProfileColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
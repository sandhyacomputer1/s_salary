import 'package:flutter/material.dart';

// ⚠️ Fix to your real AppRoutes location.

import '../../../../core/routes/app_routes.dart';
import '../models/expense_claim_model.dart';
import '../repositories/expense_claim_repository.dart';
import '../utils/expense_colors.dart';
import '../widgets/expense_claim_card.dart';
import '../widgets/expense_claim_empty_state.dart';

class EmployeeExpenseClaimsScreen extends StatefulWidget {
  const EmployeeExpenseClaimsScreen({super.key});

  @override
  State<EmployeeExpenseClaimsScreen> createState() =>
      _EmployeeExpenseClaimsScreenState();
}

class _EmployeeExpenseClaimsScreenState
    extends State<EmployeeExpenseClaimsScreen> {
  static const double _mobileBreakpoint = 700;

  /// Max width of the content on wide screens.
  /// double.infinity = fill the screen. Use e.g. 1200 to limit it.
  static const double _maxContentWidth = double.infinity;

  final ExpenseClaimRepository _repository = ExpenseClaimRepository();

  List<ExpenseClaimModel> _claims = [];
  bool _loading = true;
  String? _error;
  ExpenseClaimStatus? _filter; // null = All

  static const List<ExpenseClaimStatus> _filterOptions = [
    ExpenseClaimStatus.pending,
    ExpenseClaimStatus.approved,
    ExpenseClaimStatus.rejected,
    ExpenseClaimStatus.reimbursed,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await _repository.getMyClaims();
      if (!mounted) return;
      setState(() {
        _claims = result.claims;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _goToSubmit() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(); // back to the submit screen
    } else {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.employeeSubmitExpenseClaim,
      );
    }
  }

  List<ExpenseClaimModel> get _visibleClaims => _filter == null
      ? _claims
      : _claims.where((c) => c.status == _filter).toList();

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width < _mobileBreakpoint;

    return Scaffold(
      backgroundColor: ExpenseColors.background,
      appBar: AppBar(
        title: const Text(
          'My Expense Claims',
          style: TextStyle(
            color: ExpenseColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: ExpenseColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : () => _load(showSpinner: false),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        color: ExpenseColors.primary,
        onRefresh: () => _load(showSpinner: false),
        child: _buildBody(mobile),
      ),
      bottomNavigationBar: _buildBottomBar(mobile),
    );
  }

  // ==========================================================
  // BOTTOM BAR
  // ==========================================================

  Widget _buildBottomBar(bool mobile) {
    final button = FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: ExpenseColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: _goToSubmit,
      icon: const Icon(Icons.add, size: 20),
      label: const Text(
        'Submit New Claim',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: ExpenseColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(mobile ? 14 : 22, 10, mobile ? 14 : 22, 10),
          child: mobile
              ? button
              : Align(
            alignment: Alignment.centerRight,
            heightFactor: 1,
            child: SizedBox(width: 260, child: button),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BODY
  // ==========================================================

  Widget _buildBody(bool mobile) {
    final padding = EdgeInsets.fromLTRB(
      mobile ? 14 : 22,
      mobile ? 16 : 22,
      mobile ? 14 : 22,
      28,
    );

    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 160),
          Center(
            child: CircularProgressIndicator(color: ExpenseColors.primary),
          ),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: [
          const SizedBox(height: 40),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: ExpenseColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ExpenseColors.border),
                boxShadow: ExpenseColors.cardShadow,
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
                      size: 30,
                      color: ExpenseColors.danger,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Could not load your claims',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: ExpenseColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: ExpenseColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ExpenseColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_claims.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ExpenseClaimEmptyState(
            title: 'No expense claims yet',
            message: 'Claims you submit will appear here with their status.',
            actionLabel: 'Submit your first claim',
            onAction: _goToSubmit,
          ),
        ],
      );
    }

    final visible = _visibleClaims;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(mobile),
                SizedBox(height: mobile ? 14 : 20),
                _buildFilterMenu(mobile),
                SizedBox(height: mobile ? 12 : 16),
                if (visible.isEmpty)
                  _buildNoResults()
                else
                  ...visible.map((c) => ExpenseClaimCard(claim: c)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // PAGE HEADER
  // ==========================================================

  Widget _buildHeader(bool mobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Claim History',
          style: TextStyle(
            fontSize: mobile ? 22 : 27,
            fontWeight: FontWeight.w700,
            color: ExpenseColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _claims.length == 1
              ? '1 claim submitted by you.'
              : '${_claims.length} claims submitted by you.',
          style: TextStyle(
            fontSize: mobile ? 13 : 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // FILTER MENU (pill style, separate card)
  // ==========================================================

  Widget _buildFilterMenu(bool mobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 6 : 8),
      decoration: BoxDecoration(
        color: ExpenseColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ExpenseColors.border),
        boxShadow: ExpenseColors.cardShadow,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterPill(
              'All',
              _claims.length,
              _filter == null,
                  () => setState(() => _filter = null),
              mobile,
            ),
            for (final s in _filterOptions)
              _filterPill(
                s.label,
                _claims.where((c) => c.status == s).length,
                _filter == s,
                    () => setState(() => _filter = s),
                mobile,
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterPill(
      String label,
      int count,
      bool selected,
      VoidCallback onTap,
      bool mobile,
      ) {
    final fg = selected ? Colors.white : ExpenseColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: selected ? ExpenseColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 12 : 16,
              vertical: mobile ? 9 : 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: mobile ? 12.5 : 13.5,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withOpacity(0.22)
                        : ExpenseColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: ExpenseColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ExpenseColors.border),
      ),
      child: Center(
        child: Text(
          'No ${_filter?.label.toLowerCase() ?? ''} claims',
          style: const TextStyle(
            fontSize: 14,
            color: ExpenseColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
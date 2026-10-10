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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExpenseColors.background,
      appBar: AppBar(
        title: const Text('My Expense Claims'),
        backgroundColor: Colors.white,
        foregroundColor: ExpenseColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        color: ExpenseColors.primary,
        onRefresh: () => _load(showSpinner: false),
        child: _buildBody(),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: ExpenseColors.border)),
          ),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: ExpenseColors.primary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _goToSubmit,
            icon: const Icon(Icons.add),
            label: const Text(
              'Submit New Claim',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 160),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: Color(0xFFC62828)),
                const SizedBox(height: 12),
                const Text(
                  'Could not load your claims',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: ExpenseColors.textSecondary),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
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
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _claims.length == 1 ? '1 claim' : '${_claims.length} claims',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ExpenseColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip('All', _claims.length, _filter == null,
                      () => setState(() => _filter = null)),
              for (final s in _filterOptions)
                _chip(
                  s.label,
                  _claims.where((c) => c.status == s).length,
                  _filter == s,
                      () => setState(() => _filter = s),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No ${_filter?.label.toLowerCase() ?? ''} claims',
                style: const TextStyle(color: ExpenseColors.textSecondary),
              ),
            ),
          )
        else
          ...visible.map((c) => ExpenseClaimCard(claim: c)),
      ],
    );
  }

  Widget _chip(String label, int count, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$label ($count)'),
        selected: selected,
        showCheckmark: false,
        selectedColor: ExpenseColors.primaryTint,
        side: BorderSide(
          color: selected ? ExpenseColors.primary : ExpenseColors.border,
        ),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color:
          selected ? ExpenseColors.primary : ExpenseColors.textSecondary,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
// lib/features/employee/expense_claims/screens/employee_submit_expense_claim_screen.dart

import 'package:flutter/material.dart';

// ⚠️ Fix to your real AppRoutes location.
import '../../../../core/routes/app_routes.dart';
import '../models/expense_claim_model.dart';
import '../repositories/expense_claim_repository.dart';
import '../utils/expense_colors.dart';
import '../widgets/expense_claim_form.dart';
import '../widgets/expense_claim_summary_strip.dart';

class EmployeeSubmitExpenseClaimScreen extends StatefulWidget {
  /// When true, this screen is rendered inside the dashboard shell,
  /// which already provides the Scaffold and AppBar.
  final bool embedded;

  /// When embedded, the shell passes this so the "View All Claims"
  /// button can swap the content area instead of pushing a new route.
  final VoidCallback? onViewAllClaims;

  const EmployeeSubmitExpenseClaimScreen({
    super.key,
    this.embedded = false,
    this.onViewAllClaims,
  });

  @override
  State<EmployeeSubmitExpenseClaimScreen> createState() =>
      _EmployeeSubmitExpenseClaimScreenState();
}

class _EmployeeSubmitExpenseClaimScreenState
    extends State<EmployeeSubmitExpenseClaimScreen> {
  static const double _mobileBreakpoint = 700;

  /// Max width of the content on wide screens.
  /// double.infinity = fill the screen. Use e.g. 1200 to limit it.
  static const double _maxContentWidth = double.infinity;

  final ExpenseClaimRepository _repository = ExpenseClaimRepository();

  bool _isSubmitting = false;
  bool _summaryLoading = true;
  List<ExpenseClaimModel> _claims = [];
  bool _summaryLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary({bool showLoader = true}) async {
    if (showLoader && mounted) setState(() => _summaryLoading = true);
    try {
      final result = await _repository.getMyClaims();
      if (!mounted) return;
      setState(() {
        _claims = result.claims;
        _summaryLoaded = true;
        _summaryLoading = false;
      });
    } catch (_) {
      // Summary is secondary; the form must stay usable.
      if (!mounted) return;
      setState(() => _summaryLoading = false);
    }
  }

  Future<bool> _handleSubmit({
    required String category,
    required double amount,
    required DateTime expenseDate,
    required String description,
    String? billUrl,
  }) async {
    if (_isSubmitting) return false;
    setState(() => _isSubmitting = true);

    try {
      await _repository.submitClaim(
        category: category,
        amount: amount,
        expenseDate: expenseDate,
        description: description,
        billUrl: billUrl,
      );

      if (!mounted) return true; // server accepted it
      _showSnack('Expense claim submitted successfully', isError: false);
      _loadSummary(showLoader: false);
      return true;
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
          isError ? ExpenseColors.danger : ExpenseColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openAllClaims() async {
    // Embedded: let the dashboard shell swap the content area
    // (keeps the sidebar + selected menu item visible).
    if (widget.onViewAllClaims != null) {
      widget.onViewAllClaims!.call();
      return;
    }

    // Standalone: push the named route as a full page.
    await Navigator.pushNamed(context, AppRoutes.employeeExpenseClaims);
    if (mounted) _loadSummary(showLoader: false);
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width < _mobileBreakpoint;

    // Body only — no Scaffold. The parent (dashboard shell or Profile tab)
    // owns the Scaffold, AppBar and background.
    final content = SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          mobile ? 14 : 22,
          mobile ? 16 : 22,
          mobile ? 14 : 22,
          28,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_summaryLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: ExpenseColors.primary,
                      backgroundColor: ExpenseColors.primaryTint,
                    ),
                  )
                else if (_summaryLoaded) ...[
                  ExpenseClaimSummaryStrip(items: _summaryItems()),
                  SizedBox(height: mobile ? 14 : 20),
                ],
                _buildFormCard(mobile),
                SizedBox(height: mobile ? 14 : 16),
                _buildViewAllButton(mobile),
              ],
            ),
          ),
        ),
      ),
    );

    // When embedded, return body only. The parent shell already provides
    // the Scaffold, so nesting another Scaffold here breaks layout
    // (unlaid-out _ScaffoldSlot.floatingActionButton → blank screen).
    if (widget.embedded) return content;

    // Standalone: own the Scaffold and AppBar.
    return Scaffold(
      backgroundColor: ExpenseColors.background,
      appBar: AppBar(
        title: const Text(
          'Submit Expense Claim',
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
      ),
      body: content,
    );
  }

  // ==========================================================
  // SUMMARY (computed from the claims list)
  // ==========================================================

  ExpenseSummaryItem _summaryItem(
      String label,
      ExpenseClaimStatus? status,
      IconData icon,
      Color color,
      ) {
    final list = status == null
        ? _claims
        : _claims.where((c) => c.status == status).toList();

    var total = 0.0;
    for (final c in list) {
      total += c.amount.toDouble();
    }

    return ExpenseSummaryItem(
      label: label,
      amount: total,
      count: list.length,
      icon: icon,
      color: color,
    );
  }

  List<ExpenseSummaryItem> _summaryItems() {
    return [
      _summaryItem(
        'Total Claimed',
        null,
        Icons.receipt_long_outlined,
        ExpenseColors.primary,
      ),
      _summaryItem(
        'Pending',
        ExpenseClaimStatus.pending,
        Icons.schedule_rounded,
        const Color(0xFFB26A00),
      ),
      _summaryItem(
        'Approved',
        ExpenseClaimStatus.approved,
        Icons.check_circle_outline_rounded,
        ExpenseColors.success,
      ),
      _summaryItem(
        'Reimbursed',
        ExpenseClaimStatus.reimbursed,
        Icons.payments_outlined,
        const Color(0xFF2563EB),
      ),
      _summaryItem(
        'Rejected',
        ExpenseClaimStatus.rejected,
        Icons.cancel_outlined,
        ExpenseColors.danger,
      ),
    ];
  }

  // ==========================================================
  // FORM CARD
  // ==========================================================

  Widget _buildFormCard(bool mobile) {
    return Container(
      padding: EdgeInsets.all(mobile ? 14 : 20),
      decoration: BoxDecoration(
        color: ExpenseColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ExpenseColors.border),
        boxShadow: ExpenseColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: ExpenseColors.primaryTint,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 18,
                  color: ExpenseColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Expense Claim',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ExpenseColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Fill in the details to request reimbursement.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: ExpenseColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: mobile ? 14 : 18),
          const Divider(height: 1, color: Color(0xFFEDEFF3)),
          SizedBox(height: mobile ? 14 : 18),
          ExpenseClaimForm(
            isSubmitting: _isSubmitting,
            onSubmit: _handleSubmit,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // VIEW ALL CLAIMS
  // ==========================================================

  Widget _buildViewAllButton(bool mobile) {
    final button = OutlinedButton.icon(
      onPressed: _isSubmitting ? null : _openAllClaims,
      icon: const Icon(Icons.list_alt_outlined, size: 18),
      label: const Text('View All Claims'),
      style: OutlinedButton.styleFrom(
        foregroundColor: ExpenseColors.primary,
        side: const BorderSide(color: ExpenseColors.primary),
        minimumSize: Size(mobile ? double.infinity : 200, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    if (mobile) return button;

    return Align(
      alignment: Alignment.centerRight,
      child: button,
    );
  }
}
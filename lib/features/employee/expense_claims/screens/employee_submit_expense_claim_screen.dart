// lib/features/employee/expense_claims/screens/employee_submit_expense_claim_screen.dart

import 'package:flutter/material.dart';

// ⚠️ Fix to your real AppRoutes location.
import '../../../../core/routes/app_routes.dart';
import '../models/expense_claim_summary_model.dart';
import '../repositories/expense_claim_repository.dart';
import '../utils/expense_colors.dart';
import '../widgets/expense_claim_form.dart';
import '../widgets/expense_claim_summary_cards.dart';

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
  final ExpenseClaimRepository _repository = ExpenseClaimRepository();

  bool _isSubmitting = false;
  bool _summaryLoading = true;
  ExpenseClaimSummaryModel? _summary;

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
        _summary = result.summary;
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
          isError ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
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

  @override
  Widget build(BuildContext context) {
    // Body only — no Scaffold. The parent (dashboard shell or Profile tab)
    // owns the Scaffold, AppBar and background.
    final content = SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_summaryLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(minHeight: 3),
              )
            else if (_summary != null) ...[
              ExpenseClaimSummaryCards(summary: _summary!),
              const SizedBox(height: 20),
            ],
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ExpenseColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New Expense Claim',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ExpenseColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Fill in the details to request reimbursement.',
                    style: TextStyle(
                      fontSize: 13,
                      color: ExpenseColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ExpenseClaimForm(
                    isSubmitting: _isSubmitting,
                    onSubmit: _handleSubmit,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: ExpenseColors.primary,
                side: const BorderSide(color: ExpenseColors.primary),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isSubmitting ? null : _openAllClaims,
              icon: const Icon(Icons.list_alt_outlined),
              label: const Text(
                'View All Claims',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
          ],
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
        title: const Text('Submit Expense Claim'),
        backgroundColor: Colors.white,
        foregroundColor: ExpenseColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: content,
    );
  }
}
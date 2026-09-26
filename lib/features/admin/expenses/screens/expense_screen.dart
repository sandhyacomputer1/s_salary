import 'package:flutter/material.dart';

import '../models/expense_model.dart';
import '../services/expense_service.dart';
import '../widgets/expense_card.dart';
import 'expense_details_screen.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final ExpenseService _service = ExpenseService();

  List<ExpenseModel> _expenses = [];
  bool _isLoading = true;
  String? _error;

  String _searchQuery = '';
  String _selectedStatus = 'All';

  static const Color primary = Color(0xFFE96832);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFE1E5EA);

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _service.getExpenses();

      if (!mounted) return;

      setState(() {
        _expenses = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<ExpenseModel> get _filteredExpenses {
    return _expenses.where((expense) {
      final query = _searchQuery.toLowerCase();

      final matchesSearch =
          expense.category.toLowerCase().contains(query) ||
              expense.employeeCode.toLowerCase().contains(query) ||
              expense.description.toLowerCase().contains(query);

      final matchesStatus = _selectedStatus == 'All' ||
          expense.status.toLowerCase() == _selectedStatus.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get _pendingCount {
    return _expenses
        .where((e) => e.status.toLowerCase() == 'pending')
        .length;
  }

  int get _approvedCount {
    return _expenses
        .where((e) => e.status.toLowerCase() == 'approved')
        .length;
  }

  int get _rejectedCount {
    return _expenses
        .where((e) => e.status.toLowerCase() == 'rejected')
        .length;
  }

  double get _totalAmount {
    return _expenses.fold(
      0,
          (sum, expense) => sum + expense.amount,
    );
  }

  Future<void> _approveExpense(ExpenseModel expense) async {
    try {
      await _service.approveExpense(expense.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense approved successfully'),
        ),
      );

      await _loadExpenses();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve expense: $e'),
        ),
      );
    }
  }

  // NOTE: Rejection is intentionally NOT wired up — there is no
  // reject endpoint in the API spec (/expenses/:id/reject does not
  // exist). Provide that endpoint and this can be added back.

  void _openDetails(ExpenseModel expense) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExpenseDetailsScreen(
          expense: expense,
          onApprove: () async {
            await _approveExpense(expense);
          },
        ),
      ),
    );

    if (mounted) {
      _loadExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Expenses',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadExpenses,
            icon: const Icon(
              Icons.refresh_rounded,
              color: textDark,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        key: const ValueKey('error'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to load expenses',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textMedium,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadExpenses,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      key: const ValueKey('content'),
      onRefresh: _loadExpenses,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildSummary(),
          const SizedBox(height: 20),
          _buildSearchAndFilter(),
          const SizedBox(height: 20),
          _buildExpenseList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Expense Management',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Review and manage employee expense claims.',
                style: TextStyle(
                  fontSize: 13,
                  color: textMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        _SummaryCard(
          title: 'Total Claims',
          value: '${_expenses.length}',
          icon: Icons.receipt_long_outlined,
          iconBackground: const Color(0xFFFFEEE7),
          iconColor: primary,
        ),
        _SummaryCard(
          title: 'Pending',
          value: '$_pendingCount',
          icon: Icons.pending_actions_rounded,
          iconBackground: const Color(0xFFFFF4D6),
          iconColor: const Color(0xFFD99000),
        ),
        _SummaryCard(
          title: 'Approved',
          value: '$_approvedCount',
          icon: Icons.check_circle_outline_rounded,
          iconBackground: const Color(0xFFE7F7EF),
          iconColor: const Color(0xFF159957),
        ),
        _SummaryCard(
          title: 'Rejected',
          value: '$_rejectedCount',
          icon: Icons.cancel_outlined,
          iconBackground: const Color(0xFFFFE8E8),
          iconColor: const Color(0xFFD64545),
        ),
        _SummaryCard(
          title: 'Total Amount',
          value: '₹${_formatAmount(_totalAmount)}',
          icon: Icons.currency_rupee_rounded,
          iconBackground: const Color(0xFFE9F0FF),
          iconColor: const Color(0xFF2563EB),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 600;

          final search = TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search employee, category or description...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: const Color(0xFFF8F9FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: BorderSide.none,
              ),
            ),
          );

          final filter = DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: InputDecoration(
              labelText: 'Status',
              filled: true,
              fillColor: const Color(0xFFF8F9FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'All',
                child: Text('All Status'),
              ),
              DropdownMenuItem(
                value: 'pending',
                child: Text('Pending'),
              ),
              DropdownMenuItem(
                value: 'approved',
                child: Text('Approved'),
              ),
              DropdownMenuItem(
                value: 'rejected',
                child: Text('Rejected'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _selectedStatus = value;
              });
            },
          );

          if (isSmall) {
            return Column(
              children: [
                search,
                const SizedBox(height: 12),
                filter,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: filter,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExpenseList() {
    final expenses = _filteredExpenses;

    if (expenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: textLight,
            ),
            SizedBox(height: 12),
            Text(
              'No expenses found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textDark,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < expenses.length; i++)
          ExpenseCard(
            key: ValueKey(expenses[i].id),
            expense: expenses[i],
            index: i,
            onTap: () => _openDetails(expenses[i]),
            onApprove: expenses[i].status.toLowerCase() == 'pending'
                ? () => _approveExpense(expenses[i])
                : null,
          ),
      ],
    );
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2);
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 185,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE1E5EA),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF8A93A1),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    value,
                    key: ValueKey(value),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF18212F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
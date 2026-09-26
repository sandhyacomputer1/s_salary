import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/expense_model.dart';

class ExpenseDetailsScreen extends StatefulWidget {
  final ExpenseModel expense;
  final Future<void> Function()? onApprove;

  const ExpenseDetailsScreen({
    super.key,
    required this.expense,
    this.onApprove,
  });

  @override
  State<ExpenseDetailsScreen> createState() => _ExpenseDetailsScreenState();
}

class _ExpenseDetailsScreenState extends State<ExpenseDetailsScreen>
    with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFFE96832);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFE1E5EA);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _fadeFor(double start, double end) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  Animation<Offset> _slideFor(double start, double end) {
    return Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  Widget _animatedSection({
    required double start,
    required double end,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: _fadeFor(start, end),
      child: SlideTransition(
        position: _slideFor(start, end),
        child: child,
      ),
    );
  }

  Future<void> _openBill(BuildContext context) async {
    final url = widget.expense.billUrl;

    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No bill attached to this expense'),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid bill URL'),
        ),
      );
      return;
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open bill'),
        ),
      );
    }
  }

  Future<void> _approve(BuildContext context) async {
    if (widget.onApprove == null) return;

    await widget.onApprove!();

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expense = widget.expense;
    final isPending = expense.status.toLowerCase() == 'pending';
    final hasBill = expense.billUrl.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Expense Details',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(
          color: textDark,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 850,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _animatedSection(
                  start: 0.0,
                  end: 0.45,
                  child: _buildTopCard(expense),
                ),
                const SizedBox(height: 16),
                _animatedSection(
                  start: 0.1,
                  end: 0.55,
                  child: _buildExpenseInformation(expense),
                ),
                const SizedBox(height: 16),
                _animatedSection(
                  start: 0.2,
                  end: 0.65,
                  child: _buildTimeline(expense),
                ),
                if (hasBill) ...[
                  const SizedBox(height: 16),
                  _animatedSection(
                    start: 0.3,
                    end: 0.75,
                    child: _buildBillCard(context, expense),
                  ),
                ],
                if (isPending && widget.onApprove != null) ...[
                  const SizedBox(height: 20),
                  _animatedSection(
                    start: 0.4,
                    end: 0.9,
                    child: _buildActions(context),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopCard(ExpenseModel expense) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Hero(
            tag: 'expense-avatar-${expense.id}',
            child: Material(
              color: Colors.transparent,
              child: CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFFFEEE7),
                child: Text(
                  expense.employeeCode == '—'
                      ? '?'
                      : expense.employeeCode
                      .replaceAll('EMP-', '')
                      .characters
                      .first,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Employee Expense Claim',
                  style: TextStyle(
                    fontSize: 12,
                    color: textLight,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  expense.employeeCode,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
          _StatusBadge(status: expense.status),
        ],
      ),
    );
  }

  Widget _buildExpenseInformation(ExpenseModel expense) {
    return _SectionCard(
      title: 'Expense Information',
      icon: Icons.receipt_long_outlined,
      children: [
        _DetailRow(label: 'Employee Code', value: expense.employeeCode),
        _DetailRow(label: 'Category', value: expense.category),
        _DetailRow(
          label: 'Amount',
          value: '₹${expense.amount.toStringAsFixed(2)}',
          valueBold: true,
        ),
        _DetailRow(
          label: 'Expense Date',
          value: _formatDate(expense.expenseDate),
        ),
        _DetailRow(label: 'Status', value: expense.status),
        _DetailRow(
          label: 'Description',
          value: expense.description.isEmpty
              ? 'No description provided'
              : expense.description,
        ),
      ],
    );
  }

  Widget _buildTimeline(ExpenseModel expense) {
    return _SectionCard(
      title: 'Expense Timeline',
      icon: Icons.timeline_rounded,
      children: [
        _DetailRow(
          label: 'Submitted At',
          value: _formatDateTime(expense.submittedAt),
        ),
        _DetailRow(
          label: 'Created At',
          value: _formatDateTime(expense.createdAt),
        ),
        if (expense.actionedAt != null)
          _DetailRow(
            label: 'Actioned At',
            value: _formatDateTime(expense.actionedAt),
          ),
        if (expense.approvedBy.trim().isNotEmpty)
          _DetailRow(
            label: 'Approved / Actioned By',
            value: expense.approvedBy,
          ),
      ],
    );
  }

  Widget _buildBillCard(BuildContext context, ExpenseModel expense) {
    return _SectionCard(
      title: 'Supporting Bill',
      icon: Icons.description_outlined,
      children: [
        Row(
          children: [
            const Icon(
              Icons.attach_file_rounded,
              color: primary,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Bill / supporting document attached',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _openBill(context),
              icon: const Icon(
                Icons.open_in_new_rounded,
                size: 16,
              ),
              label: const Text('Open Bill'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _approve(context),
        icon: const Icon(Icons.check_rounded),
        label: const Text('Approve Expense'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF159957),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';

    return '${date.day.toString().padLeft(2, '0')} '
        '${_month(date.month)} ${date.year}';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return '-';

    return '${_formatDate(date)} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _month(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return months[month - 1];
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE1E5EA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: const Color(0xFFE96832),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF18212F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool valueBold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 155,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF8A93A1),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: valueBold ? FontWeight.w800 : FontWeight.w600,
                color: const Color(0xFF18212F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    final isApproved = normalized == 'approved';
    final isRejected = normalized == 'rejected';

    final background = isApproved
        ? const Color(0xFFE7F7EF)
        : isRejected
        ? const Color(0xFFFFE8E8)
        : const Color(0xFFFFF4D6);

    final foreground = isApproved
        ? const Color(0xFF159957)
        : isRejected
        ? const Color(0xFFD64545)
        : const Color(0xFFD99000);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}
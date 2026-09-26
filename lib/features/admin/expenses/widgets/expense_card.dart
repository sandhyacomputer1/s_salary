import 'package:flutter/material.dart';

import '../models/expense_model.dart';

class ExpenseCard extends StatefulWidget {
  final ExpenseModel expense;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final int index;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
    this.onApprove,
    this.index = 0,
  });

  @override
  State<ExpenseCard> createState() => _ExpenseCardState();
}

class _ExpenseCardState extends State<ExpenseCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool _pressed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    final delay = Duration(milliseconds: 40 * widget.index.clamp(0, 10));

    Future.delayed(delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expense = widget.expense;
    final bool isPending = expense.status.toLowerCase() == 'pending';

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: Colors.grey.shade200,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: widget.onTap,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapCancel: () => setState(() => _pressed = false),
              onTapUp: (_) => setState(() => _pressed = false),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =====================================================
                    // TOP ROW
                    // =====================================================
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: 'expense-avatar-${expense.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFFFFEEE7),
                              child: Text(
                                expense.employeeCode == '—'
                                    ? '?'
                                    : expense.employeeCode
                                    .replaceAll('EMP-', '')
                                    .characters
                                    .first,
                                style: const TextStyle(
                                  color: Color(0xFFE96832),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense.category,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                expense.employeeCode,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _StatusBadge(status: expense.status),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // =====================================================
                    // AMOUNT
                    // =====================================================
                    Row(
                      children: [
                        const Icon(
                          Icons.currency_rupee_rounded,
                          size: 19,
                          color: Color(0xFF111827),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          _formatAmount(expense.amount),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // =====================================================
                    // DATE
                    // =====================================================
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          _formatDate(expense.expenseDate),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),

                    // =====================================================
                    // DESCRIPTION
                    // =====================================================
                    if (expense.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        expense.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],

                    // =====================================================
                    // BILL
                    // =====================================================
                    if (expense.billUrl.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 17,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'Bill attached',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // =====================================================
                    // APPROVE ACTION
                    // (Reject removed: no reject endpoint exists yet)
                    // =====================================================
                    if (isPending && widget.onApprove != null) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.onApprove,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text(
                            'Approve',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF36C32),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    final double value = amount is num
        ? amount.toDouble()
        : double.tryParse(amount.toString()) ?? 0;

    return value.toStringAsFixed(
      value.truncateToDouble() == value ? 0 : 2,
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();

    return '$day/$month/$year';
  }
}

// =================================================================
// STATUS BADGE
// =================================================================

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final String value = status.toLowerCase();

    Color background;
    Color foreground;
    IconData icon;

    switch (value) {
      case 'approved':
        background = const Color(0xFFE8F7EE);
        foreground = const Color(0xFF15803D);
        icon = Icons.check_circle_outline_rounded;
        break;

      case 'rejected':
        background = const Color(0xFFFDECEC);
        foreground = const Color(0xFFDC2626);
        icon = Icons.cancel_outlined;
        break;

      case 'pending':
      default:
        background = const Color(0xFFFFF4E8);
        foreground = const Color(0xFFEA580C);
        icon = Icons.pending_outlined;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: foreground,
          ),
          const SizedBox(width: 5),
          Text(
            status.isEmpty
                ? 'Unknown'
                : status[0].toUpperCase() +
                status.substring(1).toLowerCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
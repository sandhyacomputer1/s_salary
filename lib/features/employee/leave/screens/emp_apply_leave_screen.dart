import 'dart:async';

import 'package:flutter/material.dart';

import '../models/emp_leave_balance_model.dart';
import '../models/emp_leave_model.dart';
import '../services/emp_leave_service.dart';
import '../widgets/emp_leave_balance_card.dart';
import '../widgets/emp_leave_form.dart';
import '../widgets/emp_leave_history_card.dart';

class EmpApplyLeaveScreen extends StatefulWidget {
  /// Set to true when shown inside the employee shell (no AppBar of its own).
  final bool embedded;

  const EmpApplyLeaveScreen({super.key, this.embedded = false});

  @override
  State<EmpApplyLeaveScreen> createState() => _EmpApplyLeaveScreenState();
}

class _EmpApplyLeaveScreenState extends State<EmpApplyLeaveScreen> {
  final EmpLeaveService _service = EmpLeaveService();
  final ScrollController _scrollController = ScrollController();

  List<EmpLeaveBalanceModel> _balances = [];
  List<EmpLeaveModel> _history = [];

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showSuccess = false;

  String? _balancesError;
  String? _historyError;

  Timer? _successTimer;

  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFE1E5EA);
  static const Color success = Color(0xFF159957);
  static const Color successLight = Color(0xFFE7F7EF);

  static const double _maxContentWidth = 1100;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _successTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // DATA
  // ============================================================

  String _messageOf(Object e) {
    if (e is EmpLeaveException) return e.message;
    return 'Something went wrong. Please try again.';
  }

  Future<void> _fetchBalances() async {
    try {
      final data = await _service.getLeaveBalances();
      if (!mounted) return;
      setState(() {
        _balances = data;
        _balancesError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _balancesError = _messageOf(e));
    }
  }

  Future<void> _fetchHistory() async {
    try {
      final data = await _service.getLeaveHistory();
      if (!mounted) return;
      setState(() {
        _history = data;
        _historyError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _historyError = _messageOf(e));
    }
  }

  Future<void> _loadAll() async {
    await Future.wait([_fetchBalances(), _fetchHistory()]);
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _retry() async {
    setState(() => _isLoading = true);
    await _loadAll();
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<bool> _submitLeave(EmpLeaveRequest request) async {
    if (_isSubmitting) return false;

    setState(() => _isSubmitting = true);

    try {
      await _service.submitLeaveRequest(request);
    } catch (e) {
      if (!mounted) return false;
      setState(() => _isSubmitting = false);
      _showError(_messageOf(e));
      return false;
    }

    if (!mounted) return false;

    setState(() {
      _isSubmitting = false;
      _showSuccess = true;
    });

    _successTimer?.cancel();
    _successTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _showSuccess = false);
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    // Refresh balances and history from the backend.
    await _loadAll();

    return true;
  }

  void _showError(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textDark,
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: widget.embedded
          ? null
          : AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text(
          'Apply Leave',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _wrap(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _wrap(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  _buildSuccessBanner(),
                  _buildBalances(),
                  const SizedBox(height: 16),
                  EmpLeaveForm(
                    balances: _balances,
                    isSubmitting: _isSubmitting,
                    onSubmit: _submitLeave,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Real-time Leave Applications Log (${_history.length})',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          ..._buildHistorySlivers(),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: !_showSuccess
          ? const SizedBox.shrink(key: ValueKey('no-success'))
          : Padding(
        key: const ValueKey('success'),
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: successLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: success.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  size: 20, color: success),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Leave request submitted successfully!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: success,
                  ),
                ),
              ),
              InkWell(
                onTap: () => setState(() => _showSuccess = false),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close_rounded,
                      size: 18, color: success),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalances() {
    if (_balances.isEmpty) {
      return _NoticeCard(
        icon: Icons.info_outline_rounded,
        message: _balancesError ??
            'Leave balance details are not available right now.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 4 : 2;
        const spacing = 12.0;
        final itemWidth =
        ((constraints.maxWidth - spacing * (columns - 1)) / columns)
            .floorToDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final balance in _balances)
              SizedBox(
                width: itemWidth,
                child: EmpLeaveBalanceCard(balance: balance),
              ),
          ],
        );
      },
    );
  }

  List<Widget> _buildHistorySlivers() {
    if (_historyError != null && _history.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _wrap(
            _ErrorCard(message: _historyError!, onRetry: _retry),
          ),
        ),
      ];
    }

    if (_history.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _wrap(
            const _NoticeCard(
              icon: Icons.event_note_outlined,
              message:
              'No leave applications yet. Your submitted requests will appear here.',
            ),
          ),
        ),
      ];
    }

    return [
      SliverList.builder(
        itemCount: _history.length,
        itemBuilder: (context, index) {
          return _wrap(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: EmpLeaveHistoryCard(leave: _history[index]),
            ),
          );
        },
      ),
    ];
  }
}

class _NoticeCard extends StatelessWidget {
  final IconData icon;
  final String message;

  const _NoticeCard({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _EmpApplyLeaveScreenState.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: _EmpApplyLeaveScreenState.textLight),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13.5,
                color: _EmpApplyLeaveScreenState.textMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _EmpApplyLeaveScreenState.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 36, color: Colors.redAccent),
          const SizedBox(height: 10),
          const Text(
            'Unable to load leave applications',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _EmpApplyLeaveScreenState.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: _EmpApplyLeaveScreenState.textMedium,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
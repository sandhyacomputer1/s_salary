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

  // Palette (same as the admin screens)
  static const Color primary = Color(0xFFE96832);
  static const Color primaryTint = Color(0xFFFFEEE7);
  static const Color pageBg = Color(0xFFF7F8FA);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFE5E7EB);
  static const Color success = Color(0xFF159957);
  static const Color successLight = Color(0xFFE7F7EF);

  static const double _mobileBreakpoint = 700;

  /// Width from which form and history sit side by side.
  static const double _wideBreakpoint = 1000;

  /// Max width of the page content.
  /// double.infinity = fill the screen. Use e.g. 1600 to limit it on
  /// very large monitors.
  static const double _maxContentWidth = double.infinity;

  static const List<BoxShadow> _cardShadow = [
    BoxShadow(
      color: Color(0x06000000),
      blurRadius: 10,
      offset: Offset(0, 3),
    ),
  ];

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
      backgroundColor: pageBg,
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
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadAll,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primary),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final mobile = width < _mobileBreakpoint;
    final wide = width >= _wideBreakpoint;

    final form = EmpLeaveForm(
      balances: _balances,
      isSubmitting: _isSubmitting,
      onSubmit: _submitLeave,
    );

    final history = _buildHistorySection(mobile);

    return RefreshIndicator(
      color: primary,
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        controller: _scrollController,
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
                _buildPageHeader(mobile),
                SizedBox(height: mobile ? 14 : 20),
                _buildSuccessBanner(),
                _buildSectionTitle('Leave Balance', mobile),
                _buildBalances(mobile),
                SizedBox(height: mobile ? 18 : 24),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: form),
                      const SizedBox(width: 20),
                      Expanded(flex: 4, child: history),
                    ],
                  )
                else ...[
                  form,
                  SizedBox(height: mobile ? 18 : 24),
                  history,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _buildPageHeader(bool mobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Apply Leave',
          style: TextStyle(
            fontSize: mobile ? 22 : 27,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Check your balance, request time off and track your applications.',
          style: TextStyle(
            fontSize: mobile ? 13 : 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool mobile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: mobile ? 15 : 16,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
      ),
    );
  }

  // ============================================================
  // SUCCESS BANNER
  // ============================================================

  Widget _buildSuccessBanner() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: !_showSuccess
          ? const SizedBox.shrink(key: ValueKey('no-success'))
          : Padding(
        key: const ValueKey('success'),
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

  // ============================================================
  // BALANCES
  // ============================================================

  Widget _buildBalances(bool mobile) {
    if (_balances.isEmpty) {
      return _NoticeCard(
        icon: Icons.info_outline_rounded,
        message: _balancesError ??
            'Leave balance details are not available right now.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Phone: 2 per row. Tablet / web: 4 per row.
        final columns = constraints.maxWidth >= 700 ? 4 : 2;
        final spacing = mobile ? 10.0 : 14.0;
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

  // ============================================================
  // HISTORY SECTION
  // ============================================================

  Widget _buildHistorySection(bool mobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHistoryHeader(mobile),
        const SizedBox(height: 12),
        ..._buildHistoryContent(),
      ],
    );
  }

  Widget _buildHistoryHeader(bool mobile) {
    return Container(
      padding: EdgeInsets.all(mobile ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: _cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: primaryTint,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.event_note_outlined,
              size: 18,
              color: primary,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leave Applications',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Real-time log of your requests',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: textLight),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: primaryTint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_history.length}',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHistoryContent() {
    if (_historyError != null && _history.isEmpty) {
      return [
        _ErrorCard(message: _historyError!, onRetry: _retry),
      ];
    }

    if (_history.isEmpty) {
      return const [
        _NoticeCard(
          icon: Icons.event_note_outlined,
          message:
          'No leave applications yet. Your submitted requests will appear here.',
        ),
      ];
    }

    return [
      for (final leave in _history)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: EmpLeaveHistoryCard(leave: leave),
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
        boxShadow: _EmpApplyLeaveScreenState._cardShadow,
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
        boxShadow: _EmpApplyLeaveScreenState._cardShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 28,
              color: Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 12),
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
            style: FilledButton.styleFrom(
              backgroundColor: _EmpApplyLeaveScreenState.primary,
            ),
          ),
        ],
      ),
    );
  }
}
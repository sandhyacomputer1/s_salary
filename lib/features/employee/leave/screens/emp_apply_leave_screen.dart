import 'dart:async';

import 'package:flutter/material.dart';

import '../models/emp_leave_balance_model.dart';
import '../models/emp_leave_model.dart';
import '../services/emp_leave_service.dart';
import '../widgets/emp_leave_balance_card.dart';
import '../widgets/emp_leave_form.dart';
import 'emp_leave_list_screen.dart';

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

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showSuccess = false;

  String? _balancesError;

  Timer? _successTimer;

  // Palette (same as the admin screens)
  static const Color primary = Color(0xFFE96832);
  static const Color pageBg = Color(0xFFF7F8FA);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFE5E7EB);
  static const Color success = Color(0xFF159957);
  static const Color successLight = Color(0xFFE7F7EF);

  static const double _mobileBreakpoint = 700;

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

  Future<void> _loadAll() async {
    await _fetchBalances();
    if (!mounted) return;
    setState(() => _isLoading = false);
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

    // Refresh balances from the backend.
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
  // VIEW ALL LEAVES
  // ============================================================

  Future<void> _openAllLeaves() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EmpLeaveListScreen()),
    );

    // Balances may have changed (e.g. a leave was approved meanwhile).
    if (mounted) _loadAll();
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
                _buildSuccessBanner(),
                _buildSectionTitle('Leave Balance', mobile),
                _buildBalances(mobile),
                SizedBox(height: mobile ? 18 : 24),
                EmpLeaveForm(
                  balances: _balances,
                  isSubmitting: _isSubmitting,
                  onSubmit: _submitLeave,
                ),
                SizedBox(height: mobile ? 14 : 16),
                _buildViewAllButton(mobile),
              ],
            ),
          ),
        ),
      ),
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
  // VIEW ALL LEAVES BUTTON
  // ============================================================

  Widget _buildViewAllButton(bool mobile) {
    final button = OutlinedButton.icon(
      onPressed: _isSubmitting ? null : _openAllLeaves,
      icon: const Icon(Icons.list_alt_outlined, size: 18),
      label: const Text('View All Leaves'),
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary),
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
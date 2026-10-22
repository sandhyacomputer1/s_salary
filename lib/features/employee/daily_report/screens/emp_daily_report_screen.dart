import 'dart:async';

import 'package:flutter/material.dart';

import '../models/emp_daily_report_model.dart';
import '../services/emp_daily_report_service.dart';
import '../widgets/emp_daily_report_form.dart';
import 'emp_daily_report_list_screen.dart';

class EmpDailyReportScreen extends StatefulWidget {
  /// Set to true when shown inside the employee shell (no AppBar of its own).
  final bool embedded;

  const EmpDailyReportScreen({super.key, this.embedded = false});

  @override
  State<EmpDailyReportScreen> createState() => _EmpDailyReportScreenState();
}

class _EmpDailyReportScreenState extends State<EmpDailyReportScreen> {
  final EmpDailyReportService _service = EmpDailyReportService();
  final ScrollController _scrollController = ScrollController();

  // Only used to find today's report when the dated lookup returns nothing.
  List<EmpDailyReportModel> _history = [];
  EmpDailyReportModel? _todayReport;

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showSuccess = false;

  Timer? _successTimer;

  // Palette (same as the admin screens)
  static const Color primary = Color(0xFFE96832);
  static const Color primaryTint = Color(0xFFFFEEE7);
  static const Color pageBg = Color(0xFFF7F8FA);
  static const Color textDark = Color(0xFF18212F);
  static const Color success = Color(0xFF159957);
  static const Color successLight = Color(0xFFE7F7EF);

  static const double _mobileBreakpoint = 700;

  /// Max width of the page content.
  /// double.infinity = fill the screen. Use e.g. 1600 to limit it on
  /// very large monitors.
  static const double _maxContentWidth = double.infinity;

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
    if (e is EmpDailyReportException) return e.message;
    return 'Something went wrong. Please try again.';
  }

  Future<void> _fetchHistory() async {
    try {
      final data = await _service.getReportHistory();
      if (!mounted) return;
      setState(() => _history = data);
    } catch (_) {
      // History is only a fallback here; the full list has its own screen.
    }
  }

  Future<void> _fetchToday() async {
    EmpDailyReportModel? report;

    try {
      report = await _service.getTodayReport(DateTime.now());
    } catch (_) {
      report = null;
    }

    if (!mounted) return;
    setState(() => _todayReport = report);
  }

  Future<void> _loadAll() async {
    await Future.wait([_fetchHistory(), _fetchToday()]);

    if (!mounted) return;

    // If the dated lookup returned nothing, fall back to today's entry in
    // the history list (same data, different route).
    final todayKey = EmpDailyReportFormat.api(DateTime.now());
    final fromHistory =
        _history.where((r) => r.dateKey == todayKey).firstOrNull;

    setState(() {
      _todayReport ??= fromHistory;
      _isLoading = false;
    });
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<bool> _submitReport(EmpDailyReportInput input) async {
    if (_isSubmitting) return false;

    setState(() => _isSubmitting = true);

    try {
      await _service.submitDailyReport(input);
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

    // Reload today's report from the backend.
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
  // VIEW ALL REPORTS
  // ============================================================

  Future<void> _openAllReports() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EmpDailyReportListScreen()),
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
          'Daily Work Report',
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
                _buildViewAllButton(mobile),
                SizedBox(height: mobile ? 12 : 16),
                EmpDailyReportForm(
                  initialReport: _todayReport,
                  hasSubmittedToday: _todayReport != null,
                  isSubmitting: _isSubmitting,
                  onSubmit: _submitReport,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VIEW ALL REPORTS BUTTON
  // ============================================================

  Widget _buildViewAllButton(bool mobile) {
    final fg = _isSubmitting ? const Color(0xFF8A93A1) : primary;

    final button = Material(
      color: primaryTint,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _isSubmitting ? null : _openAllReports,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: mobile ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_rounded, size: 18, color: fg),
              const SizedBox(width: 8),
              Text(
                'View All Reports',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, size: 16, color: fg),
            ],
          ),
        ),
      ),
    );

    if (mobile) return button;

    return Align(
      alignment: Alignment.centerRight,
      child: button,
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
                  'Daily work report submitted successfully!',
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
}
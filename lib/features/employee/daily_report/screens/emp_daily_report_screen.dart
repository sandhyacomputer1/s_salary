import 'dart:async';

import 'package:flutter/material.dart';

import '../models/emp_daily_report_model.dart';
import '../services/emp_daily_report_service.dart';
import '../widgets/emp_daily_report_form.dart';
import '../widgets/emp_daily_report_history.dart';

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

  List<EmpDailyReportModel> _history = [];
  EmpDailyReportModel? _todayReport;

  bool _isLoading = true;
  bool _historyLoading = false;
  bool _isSubmitting = false;
  bool _showSuccess = false;

  String? _historyError;

  Timer? _successTimer;

  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFE1E5EA);
  static const Color success = Color(0xFF159957);
  static const Color successLight = Color(0xFFE7F7EF);

  static const double _maxContentWidth = 900;

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
      setState(() {
        _history = data;
        _historyError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _historyError = _messageOf(e));
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

  Future<void> _retryHistory() async {
    setState(() {
      _historyError = null;
      _historyLoading = true;
    });

    await _fetchHistory();

    if (!mounted) return;
    setState(() => _historyLoading = false);
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

    // Reload today's report and the history from the backend.
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
          'Daily Work Report',
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
                  EmpDailyReportForm(
                    initialReport: _todayReport,
                    hasSubmittedToday: _todayReport != null,
                    isSubmitting: _isSubmitting,
                    onSubmit: _submitReport,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Daily EOD Work Report History (${_history.length})',
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

  List<Widget> _buildHistorySlivers() {
    if (_historyLoading) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }

    if (_historyError != null && _history.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _wrap(
            _ErrorCard(message: _historyError!, onRetry: _retryHistory),
          ),
        ),
      ];
    }

    if (_history.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _wrap(
            const _NoticeCard(
              icon: Icons.description_outlined,
              message:
              'No daily work reports submitted yet. Fill the form above to log your first report.',
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
              child: EmpDailyReportHistoryCard(report: _history[index]),
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
        border: Border.all(color: _EmpDailyReportScreenState.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: _EmpDailyReportScreenState.textLight),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13.5,
                color: _EmpDailyReportScreenState.textMedium,
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
        border: Border.all(color: _EmpDailyReportScreenState.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 36, color: Colors.redAccent),
          const SizedBox(height: 10),
          const Text(
            'Unable to load report history',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _EmpDailyReportScreenState.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: _EmpDailyReportScreenState.textMedium,
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
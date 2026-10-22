import 'package:flutter/material.dart';

import '../models/emp_daily_report_model.dart';
import '../services/emp_daily_report_service.dart';
import '../widgets/emp_daily_report_history.dart';

/// Full list of the employee's submitted daily work reports.
/// Opened from the "View All Reports" button on the Daily Work Report screen.
class EmpDailyReportListScreen extends StatefulWidget {
  const EmpDailyReportListScreen({super.key});

  @override
  State<EmpDailyReportListScreen> createState() =>
      _EmpDailyReportListScreenState();
}

class _EmpDailyReportListScreenState extends State<EmpDailyReportListScreen> {
  final EmpDailyReportService _service = EmpDailyReportService();

  List<EmpDailyReportModel> _reports = [];
  bool _loading = true;
  String? _error;

  // Palette (same as the admin screens)
  static const Color primary = Color(0xFFE96832);
  static const Color primaryTint = Color(0xFFFFEEE7);
  static const Color pageBg = Color(0xFFF7F8FA);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFE5E7EB);
  static const Color danger = Color(0xFFDC2626);

  static const double _mobileBreakpoint = 700;

  /// Max width of the content on wide screens.
  /// double.infinity = fill the screen. Use e.g. 1200 to limit it.
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
    _load();
  }

  // ============================================================
  // DATA
  // ============================================================

  String _messageOf(Object e) {
    if (e is EmpDailyReportException) return e.message;
    return 'Something went wrong. Please try again.';
  }

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final data = await _service.getReportHistory();
      if (!mounted) return;
      setState(() {
        _reports = data;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _messageOf(e);
        _loading = false;
      });
    }
  }

  void _goToSubmit() {
    Navigator.of(context).maybePop();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.of(context).size.width < _mobileBreakpoint;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: const Text(
          'Daily Work Reports',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        elevation: 0,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : () => _load(showSpinner: false),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        color: primary,
        onRefresh: () => _load(showSpinner: false),
        child: _buildBody(mobile),
      ),
      bottomNavigationBar: _buildBottomBar(mobile),
    );
  }

  // ============================================================
  // BOTTOM BAR
  // ============================================================

  Widget _buildBottomBar(bool mobile) {
    final button = FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: _goToSubmit,
      icon: const Icon(Icons.edit_note_rounded, size: 20),
      label: const Text(
        "Submit Today's Report",
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            mobile ? 14 : 22,
            10,
            mobile ? 14 : 22,
            10,
          ),
          child: mobile
              ? button
              : Align(
            alignment: Alignment.centerRight,
            heightFactor: 1,
            child: SizedBox(width: 280, child: button),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody(bool mobile) {
    final padding = EdgeInsets.fromLTRB(
      mobile ? 14 : 22,
      mobile ? 16 : 22,
      mobile ? 14 : 22,
      28,
    );

    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 160),
          Center(child: CircularProgressIndicator(color: primary)),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: [
          const SizedBox(height: 40),
          Center(
            child: _stateCard(
              icon: Icons.error_outline_rounded,
              iconColor: danger,
              iconBg: const Color(0xFFFFF1F1),
              title: 'Could not load your reports',
              message: _error!,
              buttonLabel: 'Try again',
              buttonIcon: Icons.refresh_rounded,
              onPressed: _load,
            ),
          ),
        ],
      );
    }

    if (_reports.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: [
          const SizedBox(height: 40),
          Center(
            child: _stateCard(
              icon: Icons.description_outlined,
              iconColor: textLight,
              iconBg: const Color(0xFFF1F5F9),
              title: 'No daily work reports yet',
              message:
              'Reports you submit will appear here, newest first.',
              buttonLabel: 'Submit your first report',
              buttonIcon: Icons.edit_note_rounded,
              onPressed: _goToSubmit,
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryBar(mobile),
                SizedBox(height: mobile ? 12 : 16),
                for (final report in _reports)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: EmpDailyReportHistoryCard(report: report),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY BAR
  // ============================================================

  Widget _buildSummaryBar(bool mobile) {
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
              Icons.history_rounded,
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
                  'EOD Report History',
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
                  'Your previously submitted daily reports',
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
              '${_reports.length}',
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

  // ============================================================
  // STATE CARD (error / empty)
  // ============================================================

  Widget _stateCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String message,
    required String buttonLabel,
    required IconData buttonIcon,
    required VoidCallback onPressed,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: _cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 30, color: iconColor),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: textMedium),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(buttonIcon),
            label: Text(buttonLabel),
            style: FilledButton.styleFrom(backgroundColor: primary),
          ),
        ],
      ),
    );
  }
}
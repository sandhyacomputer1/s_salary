import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import '../models/emp_leave_model.dart';
import '../services/emp_leave_service.dart';
import '../widgets/emp_leave_history_card.dart';

/// Full list of the employee's leave applications.
/// Opened from the "View All Leaves" button on the Apply Leave screen.
class EmpLeaveListScreen extends StatefulWidget {
  const EmpLeaveListScreen({super.key});

  @override
  State<EmpLeaveListScreen> createState() => _EmpLeaveListScreenState();
}

class _EmpLeaveListScreenState extends State<EmpLeaveListScreen> {
  final EmpLeaveService _service = EmpLeaveService();

  List<EmpLeaveModel> _leaves = [];
  bool _loading = true;
  String? _error;

  /// null = All, otherwise 'pending' / 'approved' / 'rejected' / 'cancelled'
  String? _filter;

  static const List<String> _filterOptions = [
    'pending',
    'approved',
    'rejected',
    'cancelled',
  ];

  // Palette (same as the admin screens)
  static const Color primary = Color(0xFFE96832);
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
    if (e is EmpLeaveException) return e.message;
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
      final data = await _service.getLeaveHistory();
      if (!mounted) return;
      setState(() {
        _leaves = data;
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

  String _statusOf(EmpLeaveModel leave) =>
      leave.status.toString().toLowerCase();

  bool _matches(EmpLeaveModel leave, String status) =>
      _statusOf(leave).contains(status);

  List<EmpLeaveModel> get _visibleLeaves => _filter == null
      ? _leaves
      : _leaves.where((l) => _matches(l, _filter!)).toList();

  String _labelOf(String status) =>
      status[0].toUpperCase() + status.substring(1);

  void _goToApply() {
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
          'My Leave Applications',
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
      onPressed: _goToApply,
      icon: const Icon(Icons.add, size: 20),
      label: const Text(
        'Apply New Leave',
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
            child: SizedBox(width: 260, child: button),
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
            child: Container(
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
                      color: const Color(0xFFFFF1F1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 30,
                      color: danger,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Could not load your leaves',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: textMedium),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                    style: FilledButton.styleFrom(backgroundColor: primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_leaves.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: [
          const SizedBox(height: 40),
          Center(
            child: Container(
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
                  const Icon(
                    Icons.event_note_outlined,
                    size: 44,
                    color: textLight,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No leave applications yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your submitted requests will appear here with their status.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: textMedium),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _goToApply,
                    icon: const Icon(Icons.add),
                    label: const Text('Apply for leave'),
                    style: FilledButton.styleFrom(backgroundColor: primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final visible = _visibleLeaves;

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
                _buildFilterMenu(mobile),
                SizedBox(height: mobile ? 12 : 16),
                if (visible.isEmpty)
                  _buildNoResults()
                else
                  for (final leave in visible)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: EmpLeaveHistoryCard(leave: leave),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FILTER MENU (compact, scrolling pills)
  // ============================================================

  Widget _buildFilterMenu(bool mobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 4 : 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: _cardShadow,
      ),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
          scrollbars: false,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterPill(
                'All',
                _leaves.length,
                _filter == null,
                    () => setState(() => _filter = null),
                mobile,
              ),
              for (final s in _filterOptions)
                _filterPill(
                  _labelOf(s),
                  _leaves.where((l) => _matches(l, s)).length,
                  _filter == s,
                      () => setState(() => _filter = s),
                  mobile,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterPill(
      String label,
      int count,
      bool selected,
      VoidCallback onTap,
      bool mobile,
      ) {
    final fg = selected ? Colors.white : const Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: selected ? primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 10 : 12,
              vertical: mobile ? 6 : 7,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: mobile ? 12 : 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.22)
                        : pageBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Center(
        child: Text(
          'No ${_filter ?? ''} leave applications',
          style: const TextStyle(fontSize: 14, color: textMedium),
        ),
      ),
    );
  }
}
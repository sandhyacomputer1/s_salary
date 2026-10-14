import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../models/audit_log_model.dart';
import '../services/audit_trail_service.dart';
import '../widgets/audit_event_table.dart';
import '../widgets/audit_filter_bar.dart';
import '../widgets/audit_pagination.dart';

class AuditTrailScreen extends StatefulWidget {
  const AuditTrailScreen({super.key});

  @override
  State<AuditTrailScreen> createState() => _AuditTrailScreenState();
}

class _AuditTrailScreenState extends State<AuditTrailScreen> {
  // Palette copied from AdminDashboardScreen.
  static const Color _primary = Color(0xFFE96832);
  static const Color _textDark = Color(0xFF18212F);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _pageBg = Color(0xFFF7F8FA);
  static const double _mobileBreakpoint = 700;

  final AuditTrailService _service = AuditTrailService();

  /// Filters + page of the LAST request that was started.
  AuditQuery _query = const AuditQuery();

  /// Last successfully loaded page (kept when a later request fails).
  AuditPage? _data;

  bool _requesting = false; // also blocks duplicate requests
  String? _error;
  int _token = 0;

  bool get _isMobile => MediaQuery.of(context).size.width < _mobileBreakpoint;

  @override
  void initState() {
    super.initState();
    _load(_query);
  }

  // ==========================================================
  // DATA
  // ==========================================================

  Future<void> _load(AuditQuery query) async {
    if (_requesting) return; // never run two requests at once

    final token = ++_token;

    setState(() {
      _requesting = true;
      _error = null;
      _query = query;
    });

    try {
      final page = await _service.fetchPage(query);
      if (!mounted || token != _token) return;

      setState(() {
        _data = page;
        _requesting = false;
      });
    } on AuditTrailException catch (e) {
      if (!mounted || token != _token) return;

      if (e.isAuthError) {
        _goToLogin();
        return;
      }

      // Keep the last good results on screen.
      setState(() {
        _requesting = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted || token != _token) return;

      setState(() {
        _requesting = false;
        _error = 'Something went wrong while loading audit events.';
      });
    }
  }

  void _goToLogin() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
          (route) => false,
    );
  }

  void _onSearch(String search, String action, String status) {
    // Any filter change starts again from page 1.
    _load(
      AuditQuery(search: search, action: action, status: status, page: 1),
    );
  }

  void _previous() {
    final data = _data;
    if (data == null || !data.hasPrevious) return;

    // copyWith keeps the active search / action / status.
    _load(_query.copyWith(page: data.page - 1));
  }

  void _next() {
    final data = _data;
    if (data == null || !data.hasNext) return;

    _load(_query.copyWith(page: data.page + 1));
  }

  void _clearFilters() => _load(const AuditQuery());

  Future<void> _refresh() => _load(_query);

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobile;

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Audit Trail',
          style: TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _requesting ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              mobile ? 14 : 22,
              mobile ? 16 : 22,
              mobile ? 14 : 22,
              35,
            ),
            children: [
              Text(
                'Company Admin  /  Security Audit Trail',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(mobile ? 14 : 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(),
                    const SizedBox(height: 20),
                    AuditFilterBar(
                      search: _query.search,
                      action: _query.action,
                      status: _query.status,
                      busy: _requesting,
                      onSearch: _onSearch,
                    ),
                    const SizedBox(height: 18),
                    _results(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    // The count comes from the backend response; it is never hardcoded.
    final total = _data?.total;
    final suffix = total == null ? '' : ' ($total total events)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Security Audit Trail',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'System-wide security events, authentication challenges, IP logs, '
              'and administrative changes$suffix.',
          style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _results() {
    final data = _data;

    // First load failed: nothing to fall back on.
    if (data == null && _error != null && !_requesting) {
      return _errorState();
    }

    // First load running: skeleton rows.
    if (data == null) {
      return const AuditEventTable(logs: [], isLoading: true);
    }

    final empty = data.logs.isEmpty && !_requesting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          _errorBanner(),
          const SizedBox(height: 12),
        ],
        if (empty)
          _emptyState()
        else
          AuditEventTable(logs: data.logs, isLoading: _requesting),
        if (data.logs.isNotEmpty || data.page > 1)
          AuditPagination(
            page: data.page,
            totalPages: data.totalPages,
            hasPrevious: data.hasPrevious,
            hasNext: data.hasNext,
            busy: _requesting,
            onPrevious: _previous,
            onNext: _next,
          ),
      ],
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.shield_outlined, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No audit events found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _query.hasFilters
                ? 'No events match the current search and filters.'
                : 'There are no audit events yet.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          if (_query.hasFilters) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _requesting ? null : _clearFilters,
              icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
              label: const Text('Clear filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _textDark,
                side: const BorderSide(color: Color(0xFFD9DEE7)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _errorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
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
              color: Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _requesting ? null : () => _load(_query),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: FilledButton.styleFrom(backgroundColor: _primary),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF5DDA3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: Color(0xFFB45309),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$_error Showing the previous results.',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF92400E)),
            ),
          ),
          TextButton(
            onPressed: _requesting ? null : () => _load(_query),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
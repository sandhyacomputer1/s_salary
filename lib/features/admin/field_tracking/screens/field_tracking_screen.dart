import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../models/field_employee_location_model.dart';
import '../models/location_history_model.dart';
import '../services/field_tracking_service.dart';
import '../widgets/employee_location_details.dart';
import '../widgets/field_employee_list.dart';
import '../widgets/field_tracking_format.dart';
import '../widgets/location_history_map.dart';

class FieldTrackingScreen extends StatefulWidget {
  /// True when shown inside the admin dashboard (the sidebar stays visible).
  final bool embedded;

  const FieldTrackingScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<FieldTrackingScreen> createState() => _FieldTrackingScreenState();
}

class _FieldTrackingScreenState extends State<FieldTrackingScreen>
    with WidgetsBindingObserver {
  // Palette copied from AdminDashboardScreen.
  static const Color _primary = Color(0xFFE96832);
  static const Color _textDark = Color(0xFF18212F);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _pageBg = Color(0xFFF7F8FA);

  /// How often the ADMIN map re-reads locations.
  static const Duration _refreshInterval = Duration(seconds: 30);

  static const double _wideBreakpoint = 900;

  final FieldTrackingService _service = FieldTrackingService();

  // Employees
  List<FieldEmployeeLocation> _employees = const [];
  bool _loading = true; // first load only
  String? _error; // shown only when there is no data to fall back on
  String? _refreshError; // refresh failed but older data is still shown
  DateTime? _lastRefreshed;

  // Refresh control
  bool _liveRefresh = true;
  bool _refreshing = false; // guards against overlapping requests
  bool _appActive = true;
  Timer? _timer;

  // Selection + history
  String? _selectedId;
  late DateTime _selectedDate;
  LocationHistory? _history;
  bool _historyLoading = false;
  String? _historyError;
  int _historyToken = 0; // ignores out-of-date responses

  bool get _isToday =>
      FieldTrackingFormat.isSameDay(_selectedDate, DateTime.now());

  FieldEmployeeLocation? get _selected {
    final id = _selectedId;
    if (id == null) return null;

    for (final e in _employees) {
      if (e.id == id) return e;
    }
    return null;
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // ==========================================================
  // LIFECYCLE
  // ==========================================================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedDate = _today();
    _refreshAll(initial: true);
    _restartTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed;
    if (active == _appActive) return;

    _appActive = active;

    if (active && _liveRefresh) {
      _refreshAll();
    }

    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = null;

    if (!_liveRefresh || !_appActive) return;

    _timer = Timer.periodic(_refreshInterval, (_) {
      if (!mounted) return;

      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return;

      _refreshAll();
    });
  }

  void _setLive(bool value) {
    setState(() => _liveRefresh = value);
    _restartTimer();

    if (value) _refreshAll();
  }

  void _goToLogin() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
          (route) => false,
    );
  }

  // ==========================================================
  // DATA
  // ==========================================================

  Future<void> _refreshAll({bool initial = false}) async {
    if (_refreshing) return; // never overlap requests
    _refreshing = true;

    setState(() {
      if (initial) {
        _loading = true;
        _error = null;
      }
    });

    try {
      final list = await _service.fetchFieldLocations();
      if (!mounted) return;

      setState(() {
        _employees = list;
        _lastRefreshed = DateTime.now();
        _loading = false;
        _error = null;
        _refreshError = null;

        if (_selectedId != null && !list.any((e) => e.id == _selectedId)) {
          _selectedId = null;
          _history = null;
          _historyError = null;
          _historyLoading = false;
          _historyToken++;
        }
      });

      if (_selectedId != null && _isToday) {
        await _loadHistory(silent: true);
      }
    } on FieldTrackingException catch (e) {
      if (!mounted) return;

      if (e.isAuthError) {
        _goToLogin();
        return;
      }

      setState(() {
        _loading = false;
        if (_employees.isEmpty) {
          _error = e.message;
        } else {
          _refreshError = e.message;
        }
      });
    } catch (_) {
      if (!mounted) return;

      const message = 'Something went wrong while loading field locations.';

      setState(() {
        _loading = false;
        if (_employees.isEmpty) {
          _error = message;
        } else {
          _refreshError = message;
        }
      });
    } finally {
      _refreshing = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadHistory({bool silent = false}) async {
    final id = _selectedId;
    if (id == null) return;

    final date = _selectedDate;
    final token = ++_historyToken;

    if (!silent) {
      setState(() {
        _historyLoading = true;
        _historyError = null;
      });
    }

    try {
      final history = await _service.fetchHistory(id, date);
      if (!mounted || token != _historyToken) return;

      setState(() {
        _history = history;
        _historyLoading = false;
        _historyError = null;
      });
    } on FieldTrackingException catch (e) {
      if (!mounted || token != _historyToken) return;

      if (e.isAuthError) {
        _goToLogin();
        return;
      }

      setState(() {
        _historyLoading = false;
        if (!silent) _historyError = e.message;
      });
    } catch (_) {
      if (!mounted || token != _historyToken) return;

      setState(() {
        _historyLoading = false;
        if (!silent) _historyError = 'Could not load the route history.';
      });
    }
  }

  // ==========================================================
  // SELECTION + DATE
  // ==========================================================

  void _select(FieldEmployeeLocation employee) {
    if (employee.id == _selectedId) return;

    setState(() {
      _selectedId = employee.id;
      _history = null;
      _historyError = null;
    });

    _loadHistory();
  }

  void _clearSelection() {
    setState(() {
      _selectedId = null;
      _history = null;
      _historyError = null;
      _historyLoading = false;
      _historyToken++;
    });
  }

  void _setDate(DateTime date) {
    if (FieldTrackingFormat.isSameDay(date, _selectedDate)) return;

    setState(() {
      _selectedDate = date;
      _history = null;
      _historyError = null;
    });

    _loadHistory();
  }

  Future<void> _pickDate() async {
    final today = _today();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(today.year - 1, today.month, today.day),
      lastDate: today,
    );

    if (picked == null || !mounted) return;

    _setDate(DateTime(picked.year, picked.month, picked.day));
  }

  void _previousDay() {
    _setDate(
      DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day - 1),
    );
  }

  void _nextDay() {
    final next = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day + 1,
    );

    if (next.isAfter(_today())) return;

    _setDate(next);
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    // The core body layout
    final bodyContent = SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return constraints.maxWidth >= _wideBreakpoint
              ? _wideLayout(constraints)
              : _narrowLayout();
        },
      ),
    );

    // Embedded: return only the body so the dashboard shell stays visible
    if (widget.embedded) {
      return Container(
        color: _pageBg,
        child: bodyContent,
      );
    }

    // Standalone: full screen with its own Scaffold and AppBar
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Field GPS Tracking',
          style: TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: bodyContent,
    );
  }

  Widget _wideLayout(BoxConstraints constraints) {
    final height = (constraints.maxHeight - 170).clamp(520.0, 900.0).toDouble();
    final selected = _selected;

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        _header(mobile: false),
        const SizedBox(height: 16),
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 380,
                child: Column(
                  children: [
                    Expanded(flex: 5, child: _list(shrinkWrap: false)),
                    if (selected != null) ...[
                      const SizedBox(height: 12),
                      Expanded(
                        flex: 6,
                        child: SingleChildScrollView(child: _details(selected)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _map()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _narrowLayout() {
    final selected = _selected;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _header(mobile: true),
        const SizedBox(height: 14),
        SizedBox(height: 340, child: _map()),
        if (selected != null) ...[
          const SizedBox(height: 14),
          _details(selected),
        ],
        const SizedBox(height: 14),
        _list(shrinkWrap: true),
      ],
    );
  }

  Widget _list({required bool shrinkWrap}) {
    return FieldEmployeeList(
      employees: _employees,
      selectedId: _selectedId,
      onSelect: _select,
      isLoading: _loading,
      error: _error,
      onRetry: () => _refreshAll(initial: true),
      shrinkWrap: shrinkWrap,
    );
  }

  Widget _map() {
    return LocationHistoryMap(
      employees: _employees,
      selected: _selected,
      history: _history,
      historyLoading: _historyLoading,
      showLatestMarker: _isToday,
      onSelectEmployee: _select,
      onClearSelection: _clearSelection,
    );
  }

  Widget _details(FieldEmployeeLocation employee) {
    return EmployeeLocationDetails(
      employee: employee,
      history: _history,
      historyLoading: _historyLoading,
      historyError: _historyError,
      date: _selectedDate,
      onPickDate: _pickDate,
      onPreviousDay: _previousDay,
      onNextDay: _nextDay,
      onToday: () => _setDate(_today()),
      onRetryHistory: () => _loadHistory(),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _header({required bool mobile}) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Field Employee Live GPS Tracking',
          style: TextStyle(
            fontSize: mobile ? 18 : 22,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Automatic 10-minute location pings and route history for '
              'field personnel',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );

    final liveToggle = InkWell(
      onTap: () => _setLive(!_liveRefresh),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: _liveRefresh,
            activeColor: _primary,
            onChanged: (value) => _setLive(value ?? false),
          ),
          const Text(
            'Live Refresh (Every 30s)',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
    );

    final refreshButton = OutlinedButton.icon(
      onPressed: _refreshing ? null : () => _refreshAll(),
      icon: _refreshing
          ? const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : const Icon(Icons.refresh_rounded, size: 18),
      label: const Text('Refresh Now'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _textDark,
        side: const BorderSide(color: Color(0xFFD9DEE7)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
      ),
    );

    final controls = Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [liveToggle, refreshButton],
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mobile) ...[
            title,
            const SizedBox(height: 12),
            controls,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: title),
                const SizedBox(width: 16),
                controls,
              ],
            ),
          const SizedBox(height: 12),
          _statusRow(),
        ],
      ),
    );
  }

  Widget _statusRow() {
    final ok = _refreshError == null;

    final updated = _lastRefreshed == null
        ? 'Not refreshed yet'
        : 'Last updated ${FieldTrackingFormat.time(_lastRefreshed!)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: ok ? const Color(0xFF18864B) : const Color(0xFFE8A317),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '$updated  •  auto-refresh ${_liveRefresh ? 'on' : 'off'}',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
        if (_refreshError != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF5DDA3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  size: 18,
                  color: Color(0xFFB45309),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Could not refresh: $_refreshError '
                        'Showing the last loaded data.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _refreshing ? null : () => _refreshAll(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
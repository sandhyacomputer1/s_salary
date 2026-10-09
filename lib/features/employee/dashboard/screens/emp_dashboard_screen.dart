import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/emp_dash_attendance_model.dart';
import '../models/emp_dash_profile_model.dart';
import '../models/emp_dash_shift_model.dart';
import '../services/emp_dash_service.dart';
import '../widgets/emp_dash_attendance_card.dart';
import '../widgets/emp_dash_breakdown_chart.dart';
import '../widgets/emp_dash_summary_card.dart';

class EmpDashboardScreen extends StatefulWidget {
  const EmpDashboardScreen({super.key});

  @override
  State<EmpDashboardScreen> createState() => _EmpDashboardScreenState();
}

class _EmpDashboardScreenState extends State<EmpDashboardScreen> {
  final EmpDashService _service = EmpDashService();

  EmpDashProfileModel? _profile;
  EmpDashShiftModel? _shift;
  List<EmpDashAttendanceRecord> _attendance = [];

  bool _isLoading = true;
  String? _error;
  bool _isActionLoading = false;

  static const Color primary = Color(0xFFE96832);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFE1E5EA);

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final now = DateTime.now();

    try {
      // Profile must load first — attendance history needs the
      // employee's real _id as a path segment
      // (GET /attendance/employee/:employeeId).
      final profile = await _service.getProfile();

      final results = await Future.wait([
        _service.getMyShift(),
        _service.getAttendanceHistory(
          employeeId: profile.id,
          month: now.month,
          year: now.year,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _shift = results[0] as EmpDashShiftModel;
        _attendance = results[1] as List<EmpDashAttendanceRecord>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _errorText(e);
        _isLoading = false;
      });
    }
  }

  String _errorText(Object e) {
    return e.toString().replaceFirst('Exception: ', '');
  }

  EmpDashAttendanceRecord? get _todayRecord {
    final now = DateTime.now();

    for (final record in _attendance) {
      final date = record.date;
      if (date != null &&
          date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return record;
      }
    }

    return null;
  }

  EmpDashAttendanceState get _attendanceState {
    final record = _todayRecord;

    if (record == null || record.checkInTime == null) {
      return EmpDashAttendanceState.notCheckedIn;
    }

    if (record.checkOutTime == null) {
      return EmpDashAttendanceState.checkedIn;
    }

    return EmpDashAttendanceState.checkedOut;
  }

  Future<(double lat, double lng)> _getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled. Please enable location and try again.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission denied. Please allow location access to check in/out.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied. Please enable it from device settings.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return (position.latitude, position.longitude);
  }

  Future<void> _handleCheckIn() async {
    setState(() => _isActionLoading = true);

    try {
      final (lat, lng) = await _getCurrentLocation();

      final result = await _service.checkIn(
        lat: lat,
        lng: lng,
        workMode: _profile?.workMode,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );

      await _loadDashboard();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorText(e))),
      );
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _handleCheckOut() async {
    setState(() => _isActionLoading = true);

    try {
      final (lat, lng) = await _getCurrentLocation();

      final result = await _service.checkOut(lat: lat, lng: lng);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );

      await _loadDashboard();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorText(e))),
      );
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: _buildAppBar(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEE7),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.bolt_rounded, color: primary, size: 19),
          ),
          const SizedBox(width: 10),
          const Text(
            'Sandhya Salary',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
          ),
        ],
      ),
      actions: [
        if (_profile != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                _profile!.displayName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textMedium,
                ),
              ),
            ),
          ),
        IconButton(
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: textDark,
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        key: const ValueKey('error'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to load dashboard',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: textMedium),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadDashboard,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final summary = EmpDashAttendanceSummary.fromRecords(_attendance);

    return RefreshIndicator(
      key: const ValueKey('content'),
      onRefresh: _loadDashboard,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeaderInfo(),
          const SizedBox(height: 20),
          EmpDashAttendanceCard(
            state: _attendanceState,
            todayRecord: _todayRecord,
            shift: _shift,
            isActionLoading: _isActionLoading,
            onCheckIn: _handleCheckIn,
            onCheckOut: _handleCheckOut,
          ),
          const SizedBox(height: 20),
          _buildSummaryRow(summary),
          const SizedBox(height: 20),
          EmpDashBreakdownChart(summary: summary),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo() {
    final profile = _profile;

    if (profile == null) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${profile.displayName}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${profile.designation.isEmpty ? "—" : profile.designation} · '
                    '${profile.department.isEmpty ? "—" : profile.department} · '
                    '${profile.companyName}',
                style: const TextStyle(fontSize: 12.5, color: textMedium),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(EmpDashAttendanceSummary summary) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        EmpDashSummaryCard(
          title: 'Present Days',
          value: summary.presentDays,
          icon: Icons.check_circle_outline_rounded,
          iconBackground: const Color(0xFFE7F7EF),
          iconColor: const Color(0xFF159957),
        ),
        EmpDashSummaryCard(
          title: 'Late Arrivals',
          value: summary.lateArrivals,
          icon: Icons.schedule_rounded,
          iconBackground: const Color(0xFFFFF4D6),
          iconColor: const Color(0xFFD99000),
        ),
        EmpDashSummaryCard(
          title: 'Half Days',
          value: summary.halfDays,
          icon: Icons.timelapse_rounded,
          iconBackground: const Color(0xFFE9F0FF),
          iconColor: const Color(0xFF2563EB),
        ),
        EmpDashSummaryCard(
          title: 'Absences',
          value: summary.absences,
          icon: Icons.cancel_outlined,
          iconBackground: const Color(0xFFFFE8E8),
          iconColor: const Color(0xFFD64545),
        ),
      ],
    );
  }
}
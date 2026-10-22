import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../models/emp_dash_attendance_model.dart';
import '../models/emp_dash_profile_model.dart';
import '../models/emp_dash_shift_model.dart';
import '../services/emp_dash_service.dart';
import '../widgets/emp_camera_capture_dialog.dart';
import '../widgets/emp_dash_attendance_card.dart';
import '../widgets/emp_dash_breakdown_chart.dart';
import '../widgets/emp_dash_summary_card.dart';

class EmpDashboardScreen extends StatefulWidget {
  final bool embedded;
  const EmpDashboardScreen({super.key, this.embedded = false});

  @override
  State<EmpDashboardScreen> createState() => _EmpDashboardScreenState();
}

class _EmpDashboardScreenState extends State<EmpDashboardScreen>
    with SingleTickerProviderStateMixin {
  final EmpDashService _service = EmpDashService();
  final ImagePicker _picker = ImagePicker();

  EmpDashProfileModel? _profile;
  EmpDashShiftModel? _shift;
  List<EmpDashAttendanceRecord> _attendance = [];
  bool _isLoading = true;
  String? _error;
  bool _isActionLoading = false;

  static const Color primary = Color(0xFFE96832);
  static const Color primaryTint = Color(0xFFFFEEE7);
  static const Color pageBg = Color(0xFFF7F8FA);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color border = Color(0xFFE5E7EB);

  static const double _mobileBreakpoint = 700;
  static const double _wideBreakpoint = 1000;

  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadDashboard();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final now = DateTime.now();

    try {
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
        _error = null;
      });

      _entranceController.forward(from: 0);
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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    return (position.latitude, position.longitude);
  }

  Future<String?> _captureAndEncodePhoto() async {
    if (kIsWeb) {
      final bytes = await EmpCameraCaptureDialog.show(
        context,
        title: 'Take a photo to continue',
      );

      if (bytes == null) return null;

      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 60,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (photo == null) return null;

      final bytes = await photo.readAsBytes();
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } catch (e) {
      debugPrint('Camera error: $e');
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (file == null) return null;
      final bytes = await file.readAsBytes();
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }
  }

  Future<void> _handleCheckIn() async {
    setState(() => _isActionLoading = true);

    try {
      final photoUrl = await _captureAndEncodePhoto();
      if (photoUrl == null) {
        if (mounted) setState(() => _isActionLoading = false);
        return;
      }

      final (lat, lng) = await _getCurrentLocation();

      final result = await _service.checkIn(
        lat: lat,
        lng: lng,
        photoUrl: photoUrl,
        workMode: _profile?.workMode,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );

      await _loadDashboard(showSpinner: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorText(e))),
      );
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleCheckOut() async {
    setState(() => _isActionLoading = true);

    try {
      final photoUrl = await _captureAndEncodePhoto();
      if (photoUrl == null) {
        if (mounted) setState(() => _isActionLoading = false);
        return;
      }

      final (lat, lng) = await _getCurrentLocation();

      final result = await _service.checkOut(
        lat: lat,
        lng: lng,
        photoUrl: photoUrl,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );

      await _loadDashboard(showSpinner: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorText(e))),
      );
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: _buildBody(),
    );

    if (widget.embedded) {
      return ColoredBox(color: pageBg, child: body);
    }

    return Scaffold(
      backgroundColor: pageBg,
      appBar: _buildAppBar(),
      body: body,
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
              color: primaryTint,
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
        IconButton(
          tooltip: 'Refresh',
          onPressed: _isLoading ? null : () => _loadDashboard(showSpinner: false),
          icon: const Icon(Icons.refresh_rounded, color: textDark),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(color: primary),
      );
    }

    if (_error != null) return _buildErrorState();

    final summary = EmpDashAttendanceSummary.fromRecords(_attendance);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final mobile = screenWidth < _mobileBreakpoint;

    final attendanceCard = EmpDashAttendanceCard(
      key: const ValueKey('emp-attendance-card'), // FIXED: Stable key
      state: _attendanceState,
      todayRecord: _todayRecord,
      shift: _shift,
      isActionLoading: _isActionLoading,
      onCheckIn: _handleCheckIn,
      onCheckOut: _handleCheckOut,
    );

    final onLeaveDays = _attendance
        .where((r) => r.isOnLeave && r.checkInTime == null)
        .length;

    final chart = EmpDashBreakdownChart(
      summary: summary,
      onLeaveDays: onLeaveDays,
    );
    final gap = SizedBox(height: mobile ? 14 : 20);

    return RefreshIndicator(
      key: const ValueKey('content'),
      color: primary,
      onRefresh: () => _loadDashboard(showSpinner: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          mobile ? 14 : 22,
          mobile ? 16 : 22,
          mobile ? 14 : 22,
          32,
        ),
        children: [
          _staggeredIn(0, _buildHeaderInfo(mobile)),
          gap,
          _staggeredIn(1, attendanceCard),
          gap,
          _buildSummaryGrid(summary, mobile, 2),
          gap,
          _staggeredIn(6, chart),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildHeaderInfo(bool mobile) {
    final profile = _profile;
    const clock = _LiveDateTimeChip();

    if (profile == null) {
      return const Align(alignment: Alignment.centerLeft, child: clock);
    }

    final detail = '${profile.designation.isEmpty ? "—" : profile.designation}'
        '  •  ${profile.department.isEmpty ? "—" : profile.department}'
        '  •  ${profile.companyName}';

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_greeting()}, ${profile.displayName}',
          style: TextStyle(fontSize: mobile ? 22 : 27, fontWeight: FontWeight.w700, color: textDark),
        ),
        const SizedBox(height: 6),
        Text(detail, style: TextStyle(fontSize: mobile ? 13 : 14, color: Colors.grey.shade600)),
      ],
    );

    if (mobile) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [titleBlock, const SizedBox(height: 12), clock]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: titleBlock), const SizedBox(width: 12), clock],
    );
  }

  // FIXED: Replaced LayoutBuilder with MediaQuery to prevent unbounded height crash
  Widget _buildSummaryGrid(EmpDashAttendanceSummary summary, bool mobile, int startIndex) {
    final cards = <Widget>[
      EmpDashSummaryCard(
        key: const ValueKey('summary-present'),
        title: 'Present Days',
        value: summary.presentDays,
        icon: Icons.check_circle_outline_rounded,
        iconBackground: const Color(0xFFE7F7EF),
        iconColor: const Color(0xFF159957),
        highlighted: true,
      ),
      EmpDashSummaryCard(
        key: const ValueKey('summary-late'),
        title: 'Late Arrivals',
        value: summary.lateArrivals,
        icon: Icons.schedule_rounded,
        iconBackground: const Color(0xFFFFF4D6),
        iconColor: const Color(0xFFD99000),
      ),
      EmpDashSummaryCard(
        key: const ValueKey('summary-half'),
        title: 'Half Days',
        value: summary.halfDays,
        icon: Icons.timelapse_rounded,
        iconBackground: const Color(0xFFE9F0FF),
        iconColor: const Color(0xFF2563EB),
      ),
      EmpDashSummaryCard(
        key: const ValueKey('summary-absent'),
        title: 'Absences',
        value: summary.absences,
        icon: Icons.cancel_outlined,
        iconBackground: const Color(0xFFFFE8E8),
        iconColor: const Color(0xFFD64545),
      ),
    ];

    final screenWidth = MediaQuery.sizeOf(context).width;
    final columns = screenWidth >= 700 ? 4 : 2;
    final spacing = mobile ? 10.0 : 16.0;

    // Approximate available width: subtract horizontal padding of ListView (14 or 22)
    final availableWidth = screenWidth - (mobile ? 28 : 44);
    final itemWidth = ((availableWidth - spacing * (columns - 1)) / columns).floorToDouble();

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (var i = 0; i < cards.length; i++)
          SizedBox(
            width: itemWidth,
            child: _staggeredIn(startIndex + i, cards[i]),
          ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      key: const ValueKey('error'),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 62, height: 62, decoration: BoxDecoration(color: const Color(0xFFFFF1F1), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.error_outline_rounded, size: 32, color: Color(0xFFDC2626))),
            const SizedBox(height: 16),
            const Text('Unable to load dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textDark)),
            const SizedBox(height: 8),
            Text(_error ?? 'Something went wrong.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: textMedium)),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: _loadDashboard, icon: const Icon(Icons.refresh_rounded), label: const Text('Try Again'), style: FilledButton.styleFrom(backgroundColor: primary)),
          ],
        ),
      ),
    );
  }

  Widget _staggeredIn(int index, Widget child) {
    final start = (index * 0.1).clamp(0.0, 0.6);
    final animation = CurvedAnimation(parent: _entranceController, curve: Interval(start, (start + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutCubic));

    return AnimatedBuilder(
      animation: animation,
      builder: (context, builtChild) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, (1 - animation.value) * 16), child: builtChild),
        );
      },
      child: child,
    );
  }
}

// =================================================================
// LIVE DATE + CLOCK CHIP
// =================================================================

class _LiveDateTimeChip extends StatefulWidget {
  const _LiveDateTimeChip();

  @override
  State<_LiveDateTimeChip> createState() => _LiveDateTimeChipState();
}

class _LiveDateTimeChipState extends State<_LiveDateTimeChip> {
  static const Color _primary = Color(0xFFE96832);
  static const Color _border = Color(0xFFE5E7EB);

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const List<String> _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _dateText =>
      '${_weekdays[_now.weekday - 1]}, ${_now.day} ${_months[_now.month - 1]} ${_now.year}';

  String get _timeText {
    final hour = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final minute = _now.minute.toString().padLeft(2, '0');
    final second = _now.second.toString().padLeft(2, '0');
    final period = _now.hour >= 12 ? 'pm' : 'am';
    return '${hour.toString().padLeft(2, '0')}:$minute:$second $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF6B7280)),
          const SizedBox(width: 7),
          Text(
            _dateText,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEE7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.access_time_rounded, size: 13, color: _primary),
                const SizedBox(width: 5),
                Text(
                  _timeText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
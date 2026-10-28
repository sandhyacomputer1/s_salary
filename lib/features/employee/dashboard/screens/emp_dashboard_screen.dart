import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/emp_dash_attendance_model.dart';
import '../models/emp_dash_profile_model.dart';
import '../models/emp_dash_shift_model.dart';
import '../services/emp_dash_service.dart';
import 'emp_attendance_camera_screen.dart';
import '../widgets/emp_dash_attendance_card.dart';
import '../widgets/emp_dash_breakdown_chart.dart';
import '../widgets/emp_dash_summary_card.dart';

/// In-memory cache so the dashboard opens instantly when the employee
/// comes back to it from another sidebar item (the shell rebuilds this
/// screen every time).
class _EmpDashCache {
  static EmpDashProfileModel? profile;
  static EmpDashShiftModel? shift;
  static List<EmpDashAttendanceRecord> attendance = [];
  static DateTime? loadedAt;

  static bool get hasData => profile != null && loadedAt != null;

  static void clear() {
    profile = null;
    shift = null;
    attendance = [];
    loadedAt = null;
  }
}

class _Loc {
  final double? lat;
  final double? lng;
  final Object? error;
  const _Loc(this.lat, this.lng, [this.error]);
}

/// One row inside the notification panel.
class _NotifItem {
  final String title;
  final String message;
  final String footer;
  final bool completed; // true = "Completed", false = "Pending"

  const _NotifItem({
    required this.title,
    required this.message,
    required this.footer,
    required this.completed,
  });
}

class EmpDashboardScreen extends StatefulWidget {
  final bool embedded;
  const EmpDashboardScreen({super.key, this.embedded = false});

  /// Number shown on the shell's bell badge.
  static final ValueNotifier<int> notificationCount = ValueNotifier<int>(0);
  static List<_NotifItem> _notifItems = [];

  /// Call from the shell's bell: opens the notification panel.
  static Future<void> showNotifications(BuildContext context) =>
      _showNotificationPanel(context, _notifItems);

  /// Call this on logout so the next user never sees old data.
  static void clearCache() {
    _EmpDashCache.clear();
    _notifItems = [];
    notificationCount.value = 0;
  }

  @override
  State<EmpDashboardScreen> createState() => _EmpDashboardScreenState();
}

class _EmpDashboardScreenState extends State<EmpDashboardScreen>
    with SingleTickerProviderStateMixin {
  final EmpDashService _service = EmpDashService();

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

  // Cached data younger than this is shown without re-fetching.
  static const Duration _cacheFreshFor = Duration(seconds: 45);

  late final AnimationController _entranceController;

  /// The permission pop-ups are shown once each time the app is opened.
  static bool _askedThisSession = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    if (_EmpDashCache.hasData) {
      // Show the last known data immediately.
      _profile = _EmpDashCache.profile;
      _shift = _EmpDashCache.shift;
      _attendance = _EmpDashCache.attendance;
      _isLoading = false;
      _entranceController.forward(from: 0);

      final age = DateTime.now().difference(_EmpDashCache.loadedAt!);
      if (age > _cacheFreshFor) {
        // Refresh quietly in the background.
        _loadDashboard(showSpinner: false);
      }
    } else {
      _loadDashboard();
    }

    // Ask for Location + Camera as soon as the dashboard is on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_profile != null) _syncNotifications();
      _requestStartupPermissions();
    });
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
      // All three requests run at the same time.
      // If we already know the employee id (cache), attendance does not
      // have to wait for the profile.
      final profileFuture = _service.getProfile();
      final shiftFuture = _service.getMyShift();

      final cachedId = _EmpDashCache.profile?.id;
      final Future<List<EmpDashAttendanceRecord>> attendanceFuture =
      (cachedId != null && cachedId.isNotEmpty)
          ? _service.getAttendanceHistory(
        employeeId: cachedId,
        month: now.month,
        year: now.year,
      )
          : profileFuture.then(
            (p) => _service.getAttendanceHistory(
          employeeId: p.id,
          month: now.month,
          year: now.year,
        ),
      );

      final results = await Future.wait<Object>([
        profileFuture,
        shiftFuture,
        attendanceFuture,
      ]);

      final profile = results[0] as EmpDashProfileModel;
      final shift = results[1] as EmpDashShiftModel;
      final attendance = results[2] as List<EmpDashAttendanceRecord>;

      _EmpDashCache.profile = profile;
      _EmpDashCache.shift = shift;
      _EmpDashCache.attendance = attendance;
      _EmpDashCache.loadedAt = DateTime.now();

      if (!mounted) return;

      setState(() {
        _profile = profile;
        _shift = shift;
        _attendance = attendance;
        _isLoading = false;
        _error = null;
      });

      _syncNotifications();
      _entranceController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;

      // A quiet background refresh must not wipe a working screen.
      if (!showSpinner && _profile != null) return;

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

  // ============================================================
  // NOTIFICATIONS (bell icon -> panel)
  // ============================================================

  /// Formats a time that may be a DateTime or a String into "11:15 am".
  String? _fmtTime(dynamic value) {
    if (value == null) return null;

    DateTime? dt;
    if (value is DateTime) {
      dt = value;
    } else if (value is String) {
      if (value.trim().isEmpty) return null;
      dt = DateTime.tryParse(value);
      if (dt == null) return value; // already a readable text like "18:00"
    } else {
      return value.toString();
    }

    final local = dt.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'pm' : 'am';
    return '$hour:$minute $period';
  }

  /// Shift end time as text (for example "18:00").
  ///
  /// NOTE: I have not seen EmpDashShiftModel. If your end-time field is not
  /// called `endTime`, change the name on the line marked  <-- HERE.
  String? get _shiftEndText {
    try {
      final dynamic s = _shift;
      final dynamic end = s?.endTime; // <-- HERE
      if (end == null) return null;
      final text = end.toString().trim();
      return text.isEmpty ? null : text;
    } catch (_) {
      return null; // field does not exist -> alert simply has no time
    }
  }

  List<_NotifItem> _buildNotifications() {
    final record = _todayRecord;
    final state = _attendanceState;
    final inText = _fmtTime(record?.checkInTime);
    final outText = _fmtTime(record?.checkOutTime);
    final endText = _shiftEndText;

    final items = <_NotifItem>[];

    switch (state) {
      case EmpDashAttendanceState.notCheckedIn:
        items.add(
          _NotifItem(
            title: 'Check-In Pending',
            message: 'You have not checked in today. '
                'Please record your check-in.',
            footer: 'Shift Schedule: ${_shiftStartHint()}',
            completed: false,
          ),
        );
        break;

      case EmpDashAttendanceState.checkedIn:
        items.add(
          _NotifItem(
            title: 'Check-In Recorded',
            message: 'Check-in recorded successfully'
                '${inText != null ? ' at $inText' : ''}.',
            footer: 'Shift Schedule: ${inText ?? '--'}',
            completed: true,
          ),
        );
        items.add(
          _NotifItem(
            title: 'Shift Check-Out Alert',
            message: endText != null
                ? 'Your set working shift ends at $endText. '
                'Please record your check-out when leaving.'
                : 'Please record your check-out when leaving.',
            footer: 'Shift Schedule: ${endText != null ? '$endText End' : '--'}',
            completed: false,
          ),
        );
        break;

      case EmpDashAttendanceState.checkedOut:
        items.add(
          _NotifItem(
            title: 'Check-In Recorded',
            message: 'Check-in recorded successfully'
                '${inText != null ? ' at $inText' : ''}.',
            footer: 'Shift Schedule: ${inText ?? '--'}',
            completed: true,
          ),
        );
        items.add(
          _NotifItem(
            title: 'Check-Out Recorded',
            message: 'Check-out recorded successfully'
                '${outText != null ? ' at $outText' : ''}.',
            footer: 'Shift Schedule: ${outText ?? '--'}',
            completed: true,
          ),
        );
        break;
    }

    return items;
  }

  String _shiftStartHint() {
    try {
      final dynamic s = _shift;
      final dynamic start = s?.startTime; // change name if different
      final text = start?.toString().trim() ?? '';
      return text.isEmpty ? '--' : '$text Start';
    } catch (_) {
      return '--';
    }
  }

  /// Publishes the current notifications so the bell that already exists
  /// in the app shell (top bar) can show the count and open the panel.
  void _syncNotifications() {
    final items = _buildNotifications();
    EmpDashboardScreen._notifItems = items;
    EmpDashboardScreen.notificationCount.value = items.length;
  }

  // ============================================================
  // PERMISSIONS ON DASHBOARD OPEN
  // ============================================================

  /// Set to false if the app does not use notifications yet.
  static const bool _askNotificationPermission = true;

  /// Shows the system pop-ups one after another:
  ///   0) "Turn on GPS" prompt (only if the phone's location is switched off)
  ///   1) Location   2) Camera   3) Notifications
  /// so check-in / check-out opens straight away later.
  Future<void> _requestStartupPermissions() async {
    if (_askedThisSession) return;
    _askedThisSession = true;

    final blocked = <String>[]; // permissions that can only be fixed in Settings

    try {
      // 0) GPS switched off on the phone -> ask to turn it on
      if (!kIsWeb) {
        final gpsOn = await Geolocator.isLocationServiceEnabled();
        if (!gpsOn && mounted) {
          final open = await _askDialog(
            title: 'Turn on location',
            message:
            'Location (GPS) is switched off. It is needed to verify your '
                'office location when you check in or out.',
            action: 'Turn on',
          );
          if (open == true) await Geolocator.openLocationSettings();
        }
      }

      // 1) Location
      var location = await Geolocator.checkPermission();
      if (location == LocationPermission.denied) {
        location = await Geolocator.requestPermission();
      }
      if (location == LocationPermission.deniedForever) {
        blocked.add('Location');
      }

      if (!kIsWeb) {
        // 2) Camera (on the web the browser asks by itself)
        var camera = await Permission.camera.status;
        if (camera.isDenied) camera = await Permission.camera.request();
        if (camera.isPermanentlyDenied) blocked.add('Camera');

        // 3) Notifications (Android 13+ / iOS)
        if (_askNotificationPermission) {
          final notif = await Permission.notification.status;
          if (notif.isDenied) await Permission.notification.request();
        }
      }
    } catch (e) {
      debugPrint('PERMISSION REQUEST ERROR: $e');
    }

    // Something was blocked ("Don't ask again") -> only Settings can fix it.
    if (blocked.isNotEmpty && mounted) {
      final open = await _askDialog(
        title: '${blocked.join(' & ')} access is blocked',
        message:
        'Please allow ${blocked.join(' and ')} in the app settings, '
            'otherwise check-in and check-out will not work.',
        action: 'Open Settings',
      );
      if (open == true) await openAppSettings();
    }
  }

  Future<bool?> _askDialog({
    required String title,
    required String message,
    required String action,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: textDark,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13.5, height: 1.45, color: textMedium),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: primary),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Future<void> _ensureLocationPermission() async {
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
  }

  Future<(double lat, double lng)> _readPosition() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );

    return (position.latitude, position.longitude);
  }

  /// Starts reading GPS in the background (while the employee is taking
  /// the selfie). Never throws - the error is returned inside [_Loc].
  Future<_Loc> _startLocation() {
    return _readPosition()
        .then<_Loc>((v) => _Loc(v.$1, v.$2))
        .catchError((Object e) => _Loc(null, null, e));
  }

  // ============================================================
  // CHECK IN / CHECK OUT  (opens the full screen selfie camera)
  // ============================================================

  Future<void> _handleCheckIn() => _openAttendanceCamera(isCheckIn: true);

  Future<void> _handleCheckOut() => _openAttendanceCamera(isCheckIn: false);

  Future<void> _openAttendanceCamera({required bool isCheckIn}) async {
    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);

    try {
      // Permission first, so no dialog appears over the camera screen...
      await _ensureLocationPermission();

      // ...then GPS is read in the background while the selfie is taken.
      var locFuture = _startLocation();
      String? successMessage;

      if (!mounted) return;

      final done = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          fullscreenDialog: true,
          builder: (_) => EmpAttendanceCameraScreen(
            isCheckIn: isCheckIn,
            onConfirm: (photoUrl) async {
              final loc = await locFuture;

              if (loc.error != null) {
                // read GPS again for the next "Try again"
                locFuture = _startLocation();
                throw loc.error!;
              }

              if (isCheckIn) {
                final result = await _service.checkIn(
                  lat: loc.lat!,
                  lng: loc.lng!,
                  photoUrl: photoUrl,
                  workMode: _profile?.workMode,
                );
                successMessage = result.message;
              } else {
                final result = await _service.checkOut(
                  lat: loc.lat!,
                  lng: loc.lng!,
                  photoUrl: photoUrl,
                );
                successMessage = result.message;
              }
            },
          ),
        ),
      );

      if (!mounted) return;

      if (done == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              successMessage ??
                  (isCheckIn
                      ? 'Checked in successfully'
                      : 'Checked out successfully'),
            ),
          ),
        );

        await _loadDashboard(showSpinner: false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorText(e))),
      );
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

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
      key: const ValueKey('emp-attendance-card'),
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
          style: TextStyle(
            fontSize: mobile ? 22 : 27,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          detail,
          style: TextStyle(
            fontSize: mobile ? 13 : 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [titleBlock, const SizedBox(height: 12), clock],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Expanded(child: titleBlock), const SizedBox(width: 12), clock],
    );
  }

  Widget _buildSummaryGrid(
      EmpDashAttendanceSummary summary,
      bool mobile,
      int startIndex,
      ) {
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

    final availableWidth = screenWidth - (mobile ? 28 : 44);
    final itemWidth =
    ((availableWidth - spacing * (columns - 1)) / columns).floorToDouble();

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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: textMedium),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _loadDashboard(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(backgroundColor: primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _staggeredIn(int index, Widget child) {
    final start = (index * 0.1).clamp(0.0, 0.6);
    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(
        start,
        (start + 0.4).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, builtChild) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 16),
            child: builtChild,
          ),
        );
      },
      child: child,
    );
  }
}

// =================================================================
// NOTIFICATION PANEL
// =================================================================

Future<void> _showNotificationPanel(
    BuildContext context,
    List<_NotifItem> items,
    ) async {
  final mobile = MediaQuery.sizeOf(context).width < 700;

  if (mobile) {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _NotificationPanel(
            items: items,
            onClose: () => Navigator.pop(sheetContext),
          ),
        ),
      ),
    );
    return;
  }

  // Wide screen: small panel under the bell, top-right.
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close notifications',
    barrierColor: Colors.black.withValues(alpha: 0.08),
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (dialogContext, _, __) {
      return SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 64, right: 20),
            child: Material(
              color: Colors.transparent,
              child: _NotificationPanel(
                items: items,
                onClose: () => Navigator.pop(dialogContext),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.03),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
}

class _NotificationPanel extends StatelessWidget {
  final List<_NotifItem> items;
  final VoidCallback onClose;

  const _NotificationPanel({required this.items, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      constraints: BoxConstraints(
        maxWidth: 400,
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF18212F),
                  ),
                ),
              ),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No notifications',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _NotificationCard(item: items[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final _NotifItem item;
  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final done = item.completed;

    // Completed = blue card, Pending = orange card (same as the web).
    final cardBg = done ? const Color(0xFFEFF5FF) : const Color(0xFFFFF4EC);
    final cardBorder =
    done ? const Color(0xFFBFD6FB) : const Color(0xFFF8D2B5);
    final titleColor =
    done ? const Color(0xFF1D4ED8) : const Color(0xFFC2410C);
    final pillBg = done ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7);
    final pillText = done ? const Color(0xFF166534) : const Color(0xFF92400E);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  done ? 'Completed' : 'Pending',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: pillText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            item.message,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.footer,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
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
          const Icon(
            Icons.calendar_today_outlined,
            size: 15,
            color: Color(0xFF6B7280),
          ),
          const SizedBox(width: 7),
          Text(
            _dateText,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
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
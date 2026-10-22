import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_attendance_model.dart';
import '../repositories/notification_repository.dart';
import '../utils/notification_theme.dart';
import '../widgets/notification_list_tile.dart';
import '../widgets/profile_navigation.dart';
import '../widgets/summary_cards.dart';

enum ActivityTab { all, checkIns, checkOuts, late }

class CheckInOutNotificationsScreen extends ConsumerStatefulWidget {
  final bool embedded;
  const CheckInOutNotificationsScreen({super.key, this.embedded = false});

  @override
  ConsumerState<CheckInOutNotificationsScreen> createState() =>
      _CheckInOutNotificationsScreenState();
}

class _CheckInOutNotificationsScreenState
    extends ConsumerState<CheckInOutNotificationsScreen> {
  static const double _mobileBreakpoint = 700;

  final TextEditingController _searchController = TextEditingController();
  ActivityTab _activeTab = ActivityTab.all;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncRecords = ref.watch(todayAttendanceProvider);
    final mobile = MediaQuery.of(context).size.width < _mobileBreakpoint;

    // The scrollable body used by BOTH branches. In embedded mode the
    // dashboard supplies the height, so we simply hand it a finite-scroll
    // view. In standalone mode we provide our own Scaffold.
    Widget buildBody() {
      return RefreshIndicator(
        onRefresh: () => ref.read(todayAttendanceProvider.notifier).refresh(),
        color: NotificationColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            mobile ? 14 : 22,
            mobile ? 16 : 22,
            mobile ? 14 : 22,
            mobile ? 16 : 22,
          ),
          child: asyncRecords.when(
            loading: () => const _LoadingState(),
            error: (e, _) => _ErrorState(
              message: e.toString().replaceFirst('Exception: ', ''),
              onRetry: () =>
                  ref.read(todayAttendanceProvider.notifier).refresh(),
            ),
            data: (records) => _buildBodyContent(records, mobile),
          ),
        ),
      );
    }

    if (widget.embedded) {
      return Container(
        color: NotificationColors.background,
        child: buildBody(),
      );
    }

    return Scaffold(
      backgroundColor: NotificationColors.background,
      appBar: AppBar(
        title: const Text('Check-In & Check-Out Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: NotificationColors.textDark,
        elevation: 0,
      ),
      body: buildBody(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBodyContent(List<AdminAttendanceModel> records, bool mobile) {
    final totalIn = records.where((r) => r.hasCheckedIn).length;
    final totalOut = records.where((r) => r.hasCheckedOut).length;
    final late = records.where((r) => r.hasCheckedIn && r.isLate).length;
    final inOffice = records.where((r) => r.isCurrentlyInOffice).length;

    final allEvents = AttendanceEvent.fromRecords(records);
    final checkInEvents = allEvents
        .where((e) => e.kind == AttendanceEventKind.checkIn)
        .toList();
    final checkOutEvents = allEvents
        .where((e) => e.kind == AttendanceEventKind.checkOut)
        .toList();
    final lateEvents = checkInEvents.where((e) => e.record.isLate).toList();

    List<AttendanceEvent> visible;
    switch (_activeTab) {
      case ActivityTab.all:
        visible = allEvents;
        break;
      case ActivityTab.checkIns:
        visible = checkInEvents;
        break;
      case ActivityTab.checkOuts:
        visible = checkOutEvents;
        break;
      case ActivityTab.late:
        visible = lateEvents;
        break;
    }

    final q = _searchQuery.trim().toLowerCase();
    final filtered = q.isEmpty
        ? visible
        : visible.where((e) {
      final r = e.record;
      return r.employeeName.toLowerCase().contains(q) ||
          r.employeeCode.toLowerCase().contains(q);
    }).toList();

    // NOTE: no `mainAxisSize: MainAxisSize.min` on this outer Column.
    // The parent SingleChildScrollView will measure it lazily; letting it
    // be `max` under a scroll view is safe because scroll gives infinite
    // vertical space, and each child has finite intrinsic height.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NotificationSummaryCards(
          totalIns: totalIn,
          totalOuts: totalOut,
          lateArrivals: late,
          inOffice: inOffice,
        ),
        const SizedBox(height: 24),

        // ── The notifications panel ──────────────────────────────────────
        // A Container with an implicit-height Column. `mainAxisSize: min`
        // on the inner Column is what gives the panel its real height.
        Container(
          decoration: BoxDecoration(
            color: NotificationColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: NotificationColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _headerRow(),
              _tabsRow(
                total: allEvents.length,
                checkIns: checkInEvents.length,
                checkOuts: checkOutEvents.length,
                late: lateEvents.length,
              ),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'No notifications match your current filter',
                        style: NotificationText.emptyTitle,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Check-in and check-out events from employees will appear here in real-time.',
                        style: NotificationText.emptySubtitle,
                      ),
                    ],
                  ),
                )
              else if (mobile)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final e in filtered)
                        NotificationEventCard(
                          event: e,
                          onViewProfile: () =>
                              openEmployeeProfile(context, e.record),
                        ),
                    ],
                  ),
                )
              else
                NotificationTable(
                  events: filtered,
                  onViewProfile: (e) =>
                      openEmployeeProfile(context, e.record),
                ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _headerRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: LayoutBuilder(
        builder: (context, c) {
          final isWide = c.maxWidth > 700;

          final title = const Text(
            "Today's Live Check-In & Check-Out Notifications",
            style: NotificationText.sectionTitle,
          );

          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 240,
                height: 36,
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search employee name or code...',
                    hintStyle: NotificationText.emptySubtitle,
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12),
                    filled: true,
                    fillColor: NotificationColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:
                      const BorderSide(color: NotificationColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:
                      const BorderSide(color: NotificationColors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () =>
                    ref.read(todayAttendanceProvider.notifier).refresh(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: NotificationColors.textDark,
                  side: const BorderSide(color: NotificationColors.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text(
                  'Refresh',
                  style:
                  TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );

          if (isWide) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [Expanded(child: title), actions],
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 16), actions],
          );
        },
      ),
    );
  }

  Widget _tabsRow({
    required int total,
    required int checkIns,
    required int checkOuts,
    required int late,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: NotificationColors.border),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTab('All Activity', ActivityTab.all, total),
            _buildTab('Check-Ins', ActivityTab.checkIns, checkIns),
            _buildTab('Check-Outs', ActivityTab.checkOuts, checkOuts),
            _buildTab('Late Arrivals', ActivityTab.late, late),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, ActivityTab tab, int count) {
    final isSelected = _activeTab == tab;
    return InkWell(
      onTap: () => setState(() => _activeTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? NotificationColors.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          '$label ($count)',
          style: isSelected
              ? NotificationText.tabActive
              : NotificationText.tabInactive,
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 100),
      child: Center(
        child: CircularProgressIndicator(color: NotificationColors.primary),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline,
              color: NotificationColors.danger, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: NotificationText.emptySubtitle,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
                backgroundColor: NotificationColors.primary),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
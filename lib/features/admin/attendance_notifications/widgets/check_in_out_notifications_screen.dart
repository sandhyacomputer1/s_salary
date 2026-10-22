import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_attendance_model.dart';
import '../repositories/notification_repository.dart';
import '../utils/notification_theme.dart';
import '../widgets/notification_list_tile.dart';
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

  /// Max width of the page content.
  /// double.infinity = fill the screen. Use e.g. 1600 to limit it on
  /// very large monitors.
  static const double _maxContentWidth = double.infinity;

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

    // The core scrollable content
    final content = RefreshIndicator(
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
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: asyncRecords.when(
              loading: () => const _LoadingState(),
              error: (e, _) => _ErrorState(
                message: e.toString().replaceFirst('Exception: ', ''),
                onRetry: () => ref.read(todayAttendanceProvider.notifier).refresh(),
              ),
              data: (records) => _buildBody(records),
            ),
          ),
        ),
      ),
    );

    // If embedded in the dashboard shell, return only the body so the sidebar stays
    if (widget.embedded) {
      return Container(
        color: NotificationColors.background,
        child: content,
      );
    }

    // Otherwise, standalone screen with its own AppBar
    return Scaffold(
      backgroundColor: NotificationColors.background,
      appBar: AppBar(
        title: const Text('Check-In & Check-Out Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: NotificationColors.textDark,
        elevation: 0,
      ),
      body: content,
    );
  }

  Widget _buildBody(List<AdminAttendanceModel> records) {
    final totalIn = records.where((r) => r.hasCheckedIn).length;
    final totalOut = records.where((r) => r.hasCheckedOut).length;
    final late = records.where((r) => r.isLate).length;
    final inOffice = records.where((r) => r.isCurrentlyInOffice).length;

    List<AdminAttendanceModel> tabFiltered = records;
    if (_activeTab == ActivityTab.checkIns) {
      tabFiltered = records.where((r) => r.hasCheckedIn).toList();
    } else if (_activeTab == ActivityTab.checkOuts) {
      tabFiltered = records.where((r) => r.hasCheckedOut).toList();
    } else if (_activeTab == ActivityTab.late) {
      tabFiltered = records.where((r) => r.isLate).toList();
    }

    final searched = tabFiltered.where((r) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return r.employeeName.toLowerCase().contains(q) ||
          r.employeeCode.toLowerCase().contains(q);
    }).toList();

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

        Container(
          decoration: BoxDecoration(
            color: NotificationColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: NotificationColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
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
                          width: 220,
                          height: 36,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search employee name or code...',
                              hintStyle: NotificationText.emptySubtitle,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              filled: true,
                              fillColor: NotificationColors.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: NotificationColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(color: NotificationColors.border),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => ref.read(todayAttendanceProvider.notifier).refresh(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: NotificationColors.textDark,
                            side: const BorderSide(color: NotificationColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text('Refresh', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    );

                    if (isWide) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [title, actions],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title,
                        const SizedBox(height: 16),
                        actions,
                      ],
                    );
                  },
                ),
              ),

              // Tabs
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: NotificationColors.border)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildTab('All Activity', ActivityTab.all, tabFiltered.length),
                      _buildTab('Check-Ins', ActivityTab.checkIns, records.where((r) => r.hasCheckedIn).length),
                      _buildTab('Check-Outs', ActivityTab.checkOuts, records.where((r) => r.hasCheckedOut).length),
                      _buildTab('Late Arrivals', ActivityTab.late, records.where((r) => r.isLate).length),
                    ],
                  ),
                ),
              ),

              // List
              if (searched.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Column(
                    children: [
                      Text('No notifications match your current filter', style: NotificationText.emptyTitle),
                      SizedBox(height: 6),
                      Text(
                        'Check-in and check-out events from employees will appear here in real-time.',
                        style: NotificationText.emptySubtitle,
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    for (final record in searched)
                      NotificationListTile(
                        record: record,
                        showCheckIn: _activeTab != ActivityTab.checkOuts,
                        showCheckOut: _activeTab != ActivityTab.checkIns,
                      )
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
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
              color: isSelected ? NotificationColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          '$label ($count)',
          style: isSelected ? NotificationText.tabActive : NotificationText.tabInactive,
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
      child: Center(child: CircularProgressIndicator(color: NotificationColors.primary)),
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
        children: [
          const Icon(Icons.error_outline, color: NotificationColors.danger, size: 40),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: NotificationText.emptySubtitle),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: NotificationColors.primary),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
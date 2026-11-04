import 'package:flutter/material.dart';

import '../../employees/services/admin_csv_download.dart';
import '../models/leave_model.dart';
import '../services/leave_service.dart';
import '../widgets/leave_card.dart';
import '../widgets/leave_table.dart';
import 'leave_details_screen.dart';

class LeaveScreen extends StatefulWidget {
  /// True when shown inside the admin dashboard (the sidebar stays visible).
  /// The dashboard already provides the Scaffold and AppBar.
  final bool embedded;

  /// PERMISSION: false = view only (no Approve / Reject anywhere on this
  /// screen or in the details page). The default is true (the old behaviour).
  final bool canManage;

  const LeaveScreen({
    super.key,
    this.embedded = false,
    this.canManage = true,
  });

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  final LeaveService _service = LeaveService();

  List<LeaveModel> _leaves = [];
  bool _isLoading = true;
  String? _error;

  String _searchQuery = '';
  String _selectedStatus = 'All';

  /// Table: ids of the requests ticked with the checkboxes.
  final Set<String> _selectedIds = {};
  bool _bulkBusy = false;

  static const Color primary = Color(0xFFE96832);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFE1E5EA);
  static const Color danger = Color(0xFFD64545);
  static const Color pageBg = Color(0xFFF7F8FA);

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  Future<void> _loadLeaves() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final leavesFuture = _service.getLeaves();
      final namesFuture = _service.getEmployeeNames().catchError(
            (_) => <String, String>{},
      );

      final leaves = await leavesFuture;
      final names = await namesFuture;

      final resolved = leaves.map((leave) {
        final id = leave.employee?.id ?? leave.employeeIdRaw;
        final name = names[id];
        return leave.copyWithResolvedName(name);
      }).toList();

      if (!mounted) return;

      setState(() {
        _leaves = resolved;
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

  List<LeaveModel> get _filteredLeaves {
    return _leaves.where((leave) {
      final query = _searchQuery.toLowerCase();

      final matchesSearch =
          leave.leaveType.toLowerCase().contains(query) ||
              leave.employeeDisplayLabel.toLowerCase().contains(query) ||
              leave.reason.toLowerCase().contains(query);

      final matchesStatus = _selectedStatus == 'All' ||
          leave.status.toLowerCase() == _selectedStatus.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get _pendingCount {
    return _leaves.where((l) => l.status.toLowerCase() == 'pending').length;
  }

  int get _approvedCount {
    return _leaves.where((l) => l.status.toLowerCase() == 'approved').length;
  }

  int get _rejectedCount {
    return _leaves.where((l) => l.status.toLowerCase() == 'rejected').length;
  }

  int get _cancelledCount {
    return _leaves.where((l) => l.status.toLowerCase() == 'cancelled').length;
  }

  Future<bool> _approveLeave(LeaveModel leave) async {
    if (!widget.canManage) return false; // PERMISSION

    try {
      final result = await _service.approveLeave(leave.id);

      if (!mounted) return false;

      final balance = result.balance;
      final message = balance != null
          ? 'Leave approved — ${balance.remaining.toStringAsFixed(balance.remaining.truncateToDouble() == balance.remaining ? 0 : 1)} ${balance.leaveType} day(s) remaining'
          : 'Leave approved successfully';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      await _loadLeaves();
      return true;
    } catch (e) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve leave: ${_errorText(e)}'),
        ),
      );
      return false;
    }
  }

  Future<bool> _confirmReject(LeaveModel leave) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject leave request?'),
        content: Text(
          'Reject the ${leave.leaveType} leave request from '
              '${leave.employeeDisplayLabel}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: danger),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Future<bool> _rejectLeave(LeaveModel leave) async {
    if (!widget.canManage) return false; // PERMISSION

    final confirmed = await _confirmReject(leave);

    if (!confirmed || !mounted) return false;

    try {
      await _service.rejectLeave(leave.id);

      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave rejected')),
      );

      await _loadLeaves();
      return true;
    } catch (e) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject leave: ${_errorText(e)}'),
        ),
      );
      return false;
    }
  }

  void _openDetails(LeaveModel leave) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LeaveDetailsScreen(
          leave: leave,
          // PERMISSION: no actions at all for a view-only role
          onApprove: widget.canManage ? () => _approveLeave(leave) : null,
          onReject: widget.canManage ? () => _rejectLeave(leave) : null,
        ),
      ),
    );

    if (mounted) {
      _loadLeaves();
    }
  }

  // ==========================================================
  // TABLE: selection, bulk approve / reject, export
  // (new methods, nothing above was changed)
  // ==========================================================

  void _toggleSelect(String id) {
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
    });
  }

  /// Header checkbox: ticks / unticks every pending request that is visible.
  void _toggleSelectAll(bool selectAll) {
    final pendingIds = _filteredLeaves
        .where((l) => l.status.toLowerCase() == 'pending')
        .map((l) => l.id);

    setState(() {
      if (selectAll) {
        _selectedIds.addAll(pendingIds);
      } else {
        _selectedIds.removeAll(pendingIds);
      }
    });
  }

  /// Ticked requests that are still pending and visible in the table.
  List<LeaveModel> _selectedPending() {
    return _filteredLeaves
        .where((l) =>
    l.status.toLowerCase() == 'pending' && _selectedIds.contains(l.id))
        .toList();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _bulkApprove() async {
    if (!widget.canManage || _bulkBusy) return; // PERMISSION

    final targets = _selectedPending();
    if (targets.isEmpty) return;

    setState(() => _bulkBusy = true);

    var done = 0;
    var failed = 0;
    for (final leave in targets) {
      try {
        await _service.approveLeave(leave.id);
        done++;
      } catch (_) {
        failed++;
      }
    }

    if (!mounted) return;
    setState(() {
      _bulkBusy = false;
      _selectedIds.clear();
    });

    _snack(failed == 0
        ? '$done leave request(s) approved successfully'
        : '$done approved, $failed failed');

    await _loadLeaves();
  }

  Future<void> _bulkReject() async {
    if (!widget.canManage || _bulkBusy) return; // PERMISSION

    final targets = _selectedPending();
    if (targets.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject selected leave requests?'),
        content: Text(
          'Reject ${targets.length} selected request(s)? '
              'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: danger),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _bulkBusy = true);

    var done = 0;
    var failed = 0;
    for (final leave in targets) {
      try {
        await _service.rejectLeave(leave.id);
        done++;
      } catch (_) {
        failed++;
      }
    }

    if (!mounted) return;
    setState(() {
      _bulkBusy = false;
      _selectedIds.clear();
    });

    _snack(failed == 0
        ? '$done leave request(s) rejected'
        : '$done rejected, $failed failed');

    await _loadLeaves();
  }

  /// Exports the requests that are visible in the table (search + status filter).
  Future<void> _exportCsv() async {
    final rows = _filteredLeaves;

    if (rows.isEmpty) {
      _snack('No leave requests to export');
      return;
    }

    String cell(Object? v) => '"${(v ?? '').toString().replaceAll('"', '""')}"';
    String two(int n) => n.toString().padLeft(2, '0');

    String dateOf(DateTime? d) {
      if (d == null) return '';
      final u = d.toUtc();
      return '${u.year}-${two(u.month)}-${two(u.day)}';
    }

    String days(double d) => d.truncateToDouble() == d ? d.toStringAsFixed(0) : d.toStringAsFixed(1);

    final lines = <String>[
      'Employee,Employee Code,Leave Type,Start Date,End Date,Days,Half Day,Paid,Reason,Status',
      for (final l in rows)
        [
          l.employeeDisplayLabel,
          l.employeeCode,
          l.leaveType,
          dateOf(l.startDate),
          dateOf(l.endDate),
          days(l.totalDays),
          l.isHalfDay ? 'Yes' : 'No',
          l.isPaid ? 'Yes' : 'No',
          l.reason,
          l.status,
        ].map(cell).join(','),
    ];

    final now = DateTime.now();
    final fileName = 'Leave_Requests_${now.year}-${two(now.month)}-${two(now.day)}.csv';

    try {
      final downloaded = await adminSaveCsv(fileName, '\uFEFF${lines.join('\n')}');
      if (!mounted) return;
      _snack(downloaded
          ? 'Leave requests exported'
          : 'CSV copied to clipboard (paste it into Excel / Sheets)');
    } catch (e) {
      if (!mounted) return;
      _snack('Export failed: ${_errorText(e)}');
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    // The core body content
    final body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: _buildBody(),
    );

    // Inside the admin dashboard: body only, the sidebar stays visible.
    if (widget.embedded) {
      return Container(color: pageBg, child: body);
    }

    // Standalone: own Scaffold and AppBar.
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Leave Requests',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadLeaves,
            icon: const Icon(
              Icons.refresh_rounded,
              color: textDark,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: body,
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
                'Unable to load leave requests',
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
                style: const TextStyle(
                  color: textMedium,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadLeaves,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      key: const ValueKey('content'),
      onRefresh: _loadLeaves,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildSummary(),
          const SizedBox(height: 20),
          _buildSearchAndFilter(),
          const SizedBox(height: 20),
          _buildLeaveList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // PERMISSION: tells a view-only role why there are no buttons
        if (!widget.canManage)
          Container(
            margin: const EdgeInsets.only(left: 12, top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F2F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility_outlined, size: 14, color: textLight),
                SizedBox(width: 5),
                Text(
                  'View only',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSummary() {
    final cards = <_SummaryCard>[
      _SummaryCard(
        title: 'Total Requests',
        value: '${_leaves.length}',
        icon: Icons.event_note_outlined,
        iconBackground: const Color(0xFFFFEEE7),
        iconColor: primary,
      ),
      _SummaryCard(
        title: 'Pending',
        value: '$_pendingCount',
        icon: Icons.pending_actions_rounded,
        iconBackground: const Color(0xFFFFF4D6),
        iconColor: const Color(0xFFD99000),
      ),
      _SummaryCard(
        title: 'Approved',
        value: '$_approvedCount',
        icon: Icons.check_circle_outline_rounded,
        iconBackground: const Color(0xFFE7F7EF),
        iconColor: const Color(0xFF159957),
      ),
      _SummaryCard(
        title: 'Rejected',
        value: '$_rejectedCount',
        icon: Icons.cancel_outlined,
        iconBackground: const Color(0xFFFFE8E8),
        iconColor: danger,
      ),
      _SummaryCard(
        title: 'Cancelled',
        value: '$_cancelledCount',
        icon: Icons.block_outlined,
        iconBackground: const Color(0xFFF1F2F4),
        iconColor: textLight,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final int columns = width >= 900 ? 5 : (width >= 600 ? 3 : 2);
        final bool compact = width < 600;
        final double spacing = compact ? 10 : 14;

        final double cardWidth =
            (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((card) {
            return SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: card.title,
                value: card.value,
                icon: card.icon,
                iconBackground: card.iconBackground,
                iconColor: card.iconColor,
                compact: compact,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 600;

          final search = TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search employee, leave type or reason...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: const Color(0xFFF8F9FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: BorderSide.none,
              ),
            ),
          );

          final filter = DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: InputDecoration(
              labelText: 'Status',
              filled: true,
              fillColor: const Color(0xFFF8F9FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'All',
                child: Text('All Status'),
              ),
              DropdownMenuItem(
                value: 'pending',
                child: Text('Pending'),
              ),
              DropdownMenuItem(
                value: 'approved',
                child: Text('Approved'),
              ),
              DropdownMenuItem(
                value: 'rejected',
                child: Text('Rejected'),
              ),
              DropdownMenuItem(
                value: 'cancelled',
                child: Text('Cancelled'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _selectedStatus = value;
              });
            },
          );

          if (isSmall) {
            return Column(
              children: [
                search,
                const SizedBox(height: 12),
                filter,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: filter,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeaveList() {
    final leaves = _filteredLeaves;

    if (leaves.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 48,
              color: textLight,
            ),
            SizedBox(height: 12),
            Text(
              'No leave requests found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textDark,
              ),
            ),
          ],
        ),
      );
    }

    // Phones / narrow screens: the same cards as before.
    final cards = Column(
      children: [
        for (int i = 0; i < leaves.length; i++)
          LeaveCard(
            key: ValueKey(leaves[i].id),
            leave: leaves[i],
            index: i,
            onTap: () => _openDetails(leaves[i]),
            // PERMISSION: Approve / Reject only for pending leaves AND
            // only for roles that may manage leaves
            onApprove: widget.canManage &&
                leaves[i].status.toLowerCase() == 'pending'
                ? () => _approveLeave(leaves[i])
                : null,
            onReject: widget.canManage &&
                leaves[i].status.toLowerCase() == 'pending'
                ? () => _rejectLeave(leaves[i])
                : null,
          ),
      ],
    );

    // Wide screens (web / tablet): the table like the web app.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) return cards;

        return LeaveTable(
          leaves: leaves,
          totalPending: _pendingCount,
          selectedIds: _selectedIds,
          canManage: widget.canManage,
          busy: _bulkBusy,
          onToggle: _toggleSelect,
          onToggleAll: _toggleSelectAll,
          onTap: _openDetails,
          onApprove: _approveLeave,
          onReject: _rejectLeave,
          onExport: _exportCsv,
          onBulkApprove: _bulkApprove,
          onBulkReject: _bulkReject,
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final bool compact;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final double iconBox = compact ? 34 : 42;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE1E5EA),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: compact ? 18 : 21,
            ),
          ),
          SizedBox(width: compact ? 8 : 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 11 : 11.5,
                    color: const Color(0xFF8A93A1),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    value,
                    key: ValueKey(value),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF18212F),
                    ),
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
import 'package:flutter/material.dart';

import '../models/leave_model.dart';
import '../services/leave_service.dart';
import '../widgets/leave_card.dart';
import 'leave_details_screen.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

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

  static const Color primary = Color(0xFFE96832);
  static const Color textDark = Color(0xFF18212F);
  static const Color textMedium = Color(0xFF4B5563);
  static const Color textLight = Color(0xFF8A93A1);
  static const Color border = Color(0xFFE1E5EA);
  static const Color danger = Color(0xFFD64545);

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
      // Leaves must always load; employee names are a display
      // enhancement only, so a failure there doesn't block the
      // main list (falls back to employee code via the model).
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
          onApprove: () => _approveLeave(leave),
          onReject: () => _rejectLeave(leave),
        ),
      ),
    );

    if (mounted) {
      _loadLeaves();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _buildBody(),
      ),
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
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leave Management',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Review and manage employee leave requests.',
                style: TextStyle(
                  fontSize: 13,
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
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
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
      ],
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

    return Column(
      children: [
        for (int i = 0; i < leaves.length; i++)
          LeaveCard(
            key: ValueKey(leaves[i].id),
            leave: leaves[i],
            index: i,
            onTap: () => _openDetails(leaves[i]),
            onApprove: leaves[i].status.toLowerCase() == 'pending'
                ? () => _approveLeave(leaves[i])
                : null,
            onReject: leaves[i].status.toLowerCase() == 'pending'
                ? () => _rejectLeave(leaves[i])
                : null,
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 185,
      padding: const EdgeInsets.all(16),
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF8A93A1),
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
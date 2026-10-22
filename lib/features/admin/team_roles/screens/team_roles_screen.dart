import 'package:flutter/material.dart';

import '../../../../core/routes/app_routes.dart';
import '../models/team_member_model.dart';
import '../services/team_roles_service.dart';
import '../widgets/add_team_member_dialog.dart';
import '../widgets/role_permissions_dialog.dart';
import '../widgets/team_members_table.dart';

class TeamRolesScreen extends StatefulWidget {
  /// True when shown inside the admin dashboard (the sidebar stays visible).
  final bool embedded;

  const TeamRolesScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<TeamRolesScreen> createState() => _TeamRolesScreenState();
}

class _TeamRolesScreenState extends State<TeamRolesScreen> {
  // Palette copied from AdminDashboardScreen.
  static const Color _primary = Color(0xFFE96832);
  static const Color _textDark = Color(0xFF18212F);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _pageBg = Color(0xFFF7F8FA);
  static const Color _danger = Color(0xFFDC2626);
  static const double _mobileBreakpoint = 700;

  final TeamRolesService _service = TeamRolesService();

  List<TeamMember> _members = const [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  /// Member whose role change / revoke request is in flight.
  String? _busyId;

  bool get _isMobile => MediaQuery.of(context).size.width < _mobileBreakpoint;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ==========================================================
  // DATA
  // ==========================================================

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final data = await _service.fetchTeam();
      if (!mounted) return;
      setState(() {
        _members = data;
        _loading = false;
        _refreshing = false;
        _error = null;
      });
    } on TeamRolesException catch (e) {
      if (!mounted) return;
      if (e.isAuthError) {
        _goToLogin();
        return;
      }
      setState(() {
        _loading = false;
        _refreshing = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _error = 'Something went wrong while loading the team.';
      });
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await _load(silent: true);
  }

  void _goToLogin() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
          (route) => false,
    );
  }

  void _toast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? _danger : null,
        ),
      );
  }

  // ==========================================================
  // ACTIONS
  // ==========================================================

  Future<void> _openPermissions() async {
    final saved = await RolePermissionsDialog.show(context);
    if (saved == true && mounted) {
      _toast('Role permissions saved.');
    }
  }

  Future<void> _openAddMember() async {
    final message = await AddTeamMemberDialog.show(
      context,
      members: _members,
    );

    if (message == null || !mounted) return;

    await _load(silent: true);
    if (!mounted) return;

    _toast(message);
  }

  Future<void> _changeRole(TeamMember member, String role) async {
    if (_busyId != null) return;

    setState(() => _busyId = member.id);

    try {
      await _service.changeRole(member.id, role);
      if (!mounted) return;

      await _load(silent: true);
      if (!mounted) return;

      _toast('${member.name} is now ${TeamRole.label(role)}.');
    } on TeamRolesException catch (e) {
      if (!mounted) return;
      if (e.isAuthError) {
        _goToLogin();
        return;
      }
      _toast(e.message, error: true);
    } catch (_) {
      if (!mounted) return;
      _toast('Could not change the role. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _revoke(TeamMember member) async {
    if (_busyId != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Revoke admin role?'),
        content: Text(
          '${member.name} will lose the ${member.roleLabel} admin role.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: _danger),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busyId = member.id);

    try {
      await _service.revoke(member.id);
      if (!mounted) return;

      await _load(silent: true);
      if (!mounted) return;

      _toast('Admin role revoked for ${member.name}.');
    } on TeamRolesException catch (e) {
      if (!mounted) return;
      if (e.isAuthError) {
        _goToLogin();
        return;
      }
      _toast(e.message, error: true);
    } catch (_) {
      if (!mounted) return;
      _toast('Could not revoke the role. Please try again.', error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    // The core body content
    final bodyContent = SafeArea(child: _buildContent());

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
          'Team & Roles',
          style: TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _refresh,
            icon: _refreshing
                ? const SizedBox(
              width: 19,
              height: 19,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: bodyContent,
    );
  }

  Widget _buildContent() {
    final mobile = _isMobile;

    return RefreshIndicator(
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
            'Company Admin  /  Team & Roles',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: EdgeInsets.all(mobile ? 14 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(mobile),
                SizedBox(height: mobile ? 14 : 20),
                _body(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(bool mobile) {
    final count = _loading || _error != null ? '' : ' (${_members.length})';

    final title = Text(
      'Team Members & Roles$count',
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: _textDark,
      ),
    );

    final permissionsButton = OutlinedButton.icon(
      onPressed: _loading ? null : _openPermissions,
      icon: const Icon(Icons.settings_outlined, size: 17),
      label: const Text('Role Permissions Settings'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _textDark,
        side: const BorderSide(color: Color(0xFFD9DEE7)),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );

    final addButton = FilledButton.icon(
      onPressed: _loading ? null : _openAddMember,
      icon: const Icon(Icons.add, size: 17),
      label: const Text('Add Team Member & Role'),
      style: FilledButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: permissionsButton),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: addButton),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: title),
        const SizedBox(width: 12),
        permissionsButton,
        const SizedBox(width: 12),
        addButton,
      ],
    );
  }

  Widget _body() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
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
                color: _danger,
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
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(backgroundColor: _primary),
            ),
          ],
        ),
      );
    }

    if (_members.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No team members found.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return TeamMembersTable(
      members: _members,
      busyMemberId: _busyId,
      onRoleChanged: _changeRole,
      onRevoke: _revoke,
    );
  }
}
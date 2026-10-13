import 'package:flutter/material.dart';

import '../models/team_member_model.dart';

// Palette copied from AdminDashboardScreen.
const Color _kPrimary = Color(0xFFE96832);
const Color _kBlue = Color(0xFF2878FF);
const Color _kTextDark = Color(0xFF18212F);
const Color _kBorder = Color(0xFFE5E7EB);
const Color _kFieldBorder = Color(0xFFD9DEE7);
const Color _kDanger = Color(0xFFDC2626);
const Color _kMuted = Color(0xFF7A8494);

class TeamMembersTable extends StatelessWidget {
  const TeamMembersTable({
    super.key,
    required this.members,
    required this.onRoleChanged,
    required this.onRevoke,
    this.busyMemberId,
  });

  final List<TeamMember> members;

  /// Called when a member's admin-role dropdown changes.
  final void Function(TeamMember member, String role) onRoleChanged;

  /// Called when Revoke is tapped.
  final ValueChanged<TeamMember> onRevoke;

  /// The member whose request is currently in flight (controls disabled).
  final String? busyMemberId;

  static const double _wideBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _wideBreakpoint;

        return wide ? _buildWide() : _buildCompact();
      },
    );
  }

  // ==========================================================
  // WIDE TABLE
  // ==========================================================

  static const _flex = [2, 3, 4, 3, 5, 3];

  Widget _buildWide() {
    const headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      color: Color(0xFF7B8493),
    );

    Widget headerCell(String text, int flex) => Expanded(
      flex: flex,
      child: Text(text, style: headerStyle),
    );

    return Column(
      children: [
        Container(
          color: const Color(0xFFF3F4F6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              headerCell('CODE', _flex[0]),
              headerCell('MEMBER NAME', _flex[1]),
              headerCell('WORK EMAIL', _flex[2]),
              headerCell('DESIGNATION & DEPT', _flex[3]),
              headerCell('DUAL-ROLE STATUS (EMPLOYEE + ADMIN)', _flex[4]),
              headerCell('PHONE', _flex[5]),
              const SizedBox(width: 96),
            ],
          ),
        ),
        for (var i = 0; i < members.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: Color(0xFFEDEFF3)),
          _wideRow(members[i]),
        ],
      ],
    );
  }

  Widget _wideRow(TeamMember m) {
    final busy = busyMemberId == m.id;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: _flex[0],
            child: Text(
              _value(m.employeeCode),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _kTextDark,
              ),
            ),
          ),
          Expanded(
            flex: _flex[1],
            child: Row(
              children: [
                _Avatar(member: m),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _value(m.name),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kTextDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: _flex[2],
            child: Text(
              _value(m.email),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
          ),
          Expanded(
            flex: _flex[3],
            child: _DesignationText(member: m),
          ),
          Expanded(
            flex: _flex[4],
            child: Row(
              children: [
                const _EmployeeBadge(),
                const SizedBox(width: 8),
                const Text('+', style: TextStyle(color: _kMuted)),
                const SizedBox(width: 8),
                Expanded(
                  child: _RoleCell(
                    member: m,
                    members: members,
                    busy: busy,
                    onChanged: (role) => onRoleChanged(m, role),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
          Expanded(
            flex: _flex[5],
            child: Text(
              _value(m.phone),
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
          ),
          SizedBox(
            width: 96,
            child: m.isOwner
                ? null
                : _RevokeButton(
              busy: busy,
              onPressed: () => onRevoke(m),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // COMPACT LIST (phones / narrow windows)
  // ==========================================================

  Widget _buildCompact() {
    return Column(
      children: [
        for (var i = 0; i < members.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: Color(0xFFEDEFF3)),
          _compactItem(members[i]),
        ],
      ],
    );
  }

  Widget _compactItem(TeamMember m) {
    final busy = busyMemberId == m.id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(member: m),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _value(m.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kTextDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _value(m.employeeCode),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _kMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _value(m.email),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 4),
          Text(
            _value(m.phone),
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 8),
          _DesignationText(member: m),
          const SizedBox(height: 12),
          Row(
            children: [
              const _EmployeeBadge(),
              const SizedBox(width: 8),
              const Text('+', style: TextStyle(color: _kMuted)),
              const SizedBox(width: 8),
              Expanded(
                child: _RoleCell(
                  member: m,
                  members: members,
                  busy: busy,
                  onChanged: (role) => onRoleChanged(m, role),
                ),
              ),
            ],
          ),
          if (!m.isOwner) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: _RevokeButton(
                busy: busy,
                onPressed: () => onRevoke(m),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _value(String v) => v.trim().isEmpty ? '—' : v;
}

// =================================================================
// SMALL PIECES
// =================================================================

class _Avatar extends StatelessWidget {
  const _Avatar({required this.member});

  final TeamMember member;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: member.isOwner ? _kPrimary : _kBlue,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          member.initials,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _DesignationText extends StatelessWidget {
  const _DesignationText({required this.member});

  final TeamMember member;

  @override
  Widget build(BuildContext context) {
    final designation =
    member.designation.trim().isEmpty ? '—' : member.designation;
    final department = member.department.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          designation,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        if (department.isNotEmpty)
          Text(
            department,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: _kMuted),
          ),
      ],
    );
  }
}

/// The grey "Employee" pill that precedes the admin role.
class _EmployeeBadge extends StatelessWidget {
  const _EmployeeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _kMuted, width: 1.2),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'Employee',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}

/// Owner: plain bold text, no dropdown.
/// Everyone else: an admin-role dropdown.
class _RoleCell extends StatelessWidget {
  const _RoleCell({
    required this.member,
    required this.members,
    required this.busy,
    required this.onChanged,
  });

  final TeamMember member;
  final List<TeamMember> members;
  final bool busy;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (member.isOwner) {
      return Text(
        member.roleLabel,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _kTextDark,
        ),
      );
    }

    // Keep the member's current role selectable even if it is not one of the
    // three standard roles (e.g. general_admin), so the dropdown stays valid.
    final roles = <String>[...TeamRole.assignable];
    if (!roles.contains(member.role)) roles.add(member.role);

    bool occupiedByOther(String role) =>
        TeamRole.enforceSingleRolePerCompany &&
            role != member.role &&
            members.any((m) => m.role == role && m.id != member.id);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kFieldBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: member.role,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: _kTextDark),
          icon: busy
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          onChanged: busy
              ? null
              : (value) {
            if (value != null && value != member.role) {
              onChanged(value);
            }
          },
          items: [
            for (final role in roles)
              DropdownMenuItem<String>(
                value: role,
                enabled: !occupiedByOther(role),
                child: Text(
                  occupiedByOther(role)
                      ? '${TeamRole.label(role)} (Occupied)'
                      : TeamRole.label(role),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RevokeButton extends StatelessWidget {
  const _RevokeButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: busy ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: _kDanger,
        side: const BorderSide(color: _kFieldBorder),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      child: const Text('Revoke'),
    );
  }
}
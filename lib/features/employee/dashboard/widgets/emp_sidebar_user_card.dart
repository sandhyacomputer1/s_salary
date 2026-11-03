import 'package:flutter/material.dart';

import '../../../../core/storage/secure_storage.dart';
import '../../../admin/dashboard/services/admin_session_profile_service.dart';
import 'emp_sidebar_style.dart';

/// Name + role of the logged-in employee for the bottom of the sidebar
/// (above "Logout"), like the web:
///
///   [SP]  Sagar Pralhad Patil
///         Employee
///
/// The name is loaded by itself (GET /employees/me). It is remembered in
/// memory per login, so the sidebar does not flicker when the shell rebuilds.
class EmpSidebarUserCard extends StatefulWidget {
  /// true = avatar only (collapsed sidebar)
  final bool collapsed;

  const EmpSidebarUserCard({super.key, this.collapsed = false});

  @override
  State<EmpSidebarUserCard> createState() => _EmpSidebarUserCardState();
}

class _EmpSidebarUserCardState extends State<EmpSidebarUserCard> {
  // remembered per login (the key is the access token, so a new login
  // never shows the previous person's name)
  static String? _cacheKey;
  static AdminSessionProfile? _cache;

  AdminSessionProfile? _me;

  @override
  void initState() {
    super.initState();
    _me = _cache; // show the last known name immediately
    _load();
  }

  Future<void> _load() async {
    String key = '';
    try {
      key = (await SecureStorage.getAccessToken()) ?? '';
    } catch (_) {}

    if (_cacheKey != key) {
      // different login than the cached one -> never show the old name
      _cache = null;
      if (mounted) setState(() => _me = null);
    }

    final profile = await AdminSessionProfileService().load();
    _cacheKey = key;
    _cache = profile;

    if (!mounted) return;
    setState(() => _me = profile);
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;
    final name = me?.name ?? '';
    final role = me?.roleLabel ?? '';
    final initials = me?.initials ?? '';

    final avatar = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: EmpSidebarStyle.primaryTint,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: EmpSidebarStyle.primary,
        ),
      ),
    );

    if (widget.collapsed) {
      return Tooltip(message: '$name · $role', child: avatar);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEFF3)),
      ),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
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
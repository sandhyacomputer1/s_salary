// lib/features/admin/dashboard/widgets/admin_notifications_panel.dart
//
// The small "Notifications" panel that opens under the bell icon
// (same as the web):
//
//   Notifications                          [x]
//   [ View all notifications ]
//   +------------------------------------------+
//   | Software Expiry Details                  |
//   | Duration: 36 months                      |
//   | Start date: 27/10/2026                   |
//   | Valid until: 27 Oct 2029                 |
//   | 1095 days remaining                      |
//   +------------------------------------------+

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../../core/network/api_client.dart';


// =================================================================
// LICENSE DATA  (GET /companies/me -> "license")
// =================================================================

class LicenseInfo {
  final int? durationMonths;
  final DateTime? start;
  final DateTime? end;

  const LicenseInfo({this.durationMonths, this.start, this.end});

  bool get hasData => start != null || end != null || durationMonths != null;

  /// Whole days from today until the licence ends (negative = expired).
  int? get daysRemaining {
    if (end == null) return null;
    final today = DateTime.now();
    final a = DateTime(today.year, today.month, today.day);
    final b = DateTime(end!.year, end!.month, end!.day);
    return b.difference(a).inDays;
  }

  /// Loads the licence of the logged-in company. Never throws.
  static Future<LicenseInfo?> fetch() async {
    try {
      final data = await ApiClient().get('/companies/me');
      final map = _findLicenseMap(data);

      if (map == null) {
        if (kDebugMode) debugPrint('LICENSE: no license field in /companies/me');
        return null;
      }

      // Shows the real field names in the Run console (debug only).
      if (kDebugMode) debugPrint('LICENSE RAW: $map');

      final info = _parse(map);
      return info.hasData ? info : null;
    } catch (e) {
      if (kDebugMode) debugPrint('LICENSE LOAD ERROR: $e');
      return null;
    }
  }

  // The backend may call it license / licence / subscription.
  static Map<String, dynamic>? _findLicenseMap(dynamic node, [int depth = 0]) {
    if (node is! Map || depth > 2) return null;

    for (final key in const ['license', 'licence', 'subscription']) {
      final v = node[key];
      if (v is Map) return Map<String, dynamic>.from(v);
    }
    for (final v in node.values) {
      final found = _findLicenseMap(v, depth + 1);
      if (found != null) return found;
    }
    return null;
  }

  static dynamic _pick(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      if (m[k] != null && m[k].toString().trim().isNotEmpty) return m[k];
    }
    return null;
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    final d = DateTime.tryParse(v.toString());
    return d?.toLocal();
  }

  static int? _months(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    final digits = RegExp(r'\d+').firstMatch(v.toString());
    return digits == null ? null : int.tryParse(digits.group(0)!);
  }

  static DateTime _addMonths(DateTime d, int months) =>
      DateTime(d.year, d.month + months, d.day);

  static LicenseInfo _parse(Map<String, dynamic> m) {
    var start = _date(_pick(m, const [
      'startDate', 'start', 'startsAt', 'startedAt', 'activatedAt',
      'activationDate', 'licenseStart', 'from',
    ]));
    var end = _date(_pick(m, const [
      'endDate', 'end', 'expiryDate', 'expiresAt', 'expiry', 'validUntil',
      'validTill', 'expiresOn', 'endsAt', 'licenseEnd', 'to',
    ]));
    var months = _months(_pick(m, const [
      'durationMonths', 'duration', 'months', 'durationInMonths', 'planMonths',
    ]));

    // fill the gaps from the other two values
    if (end == null && start != null && months != null) {
      end = _addMonths(start, months);
    }
    if (start == null && end != null && months != null) {
      start = _addMonths(end, -months);
    }
    if (months == null && start != null && end != null) {
      months = ((end.difference(start).inDays) / 30.4375).round();
    }

    return LicenseInfo(durationMonths: months, start: start, end: end);
  }
}

/// Number shown on the bell.
int adminNotificationCount({
  required LicenseInfo? license,
  required int pendingLeaves,
  required int pendingExpenses,
}) {
  var n = 0;
  if (license != null && license.hasData) n++;
  if (pendingLeaves > 0) n++;
  if (pendingExpenses > 0) n++;
  return n;
}

// =================================================================
// OPEN THE PANEL
// =================================================================

Future<void> showAdminNotificationsPanel(
    BuildContext context, {
      required LicenseInfo? license,
      required int pendingLeaves,
      required int pendingExpenses,
      required VoidCallback onViewAll,
      required VoidCallback onOpenLeaves,
      required VoidCallback onOpenExpenses,
    }) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close notifications',
    barrierColor: Colors.transparent, // tap outside = close (like the web)
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (dialogContext, _, __) {
      final mq = MediaQuery.of(dialogContext);
      final mobile = mq.size.width < 800;

      // just under the app bar
      final top = (mobile ? mq.padding.top : 0) + kToolbarHeight + 6;

      void closeThen(VoidCallback action) {
        Navigator.of(dialogContext).pop();
        action();
      }

      return Stack(
        children: [
          Positioned(
            top: top,
            right: mobile ? 12 : 16,
            left: mobile ? 12 : null,
            width: mobile ? null : 400,
            child: _NotificationsPanel(
              maxHeight: mq.size.height - top - 16,
              license: license,
              pendingLeaves: pendingLeaves,
              pendingExpenses: pendingExpenses,
              onClose: () => Navigator.of(dialogContext).pop(),
              onViewAll: () => closeThen(onViewAll),
              onOpenLeaves: () => closeThen(onOpenLeaves),
              onOpenExpenses: () => closeThen(onOpenExpenses),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

// =================================================================
// THE PANEL
// =================================================================

class _NotificationsPanel extends StatelessWidget {
  static const Color _textDark = Color(0xFF18212F);
  static const Color _textMedium = Color(0xFF4B5563);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _primary = Color(0xFFE96832);

  final double maxHeight;
  final LicenseInfo? license;
  final int pendingLeaves;
  final int pendingExpenses;
  final VoidCallback onClose;
  final VoidCallback onViewAll;
  final VoidCallback onOpenLeaves;
  final VoidCallback onOpenExpenses;

  const _NotificationsPanel({
    required this.maxHeight,
    required this.license,
    required this.pendingLeaves,
    required this.pendingExpenses,
    required this.onClose,
    required this.onViewAll,
    required this.onOpenLeaves,
    required this.onOpenExpenses,
  });

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      if (license != null && license!.hasData) _LicenseCard(info: license!),
      if (pendingLeaves > 0)
        _SimpleCard(
          icon: Icons.event_note_outlined,
          color: const Color(0xFFE8A317),
          title: 'Pending leave requests',
          text:
          '$pendingLeaves request${pendingLeaves == 1 ? '' : 's'} waiting for approval',
          action: 'Review',
          onTap: onOpenLeaves,
        ),
      if (pendingExpenses > 0)
        _SimpleCard(
          icon: Icons.receipt_long_outlined,
          color: const Color(0xFF7A5AF8),
          title: 'Pending expense claims',
          text:
          '$pendingExpenses claim${pendingExpenses == 1 ? '' : 's'} waiting for approval',
          action: 'Review',
          onTap: onOpenExpenses,
        ),
    ];

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------- header ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 8, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: onClose,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _border),

            // ---------- body ----------
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlinedButton(
                      onPressed: onViewAll,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textDark,
                        side: const BorderSide(color: Color(0xFFD9DEE7)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('View all notifications'),
                    ),
                    const SizedBox(height: 14),
                    if (cards.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 18,
                              color: Color(0xFF18864B),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "You're all caught up.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _textMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      for (var i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        cards[i],
                      ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// "Software Expiry Details" card
// ---------------------------------------------------------------

class _LicenseCard extends StatelessWidget {
  final LicenseInfo info;
  const _LicenseCard({required this.info});

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _dmy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _longDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final days = info.daysRemaining;

    String? remainingText;
    Color remainingColor = const Color(0xFFD9480F);

    if (days != null) {
      if (days < 0) {
        remainingText = 'Expired ${-days} day${days == -1 ? '' : 's'} ago';
        remainingColor = const Color(0xFFC62828);
      } else if (days == 0) {
        remainingText = 'Expires today';
        remainingColor = const Color(0xFFC62828);
      } else {
        remainingText = '$days day${days == 1 ? '' : 's'} remaining';
        if (days > 60) remainingColor = const Color(0xFFD9480F);
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF6D9B0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Software Expiry Details',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF18212F),
            ),
          ),
          const SizedBox(height: 10),
          if (info.durationMonths != null)
            _line('Duration', '${info.durationMonths} months'),
          if (info.start != null) _line('Start date', _dmy(info.start!)),
          if (info.end != null)
            _line('Valid until', _longDate(info.end!), bold: true),
          if (remainingText != null) ...[
            const SizedBox(height: 4),
            Text(
              remainingText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: remainingColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _line(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: Color(0xFF4B5563)),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: bold ? const Color(0xFF18212F) : const Color(0xFF4B5563),
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
        style: const TextStyle(fontSize: 13, height: 1.3),
      ),
    );
  }
}

// ---------------------------------------------------------------
// Small card for pending leaves / expenses
// ---------------------------------------------------------------

class _SimpleCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String text;
  final String action;
  final VoidCallback onTap;

  const _SimpleCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 19, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF18212F),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              action,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
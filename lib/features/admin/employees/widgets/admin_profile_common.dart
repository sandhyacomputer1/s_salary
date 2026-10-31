import 'package:flutter/material.dart';

import '../models/admin_employee_model.dart';
import 'admin_employee_theme.dart';

// ----------------------------------------------------------------
// formatting helpers
// ----------------------------------------------------------------

/// "full_time" -> "Full Time"
String adminProfTitle(String v) {
  if (v.trim().isEmpty) return '—';
  return v
      .replaceAll('_', ' ')
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

String adminProfOrDash(String v) => v.trim().isEmpty ? '—' : v;

/// "10:24 AM" (device time zone).
String adminProfTime(DateTime? d) {
  if (d == null) return '—';
  final l = d.toLocal();
  final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
  final m = l.minute.toString().padLeft(2, '0');
  return '$h:$m ${l.hour >= 12 ? 'PM' : 'AM'}';
}

/// "30 Oct 2026, 10:24 AM"
String adminProfDateTime(DateTime? d) {
  if (d == null) return '—';
  return '${adminEmpFormatDate(d.toLocal())}, ${adminProfTime(d)}';
}

const List<String> _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String adminProfMonthName(int m) => _monthNames[(m - 1).clamp(0, 11)];

String adminProfHours(double h) => h.toStringAsFixed(1);

// ----------------------------------------------------------------
// card + section title
// ----------------------------------------------------------------

class AdminProfileCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Gradient? gradient;

  const AdminProfileCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? Colors.white : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEFF3)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }
}

class AdminProfileSectionTitle extends StatelessWidget {
  final String text;
  const AdminProfileSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AdminEmpColors.text,
      ),
    );
  }
}

class AdminProfileSmallCaps extends StatelessWidget {
  final String text;
  const AdminProfileSmallCaps(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
        color: AdminEmpColors.muted,
      ),
    );
  }
}

// ----------------------------------------------------------------
// label / value grid  (EMPLOYEE CODE / EMP-0003 ...)
// ----------------------------------------------------------------

class AdminInfoGrid extends StatelessWidget {
  final List<(String, String)> items;

  /// Columns on wide screens (6 = like the web header).
  final int maxColumns;

  const AdminInfoGrid({super.key, required this.items, this.maxColumns = 6});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 1000
            ? maxColumns
            : c.maxWidth >= 640
            ? (maxColumns > 3 ? 3 : maxColumns)
            : 2;
        const gap = 16.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: 20,
          children: [
            for (final it in items)
              SizedBox(
                width: w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminProfileSmallCaps(it.$1),
                    const SizedBox(height: 6),
                    Text(
                      it.$2,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AdminEmpColors.text,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

// ----------------------------------------------------------------
// misc
// ----------------------------------------------------------------

class AdminProfileEmpty extends StatelessWidget {
  final String text;
  final IconData icon;
  const AdminProfileEmpty(this.text, {super.key, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 34, color: const Color(0xFFB8BFCA)),
            const SizedBox(height: 10),
            Text(text, style: const TextStyle(color: AdminEmpColors.muted, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

/// Colored pill for statuses (approved, pending, paid ...).
class AdminStatusPill extends StatelessWidget {
  final String status;
  const AdminStatusPill(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    Color fg;
    Color bg;

    if (['approved', 'paid', 'present', 'active'].contains(s)) {
      fg = const Color(0xFF15803D);
      bg = const Color(0xFFE9F8EF);
    } else if (['pending', 'generated', 'draft', 'half_day', 'late'].contains(s)) {
      fg = const Color(0xFFB45309);
      bg = const Color(0xFFFFF6E5);
    } else if (['rejected', 'cancelled', 'absent', 'terminated'].contains(s)) {
      fg = const Color(0xFFC62828);
      bg = const Color(0xFFFDECEC);
    } else if (['on_leave', 'leave'].contains(s)) {
      fg = const Color(0xFF6D4AE0);
      bg = const Color(0xFFF1EEFF);
    } else {
      fg = AdminEmpColors.muted;
      bg = const Color(0xFFF1F2F4);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        adminProfTitle(status),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

/// "‹  October 2026  ›"
class AdminMonthSwitcher extends StatelessWidget {
  final int month;
  final int year;
  final void Function(int month, int year) onChanged;

  const AdminMonthSwitcher({
    super.key,
    required this.month,
    required this.year,
    required this.onChanged,
  });

  void _shift(int delta) {
    var m = month + delta;
    var y = year;
    if (m < 1) {
      m = 12;
      y--;
    } else if (m > 12) {
      m = 1;
      y++;
    }
    onChanged(m, y);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrent = month == now.month && year == now.year;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminEmpColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => _shift(-1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          SizedBox(
            width: 140,
            child: Text(
              '${adminProfMonthName(month)} $year',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: isCurrent ? null : () => _shift(1),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

/// Header row + rows for simple tables. Falls back to cards on phones.
class AdminSimpleTable extends StatelessWidget {
  final List<String> headers;
  final List<int> flex;
  final List<List<Widget>> rows;

  /// Builds the phone layout for row [index].
  final Widget Function(int index) compactBuilder;

  const AdminSimpleTable({
    super.key,
    required this.headers,
    required this.flex,
    required this.rows,
    required this.compactBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 640) {
          return Column(
            children: [
              for (var i = 0; i < rows.length; i++) compactBuilder(i),
            ],
          );
        }

        return Column(
          children: [
            Container(
              color: AdminEmpColors.headerBg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  for (var i = 0; i < headers.length; i++)
                    Expanded(flex: flex[i], child: AdminProfileSmallCaps(headers[i])),
                ],
              ),
            ),
            for (var r = 0; r < rows.length; r++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    for (var i = 0; i < rows[r].length; i++)
                      Expanded(
                        flex: flex[i],
                        child: Align(alignment: Alignment.centerLeft, child: rows[r][i]),
                      ),
                  ],
                ),
              ),
              if (r != rows.length - 1) const Divider(height: 1, color: AdminEmpColors.border),
            ],
          ],
        );
      },
    );
  }
}

/// Loads data once, shows spinner / error+retry / content.
class AdminProfileFuture<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;

  const AdminProfileFuture({super.key, required this.load, required this.builder});

  @override
  State<AdminProfileFuture<T>> createState() => _AdminProfileFutureState<T>();
}

class _AdminProfileFutureState<T> extends State<AdminProfileFuture<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  void _retry() => setState(() => _future = widget.load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: CircularProgressIndicator(color: AdminEmpColors.primary)),
          );
        }

        if (snap.hasError) {
          final msg = snap.error.toString().replaceFirst('Exception: ', '');
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AdminEmpColors.danger, size: 34),
                  const SizedBox(height: 10),
                  Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: AdminEmpColors.muted)),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _retry,
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return widget.builder(context, snap.data as T);
      },
    );
  }
}

/// "Approve" (orange) + "Reject" (white / red) for pending requests.
/// [onApprove] / [onReject] do the API call; errors are shown as a snackbar.
class AdminApproveRejectButtons extends StatefulWidget {
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;

  const AdminApproveRejectButtons({
    super.key,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<AdminApproveRejectButtons> createState() => _AdminApproveRejectButtonsState();
}

class _AdminApproveRejectButtonsState extends State<AdminApproveRejectButtons> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() job) async {
    setState(() => _busy = true);
    try {
      await job();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AdminEmpColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2, color: AdminEmpColors.primary),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton(
          onPressed: () => _run(widget.onApprove),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 38),
            backgroundColor: AdminEmpColors.primary,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Approve', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
        OutlinedButton(
          onPressed: () => _run(widget.onReject),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 38),
            foregroundColor: AdminEmpColors.danger,
            side: const BorderSide(color: AdminEmpColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Reject', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
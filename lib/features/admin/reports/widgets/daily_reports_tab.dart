// lib/features/admin/reports/widgets/daily_reports_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../attendance_notifications/utils/notification_theme.dart';
import '../models/report_models.dart';
import '../repositories/report_repository.dart';
import 'report_details_dialog.dart';

const double _kMobileBreakpoint = 700;

class DailyReportsTab extends ConsumerStatefulWidget {
  const DailyReportsTab({super.key});
  @override
  ConsumerState<DailyReportsTab> createState() => _DailyReportsTabState();
}

class _DailyReportsTabState extends ConsumerState<DailyReportsTab> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(dailyReportsFilterProvider);
    final async = ref.watch(dailyReportsProvider);
    final mobile = MediaQuery.sizeOf(context).width < _kMobileBreakpoint;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: NotificationColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              mobile ? 14 : 22,
              mobile ? 16 : 20,
              mobile ? 14 : 22,
              mobile ? 14 : 16,
            ),
            child: LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth > 700;

              final title = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Employee Daily Work Submissions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'View End-of-Day (EOD) work logs submitted by team members',
                    style: NotificationText.emptySubtitle,
                  ),
                ],
              );

              final searchField = TextField(
                controller: _search,
                onChanged: (v) {
                  ref.read(dailyReportsFilterProvider.notifier).state =
                      DailyReportsFilter(date: filter.date, search: v);
                },
                decoration: InputDecoration(
                  hintText: 'Search employee, department...',
                  hintStyle: NotificationText.emptySubtitle,
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded, size: 19),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                style: const TextStyle(fontSize: 13),
              );

              final refreshBtn = OutlinedButton(
                onPressed: () => ref.invalidate(dailyReportsProvider),
                style: OutlinedButton.styleFrom(
                  foregroundColor: NotificationColors.textDark,
                  side: const BorderSide(color: NotificationColors.border),
                  minimumSize: const Size(0, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text('Refresh'),
              );

              if (wide) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    title,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 240, child: searchField),
                        const SizedBox(width: 10),
                        refreshBtn,
                      ],
                    ),
                  ],
                );
              }

              // phone: search takes the free width, Refresh sits beside it
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: searchField),
                      const SizedBox(width: 10),
                      refreshBtn,
                    ],
                  ),
                ],
              );
            }),
          ),
          const Divider(height: 1),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(60),
              child: Center(
                child: CircularProgressIndicator(
                  color: NotificationColors.primary,
                ),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(30),
              child: Column(children: [
                const Icon(
                  Icons.error_outline,
                  color: NotificationColors.danger,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  e.toString().replaceFirst('Exception: ', ''),
                  style: NotificationText.emptySubtitle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(dailyReportsProvider),
                  style: FilledButton.styleFrom(
                    backgroundColor: NotificationColors.primary,
                  ),
                  child: const Text('Retry'),
                ),
              ]),
            ),
            data: (reports) {
              if (reports.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(60),
                  child: Center(
                    child: Text(
                      'No work reports available.',
                      style: NotificationText.emptySubtitle,
                    ),
                  ),
                );
              }

              // phone -> cards, web / tablet -> table
              return mobile
                  ? _ReportCards(reports: reports)
                  : _ReportTable(reports: reports);
            },
          ),
        ],
      ),
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

void _openDetails(BuildContext context, DailyWorkReport r) {
  showDialog(
    context: context,
    builder: (_) => ReportDetailsDialog(report: r),
  );
}

// =================================================================
// PHONE: one card per report
// =================================================================

class _ReportCards extends StatelessWidget {
  final List<DailyWorkReport> reports;
  const _ReportCards({required this.reports});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          for (final r in reports) ...[
            _ReportCard(r: r),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final DailyWorkReport r;
  const _ReportCard({required this.r});

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (r.employeeCode.isNotEmpty) r.employeeCode,
      if (r.department.isNotEmpty) r.department,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NotificationColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // date + details button
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F8F1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _fmtDate(r.date),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: NotificationTableColors.checkIn,
                  ),
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () => _openDetails(context, r),
                style: OutlinedButton.styleFrom(
                  foregroundColor: NotificationColors.textDark,
                  side: const BorderSide(color: NotificationColors.border),
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text('View Details'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // employee
          Text(
            r.employeeName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          if (r.designation.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(
              r.designation,
              style: NotificationText.emptySubtitle.copyWith(fontSize: 11.5),
            ),
          ],
          if (subtitleParts.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitleParts.join('  •  '),
              style: NotificationText.emptySubtitle.copyWith(fontSize: 11.5),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          _labelled('COMPLETED WORK', r.completedWork),
          const SizedBox(height: 10),
          _labelled(
            'ONGOING / NEXT PLAN',
            r.ongoingTasks,
          ),
        ],
      ),
    );
  }

  Widget _labelled(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: NotificationColors.textLight,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value.isEmpty ? '—' : value,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.5, height: 1.35),
        ),
      ],
    );
  }
}

// =================================================================
// WEB / TABLET: table (unchanged)
// =================================================================

class _ReportTable extends StatelessWidget {
  final List<DailyWorkReport> reports;
  const _ReportTable({required this.reports});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use available width, but never shrink below 1100 (so text doesn't crush)
        final tableWidth =
        constraints.maxWidth > 1100 ? constraints.maxWidth : 1100.0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(children: [
              Container(
                color: NotificationTableColors.headerBg,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: const [
                  _H('DATE', flex: 130),
                  _H('EMPLOYEE', flex: 240),
                  _H('DEPT & CODE', flex: 200),
                  _H('COMPLETED WORK', flex: 260),
                  _H('ONGOING / NEXT PLAN', flex: 260),
                  _H('ACTION', flex: 90),
                ]),
              ),
              for (int i = 0; i < reports.length; i++)
                _ReportRow(r: reports[i], alt: i.isOdd),
            ]),
          ),
        );
      },
    );
  }
}

class _H extends StatelessWidget {
  final String text;
  final int flex;
  const _H(this.text, {required this.flex});
  @override
  Widget build(BuildContext context) => Expanded(
    flex: flex,
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: NotificationColors.textLight,
      ),
    ),
  );
}

class _ReportRow extends StatelessWidget {
  final DailyWorkReport r;
  final bool alt;
  const _ReportRow({required this.r, required this.alt});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: alt ? NotificationTableColors.rowAlt : Colors.white,
        border: const Border(
          bottom: BorderSide(color: NotificationColors.border),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 130,
          child: Text(
            _fmtDate(r.date),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: NotificationTableColors.checkIn,
            ),
          ),
        ),
        Expanded(
          flex: 240,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.employeeName,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (r.designation.isNotEmpty)
                Text(
                  r.designation,
                  style: NotificationText.emptySubtitle.copyWith(fontSize: 11),
                ),
            ],
          ),
        ),
        Expanded(
          flex: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.employeeCode,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (r.department.isNotEmpty)
                Text(
                  r.department,
                  style: NotificationText.emptySubtitle.copyWith(fontSize: 11),
                ),
            ],
          ),
        ),
        Expanded(
          flex: 260,
          child: Text(
            r.completedWork.isEmpty ? '—' : r.completedWork,
            style: const TextStyle(fontSize: 12),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 260,
          child: Text(
            r.ongoingTasks.isEmpty ? '—' : 'Plan: ${r.ongoingTasks}',
            style: const TextStyle(fontSize: 12),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 90,
          child: OutlinedButton(
            onPressed: () => _openDetails(context, r),
            style: OutlinedButton.styleFrom(
              foregroundColor: NotificationColors.textDark,
              side: const BorderSide(color: NotificationColors.border),
              minimumSize: const Size(0, 30),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('View Details'),
          ),
        ),
      ]),
    );
  }
}
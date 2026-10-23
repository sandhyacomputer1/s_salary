// lib/features/admin/reports/widgets/daily_reports_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../attendance_notifications/utils/notification_theme.dart';
import '../models/report_models.dart';
import '../repositories/report_repository.dart';
import 'report_details_dialog.dart';

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
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
            child: LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth > 700;
              final title = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Employee Daily Work Submissions',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text(
                      'View End-of-Day (EOD) work logs submitted by team members',
                      style: NotificationText.emptySubtitle),
                ],
              );
              final controls = Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  width: 240,
                  height: 36,
                  child: TextField(
                    controller: _search,
                    onChanged: (v) {
                      ref.read(dailyReportsFilterProvider.notifier).state =
                          DailyReportsFilter(date: filter.date, search: v);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search employee, department...',
                      hintStyle: NotificationText.emptySubtitle,
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () => ref.invalidate(dailyReportsProvider),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NotificationColors.textDark,
                    side: const BorderSide(color: NotificationColors.border),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text('Refresh'),
                ),
              ]);
              return wide
                  ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [title, controls])
                  : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 12),
                    controls
                  ]);
            }),
          ),
          const Divider(height: 1),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(60),
              child: Center(
                  child: CircularProgressIndicator(
                      color: NotificationColors.primary)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(40),
              child: Column(children: [
                const Icon(Icons.error_outline,
                    color: NotificationColors.danger, size: 40),
                const SizedBox(height: 12),
                Text(e.toString(),
                    style: NotificationText.emptySubtitle,
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(dailyReportsProvider),
                  style: FilledButton.styleFrom(
                      backgroundColor: NotificationColors.primary),
                  child: const Text('Retry'),
                ),
              ]),
            ),
            data: (reports) {
              if (reports.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(60),
                  child: Center(
                      child: Text('No work reports available.',
                          style: NotificationText.emptySubtitle)),
                );
              }
              return _ReportTable(reports: reports);
            },
          ),
        ],
      ),
    );
  }
}

class _ReportTable extends StatelessWidget {
  final List<DailyWorkReport> reports;
  const _ReportTable({required this.reports});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use available width, but never shrink below 1100 (so text doesn't crush)
        final tableWidth = constraints.maxWidth > 1100 ? constraints.maxWidth : 1100.0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(children: [
              Container(
                color: NotificationTableColors.headerBg,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    child: Text(text,
        style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: NotificationColors.textLight)),
  );
}

class _ReportRow extends StatelessWidget {
  final DailyWorkReport r;
  final bool alt;
  const _ReportRow({required this.r, required this.alt});

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      // FIXED: Removed `color:` and moved it into `decoration:`
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
            child: Text(_fmtDate(r.date),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: NotificationTableColors.checkIn))),
        Expanded(
            flex: 240,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.employeeName,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700)),
                if (r.designation.isNotEmpty)
                  Text(r.designation,
                      style: NotificationText.emptySubtitle
                          .copyWith(fontSize: 11)),
              ],
            )),
        Expanded(
            flex: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.employeeCode,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                if (r.department.isNotEmpty)
                  Text(r.department,
                      style: NotificationText.emptySubtitle
                          .copyWith(fontSize: 11)),
              ],
            )),
        Expanded(
            flex: 260,
            child: Text(
              r.completedWork.isEmpty ? '—' : r.completedWork,
              style: const TextStyle(fontSize: 12),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            )),
        Expanded(
            flex: 260,
            child: Text(
              r.ongoingTasks.isEmpty ? '—' : 'Plan: ${r.ongoingTasks}',
              style: const TextStyle(fontSize: 12),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            )),
        Expanded(
            flex: 90,
            child: OutlinedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ReportDetailsDialog(report: r),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: NotificationColors.textDark,
                side: const BorderSide(color: NotificationColors.border),
                minimumSize: const Size(0, 30),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: const TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
              child: const Text('View Details'),
            )),
      ]),
    );
  }
}
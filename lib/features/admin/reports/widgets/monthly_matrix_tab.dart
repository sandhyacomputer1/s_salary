// // lib/features/admin/reports/widgets/monthly_matrix_tab.dart
//
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../attendance_notifications/utils/notification_theme.dart';
// import '../models/report_models.dart';
// import '../repositories/report_repository.dart';
// import '../utils/csv_exporter.dart';
// import '../utils/matrix_printer.dart';
// import 'manual_mark_dialog.dart';
//
// class MonthlyMatrixTab extends ConsumerWidget {
//   const MonthlyMatrixTab({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final sel = ref.watch(selectedMonthProvider);
//     final async = ref.watch(monthlyMatrixProvider);
//
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: NotificationColors.border),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           _Header(sel: sel),
//           const Divider(height: 1),
//           async.when(
//             loading: () => const Padding(
//               padding: EdgeInsets.all(60),
//               child: Center(
//                   child: CircularProgressIndicator(
//                       color: NotificationColors.primary)),
//             ),
//             error: (e, _) => Padding(
//               padding: const EdgeInsets.all(40),
//               child: Column(children: [
//                 const Icon(Icons.error_outline,
//                     color: NotificationColors.danger, size: 40),
//                 const SizedBox(height: 12),
//                 Text(e.toString(),
//                     style: NotificationText.emptySubtitle),
//                 const SizedBox(height: 16),
//                 FilledButton(
//                   style: FilledButton.styleFrom(
//                       backgroundColor: NotificationColors.primary),
//                   onPressed: () async {
//                     final rows = await ref.read(monthlyMatrixProvider.future);
//                     final ok = await CsvExporter.exportMatrix(
//                       rows: rows,
//                       month: sel.month,
//                       year: sel.year,
//                     );
//                     if (context.mounted) {
//                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                         // Changed text to Excel
//                         content: Text(ok ? 'Excel file downloaded' : 'Export failed'),
//                       ));
//                     }
//                   },
//                   // Changed button text
//                   child: const Text('Export Matrix Excel'),
//                 ),              ]),
//             ),
//             data: (rows) {
//               if (rows.isEmpty) {
//                 return const Padding(
//                   padding: EdgeInsets.all(60),
//                   child: Center(
//                       child: Text('No attendance data for this month.',
//                           style: NotificationText.emptySubtitle)),
//                 );
//               }
//               return _Matrix(rows: rows, sel: sel);
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _Header extends ConsumerWidget {
//   final SelectedMonth sel;
//   const _Header({required this.sel});
//
//   static const _months = [
//     'January', 'February', 'March', 'April', 'May', 'June',
//     'July', 'August', 'September', 'October', 'November', 'December'
//   ];
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
//       child: LayoutBuilder(builder: (context, c) {
//         final wide = c.maxWidth > 900;
//         final title = Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: const [
//             Text('Monthly Attendance Matrix Spreadsheet',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
//             SizedBox(height: 4),
//             Text(
//               "Day-by-day attendance grid for all active employees "
//                   "(P = Present, L = Late, HD = Half Day, LV = Leave, "
//                   "H = Holiday, WO = Week Off, A = Absent)",
//               style: NotificationText.emptySubtitle,
//             ),
//           ],
//         );
//
//         final actions = Wrap(
//           spacing: 8,
//           runSpacing: 8,
//           children: [
//             _Dropdown(
//               value: _months[sel.month - 1],
//               items: _months,
//               onChanged: (m) {
//                 final i = _months.indexOf(m!) + 1;
//                 ref.read(selectedMonthProvider.notifier).state =
//                     SelectedMonth(i, sel.year);
//               },
//             ),
//             _Dropdown(
//               value: sel.year.toString(),
//               items: List.generate(5, (i) => (DateTime.now().year - 2 + i).toString()),
//               onChanged: (y) {
//                 ref.read(selectedMonthProvider.notifier).state =
//                     SelectedMonth(sel.month, int.parse(y!));
//               },
//             ),
//             OutlinedButton(
//               onPressed: () => showDialog(
//                 context: context,
//                 builder: (_) => const ManualMarkDialog(),
//               ),
//               style: _outline,
//               child: const Text('Manual Mark'),
//             ),
//             FilledButton(
//               style: FilledButton.styleFrom(
//                   backgroundColor: NotificationColors.primary),
//               onPressed: () async {
//                 final rows = await ref.read(monthlyMatrixProvider.future);
//                 final ok = await CsvExporter.exportMatrix(
//                   rows: rows,
//                   month: sel.month,
//                   year: sel.year,
//                 );
//                 if (context.mounted) {
//                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                     content: Text(ok ? 'CSV downloaded' : 'CSV export failed'),
//                   ));
//                 }
//               },
//               child: const Text('Export Matrix CSV'),
//             ),
//             OutlinedButton(
//               onPressed: () => _printMatrix(context, ref, sel),
//               style: _outline,
//               child: const Text('Print Report'),
//             ),
//           ],
//         );
//
//         return wide
//             ? Row(crossAxisAlignment: CrossAxisAlignment.center,
//             children: [Expanded(child: title), actions])
//             : Column(crossAxisAlignment: CrossAxisAlignment.start,
//             children: [title, const SizedBox(height: 16), actions]);
//       }),
//     );
//   }
//
//   static final _outline = OutlinedButton.styleFrom(
//     foregroundColor: NotificationColors.textDark,
//     side: const BorderSide(color: NotificationColors.border),
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
//     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
//   );
//
//   Future<void> _printMatrix(BuildContext context, WidgetRef ref, SelectedMonth sel) async {
//     final rows = await ref.read(monthlyMatrixProvider.future);
//     try {
//       await MatrixPrinter.print(rows, sel);
//     } catch (e) {
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Print failed: $e')),
//         );
//       }
//     }
//   }
// }
//
// class _Dropdown extends StatelessWidget {
//   final String value;
//   final List<String> items;
//   final ValueChanged<String?> onChanged;
//   const _Dropdown({required this.value, required this.items, required this.onChanged});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 36,
//       padding: const EdgeInsets.symmetric(horizontal: 10),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(color: NotificationColors.border),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           value: value,
//           items: items.map((v) => DropdownMenuItem(value: v, child:
//           Text(v, style: const TextStyle(fontSize: 13)))).toList(),
//           onChanged: onChanged,
//           icon: const Icon(Icons.keyboard_arrow_down, size: 18),
//           style: const TextStyle(color: NotificationColors.textDark, fontSize: 13),
//         ),
//       ),
//     );
//   }
// }
//
// class _Matrix extends StatelessWidget {
//   final List<MonthlyMatrixRow> rows;
//   final SelectedMonth sel;
//
//   const _Matrix({required this.rows, required this.sel});
//
//   @override
//   Widget build(BuildContext context) {
//     final days = DateTime(sel.year, sel.month + 1, 0).day;
//
//     final ScrollController horizontalScrollController = ScrollController();
//     final ScrollController verticalScrollController = ScrollController();
//
//     // Reduced widths: Employee 180, Code 100
//     final totalWidth = 180 + 100 + days * 34.0 + 9 * 44.0;
//
//     return Scrollbar(
//       controller: horizontalScrollController,
//       thumbVisibility: true,
//       trackVisibility: true,
//       scrollbarOrientation: ScrollbarOrientation.bottom,
//       thickness: 12.0,
//       child: SingleChildScrollView(
//         controller: horizontalScrollController,
//         scrollDirection: Axis.horizontal,
//         child: Scrollbar(
//           controller: verticalScrollController,
//           thumbVisibility: true,
//           child: SingleChildScrollView(
//             controller: verticalScrollController,
//             scrollDirection: Axis.vertical,
//             child: SizedBox(
//               width: totalWidth,
//               height: 550,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   _HeaderRow(days: days),
//                   for (final r in rows) _DataRow(row: r, days: days, sel: sel),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _HeaderRow extends StatelessWidget {
//   final int days;
//   const _HeaderRow({required this.days});
//
//   @override
//   Widget build(BuildContext context) {
//     const h = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: NotificationColors.textLight);
//     return Container(
//       color: NotificationTableColors.headerBg,
//       height: 34,
//       child: Row(children: [
//         _cell(w: 180, child: const Text('EMPLOYEE', style: h)), // Reduced to 180
//         _cell(w: 100, child: const Text('CODE', style: h)),     // Increased to 100
//         for (int d = 1; d <= days; d++)
//           _cell(w: 34, child: Text('$d', style: h, textAlign: TextAlign.center)),
//         for (final lbl in ['P', 'L', 'HD', 'LV', 'H', 'WO', 'A', 'HOURS'])
//           _cell(w: 44, child: Text(lbl, style: h, textAlign: TextAlign.center)),
//       ]),
//     );
//   }
//
//   static Widget _cell({required double w, required Widget child}) => SizedBox(
//     width: w,
//     height: 34,
//     child: Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 8),
//       child: Align(alignment: Alignment.centerLeft, child: child),
//     ),
//   );
// }
//
// class _DataRow extends StatelessWidget {
//   final MonthlyMatrixRow row;
//   final int days;
//   final SelectedMonth sel;
//   const _DataRow({required this.row, required this.days, required this.sel});
//
//   Color _bg(String? code) {
//     switch (code) {
//       case 'P':  return const Color(0xFFE7F8F1);
//       case 'L':  return const Color(0xFFFFF6E0);
//       case 'HD': return const Color(0xFFE3F0FF);
//       case 'LV': return const Color(0xFFF3E8FF);
//       case 'H':  return const Color(0xFFE0F2FE);
//       case 'WO': return const Color(0xFFF1F5F9);
//       case 'A':  return const Color(0xFFFDECEA);
//       default:   return Colors.transparent;
//     }
//   }
//
//   Color _fg(String? code) {
//     switch (code) {
//       case 'P':  return const Color(0xFF0F7A40);
//       case 'L':  return const Color(0xFFB45309);
//       case 'HD': return const Color(0xFF1D4ED8);
//       case 'LV': return const Color(0xFF7E22CE);
//       case 'H':  return const Color(0xFF0369A1);
//       case 'WO': return const Color(0xFF64748B);
//       case 'A':  return const Color(0xFFB91C1C);
//       default:   return NotificationColors.textDark;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 46,
//       decoration: const BoxDecoration(
//         border: Border(bottom: BorderSide(color: NotificationColors.border)),
//       ),
//       child: Row(children: [
//         SizedBox(
//           width: 180, // Reduced to 180
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(row.employeeName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
//                 Text(row.department, style: NotificationText.emptySubtitle.copyWith(fontSize: 10.5)),
//               ],
//             ),
//           ),
//         ),
//         SizedBox(
//           width: 100, // Increased to 100
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8),
//             child: Text(row.employeeCode, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
//           ),
//         ),
//         for (int d = 1; d <= days; d++)
//           _dayCell(context, row.dailyStatus[d], d),
//         _numCell(row.present, row.present > 0 ? const Color(0xFF0F7A40) : null),
//         _numCell(row.late,    row.late > 0    ? const Color(0xFFB45309) : null),
//         _numCell(row.halfDay, row.halfDay > 0 ? const Color(0xFF1D4ED8) : null),
//         _numCell(row.leave,   row.leave > 0   ? const Color(0xFF7E22CE) : null),
//         _numCell(row.holiday, row.holiday > 0 ? const Color(0xFF0369A1) : null),
//         _numCell(row.weekOff, row.weekOff > 0 ? const Color(0xFF64748B) : null),
//         _numCell(row.absent,  row.absent > 0  ? const Color(0xFFB91C1C) : null),
//         SizedBox(
//           width: 44,
//           height: 46,
//           child: Center(
//             child: Text(
//               '${row.hours.toStringAsFixed(2)}h',
//               style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
//             ),
//           ),
//         ),
//       ]),
//     );
//   }
//
//   Widget _dayCell(BuildContext context, String? code, int day) {
//     final bg = _bg(code);
//     final fg = _fg(code);
//     return InkWell(
//       onTap: () {
//         final pickedDate = DateTime(sel.year, sel.month, day);
//         showDialog(
//           context: context,
//           builder: (_) => ManualMarkDialog(
//             initialEmployeeId: row.employeeId,
//             initialDate: pickedDate,
//           ),
//         );
//       },
//       child: Container(
//         width: 34,
//         height: 46,
//         alignment: Alignment.center,
//         decoration: BoxDecoration(
//           color: bg,
//           border: const Border(left: BorderSide(color: NotificationColors.border, width: 0.5)),
//         ),
//         child: Text(
//           (code == '-' || code == null) ? '–' : code,
//           style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
//         ),
//       ),
//     );
//   }
//
//   Widget _numCell(int n, Color? color) => SizedBox(
//     width: 44, height: 46,
//     child: Center(
//       child: Text('$n', style: TextStyle(
//           fontSize: 11.5, fontWeight: FontWeight.w600, color: color ?? NotificationColors.textDark)),
//     ),
//   );
// }


// lib/features/admin/reports/widgets/monthly_matrix_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../attendance_notifications/utils/notification_theme.dart';
import '../models/report_models.dart';
import '../repositories/report_repository.dart';
import '../utils/csv_exporter.dart';
import '../utils/matrix_printer.dart';
import 'manual_mark_dialog.dart';

class MonthlyMatrixTab extends ConsumerWidget {
  const MonthlyMatrixTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = ref.watch(selectedMonthProvider);
    final async = ref.watch(monthlyMatrixProvider);

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
          _Header(sel: sel),
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
                    style: NotificationText.emptySubtitle),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(monthlyMatrixProvider),
                  style: FilledButton.styleFrom(
                      backgroundColor: NotificationColors.primary),
                  child: const Text('Retry'),
                ),
              ]),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(60),
                  child: Center(
                      child: Text('No attendance data for this month.',
                          style: NotificationText.emptySubtitle)),
                );
              }
              return _Matrix(rows: rows, sel: sel);
            },
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final SelectedMonth sel;
  const _Header({required this.sel});

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth > 900;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Monthly Attendance Matrix Spreadsheet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            SizedBox(height: 4),
            Text(
              "Day-by-day attendance grid for all active employees "
                  "(P = Present, L = Late, HD = Half Day, LV = Leave, "
                  "H = Holiday, WO = Week Off, A = Absent)",
              style: NotificationText.emptySubtitle,
            ),
          ],
        );

        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Dropdown(
              value: _months[sel.month - 1],
              items: _months,
              onChanged: (m) {
                final i = _months.indexOf(m!) + 1;
                ref.read(selectedMonthProvider.notifier).state =
                    SelectedMonth(i, sel.year);
              },
            ),
            _Dropdown(
              value: sel.year.toString(),
              items: List.generate(5, (i) => (DateTime.now().year - 2 + i).toString()),
              onChanged: (y) {
                ref.read(selectedMonthProvider.notifier).state =
                    SelectedMonth(sel.month, int.parse(y!));
              },
            ),
            OutlinedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const ManualMarkDialog(),
              ),
              style: _outline,
              child: const Text('Manual Mark'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: NotificationColors.primary),
              onPressed: () async {
                final rows = await ref.read(monthlyMatrixProvider.future);
                final ok = await CsvExporter.exportMatrix(
                  rows: rows,
                  month: sel.month,
                  year: sel.year,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? 'Excel file downloaded successfully' : 'Export failed'),
                  ));
                }
              },
              child: const Text('Export Matrix Excel'), // Updated text
            ),
            OutlinedButton(
              onPressed: () => _printMatrix(context, ref, sel),
              style: _outline,
              child: const Text('Print Report'),
            ),
          ],
        );

        return wide
            ? Row(crossAxisAlignment: CrossAxisAlignment.center,
            children: [Expanded(child: title), actions])
            : Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 16), actions]);
      }),
    );
  }

  static final _outline = OutlinedButton.styleFrom(
    foregroundColor: NotificationColors.textDark,
    side: const BorderSide(color: NotificationColors.border),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
  );

  Future<void> _printMatrix(BuildContext context, WidgetRef ref, SelectedMonth sel) async {
    final rows = await ref.read(monthlyMatrixProvider.future);
    try {
      await MatrixPrinter.print(rows, sel);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }
}

class _Dropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _Dropdown({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: NotificationColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items.map((v) => DropdownMenuItem(value: v, child:
          Text(v, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: const TextStyle(color: NotificationColors.textDark, fontSize: 13),
        ),
      ),
    );
  }
}

class _Matrix extends StatelessWidget {
  final List<MonthlyMatrixRow> rows;
  final SelectedMonth sel;

  const _Matrix({required this.rows, required this.sel});

  @override
  Widget build(BuildContext context) {
    final days = DateTime(sel.year, sel.month + 1, 0).day;

    final ScrollController horizontalScrollController = ScrollController();
    final ScrollController verticalScrollController = ScrollController();

    final totalWidth = 180 + 100 + days * 34.0 + 9 * 44.0;

    return Scrollbar(
      controller: horizontalScrollController,
      thumbVisibility: true,
      trackVisibility: true,
      scrollbarOrientation: ScrollbarOrientation.bottom,
      thickness: 12.0,
      child: SingleChildScrollView(
        controller: horizontalScrollController,
        scrollDirection: Axis.horizontal,
        child: Scrollbar(
          controller: verticalScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: verticalScrollController,
            scrollDirection: Axis.vertical,
            child: SizedBox(
              width: totalWidth,
              height: 550,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeaderRow(days: days),
                  for (final r in rows) _DataRow(row: r, days: days, sel: sel),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final int days;
  const _HeaderRow({required this.days});

  @override
  Widget build(BuildContext context) {
    const h = TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: NotificationColors.textLight);
    return Container(
      color: NotificationTableColors.headerBg,
      height: 34,
      child: Row(children: [
        _cell(w: 180, child: const Text('EMPLOYEE', style: h)),
        _cell(w: 100, child: const Text('CODE', style: h)),
        for (int d = 1; d <= days; d++)
          _cell(w: 34, child: Text('$d', style: h, textAlign: TextAlign.center)),
        for (final lbl in ['P', 'L', 'HD', 'LV', 'H', 'WO', 'A', 'HOURS'])
          _cell(w: 44, child: Text(lbl, style: h, textAlign: TextAlign.center)),
      ]),
    );
  }

  static Widget _cell({required double w, required Widget child}) => SizedBox(
    width: w,
    height: 34,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Align(alignment: Alignment.centerLeft, child: child),
    ),
  );
}

class _DataRow extends StatelessWidget {
  final MonthlyMatrixRow row;
  final int days;
  final SelectedMonth sel;
  const _DataRow({required this.row, required this.days, required this.sel});

  Color _bg(String? code) {
    switch (code) {
      case 'P':  return const Color(0xFFE7F8F1);
      case 'L':  return const Color(0xFFFFF6E0);
      case 'HD': return const Color(0xFFE3F0FF);
      case 'LV': return const Color(0xFFF3E8FF);
      case 'H':  return const Color(0xFFE0F2FE);
      case 'WO': return const Color(0xFFF1F5F9);
      case 'A':  return const Color(0xFFFDECEA);
      default:   return Colors.transparent;
    }
  }

  Color _fg(String? code) {
    switch (code) {
      case 'P':  return const Color(0xFF0F7A40);
      case 'L':  return const Color(0xFFB45309);
      case 'HD': return const Color(0xFF1D4ED8);
      case 'LV': return const Color(0xFF7E22CE);
      case 'H':  return const Color(0xFF0369A1);
      case 'WO': return const Color(0xFF64748B);
      case 'A':  return const Color(0xFFB91C1C);
      default:   return NotificationColors.textDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: NotificationColors.border)),
      ),
      child: Row(children: [
        SizedBox(
          width: 180,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(row.employeeName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                Text(row.department, style: NotificationText.emptySubtitle.copyWith(fontSize: 10.5)),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 100,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(row.employeeCode, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
          ),
        ),
        for (int d = 1; d <= days; d++)
          _dayCell(context, row.dailyStatus[d], d),
        _numCell(row.present, row.present > 0 ? const Color(0xFF0F7A40) : null),
        _numCell(row.late,    row.late > 0    ? const Color(0xFFB45309) : null),
        _numCell(row.halfDay, row.halfDay > 0 ? const Color(0xFF1D4ED8) : null),
        _numCell(row.leave,   row.leave > 0   ? const Color(0xFF7E22CE) : null),
        _numCell(row.holiday, row.holiday > 0 ? const Color(0xFF0369A1) : null),
        _numCell(row.weekOff, row.weekOff > 0 ? const Color(0xFF64748B) : null),
        _numCell(row.absent,  row.absent > 0  ? const Color(0xFFB91C1C) : null),
        SizedBox(
          width: 44,
          height: 46,
          child: Center(
            child: Text(
              '${row.hours.toStringAsFixed(2)}h',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _dayCell(BuildContext context, String? code, int day) {
    final bg = _bg(code);
    final fg = _fg(code);
    return InkWell(
      onTap: () {
        final pickedDate = DateTime(sel.year, sel.month, day);
        showDialog(
          context: context,
          builder: (_) => ManualMarkDialog(
            initialEmployeeId: row.employeeId,
            initialDate: pickedDate,
          ),
        );
      },
      child: Container(
        width: 34,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          border: const Border(left: BorderSide(color: NotificationColors.border, width: 0.5)),
        ),
        child: Text(
          (code == '-' || code == null) ? '–' : code,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
        ),
      ),
    );
  }

  Widget _numCell(int n, Color? color) => SizedBox(
    width: 44, height: 46,
    child: Center(
      child: Text('$n', style: TextStyle(
          fontSize: 11.5, fontWeight: FontWeight.w600, color: color ?? NotificationColors.textDark)),
    ),
  );
}
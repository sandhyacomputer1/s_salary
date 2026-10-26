// lib/features/admin/reports/widgets/monthly_matrix_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../attendance_notifications/utils/notification_theme.dart';
import '../models/report_models.dart';
import '../repositories/report_repository.dart';
import '../utils/csv_exporter.dart';
import '../utils/matrix_printer.dart';
import 'manual_mark_dialog.dart';

const double _kMobileBreakpoint = 700;

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
                  textAlign: TextAlign.center,
                  style: NotificationText.emptySubtitle,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(monthlyMatrixProvider),
                  style: FilledButton.styleFrom(
                    backgroundColor: NotificationColors.primary,
                  ),
                  child: const Text('Retry'),
                ),
              ]),
            ),
            data: (rows) {
              if (rows.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(60),
                  child: Center(
                    child: Text(
                      'No attendance data for this month.',
                      textAlign: TextAlign.center,
                      style: NotificationText.emptySubtitle,
                    ),
                  ),
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

// =================================================================
// HEADER  (title + month / year / buttons)
// =================================================================

class _Header extends ConsumerWidget {
  final SelectedMonth sel;
  const _Header({required this.sel});

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = MediaQuery.sizeOf(context).width < _kMobileBreakpoint;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobile ? 14 : 22,
        mobile ? 16 : 20,
        mobile ? 14 : 22,
        mobile ? 14 : 16,
      ),
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth > 900;

        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Monthly Attendance Matrix Spreadsheet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 4),
            Text(
              "Day-by-day attendance grid for all active employees "
                  "(P = Present, L = Late, HD = Half Day, LV = Leave, "
                  "H = Holiday, WO = Week Off, A = Absent)",
              style: NotificationText.emptySubtitle,
            ),
          ],
        );

        // ---------- the controls ----------
        final monthDropdown = _Dropdown(
          value: _months[sel.month - 1],
          items: _months,
          expand: !wide,
          onChanged: (m) {
            final i = _months.indexOf(m!) + 1;
            ref.read(selectedMonthProvider.notifier).state =
                SelectedMonth(i, sel.year);
          },
        );

        final yearDropdown = _Dropdown(
          value: sel.year.toString(),
          items: List.generate(
            5,
                (i) => (DateTime.now().year - 2 + i).toString(),
          ),
          expand: !wide,
          onChanged: (y) {
            ref.read(selectedMonthProvider.notifier).state =
                SelectedMonth(sel.month, int.parse(y!));
          },
        );

        final manualBtn = OutlinedButton(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => const ManualMarkDialog(),
          ),
          style: _outline,
          child: const Text('Manual Mark'),
        );

        final exportBtn = FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: NotificationColors.primary,
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          onPressed: () async {
            final rows = await ref.read(monthlyMatrixProvider.future);
            final ok = await CsvExporter.exportMatrix(
              rows: rows,
              month: sel.month,
              year: sel.year,
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  ok ? 'Excel file downloaded successfully' : 'Export failed',
                ),
              ));
            }
          },
          child: const Text('Export Matrix Excel'),
        );

        final printBtn = OutlinedButton(
          onPressed: () => _printMatrix(context, ref, sel),
          style: _outline,
          child: const Text('Print Report'),
        );

        // ---------- web ----------
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: title),
              const SizedBox(width: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  monthDropdown,
                  yearDropdown,
                  manualBtn,
                  exportBtn,
                  printBtn,
                ],
              ),
            ],
          );
        }

        // ---------- phone / tablet ----------
        //  [ October      v ] [ 2026 v ]
        //  [ Manual Mark    ] [ Print Report ]
        //  [      Export Matrix Excel        ]
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title,
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(flex: 3, child: monthDropdown),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: yearDropdown),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: manualBtn),
                const SizedBox(width: 10),
                Expanded(child: printBtn),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: exportBtn),
          ],
        );
      }),
    );
  }

  static final _outline = OutlinedButton.styleFrom(
    foregroundColor: NotificationColors.textDark,
    side: const BorderSide(color: NotificationColors.border),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    minimumSize: const Size(0, 42),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
  );

  Future<void> _printMatrix(
      BuildContext context,
      WidgetRef ref,
      SelectedMonth sel,
      ) async {
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

  /// true -> fills the width it is given (phone layout)
  final bool expand;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: NotificationColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: expand,
          items: items
              .map(
                (v) => DropdownMenuItem(
              value: v,
              child: Text(v, style: const TextStyle(fontSize: 13.5)),
            ),
          )
              .toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: const TextStyle(
            color: NotificationColors.textDark,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }
}

// =================================================================
// MATRIX  (employee column stays fixed, days scroll sideways)
// =================================================================

class _Matrix extends StatefulWidget {
  final List<MonthlyMatrixRow> rows;
  final SelectedMonth sel;

  const _Matrix({required this.rows, required this.sel});

  @override
  State<_Matrix> createState() => _MatrixState();
}

class _MatrixState extends State<_Matrix> {
  static const double _rowH = 46;
  static const double _headH = 34;
  static const double _dayW = 34;
  static const double _totalW = 44;
  static const double _hoursW = 64;

  final ScrollController _headScroll = ScrollController(); // header (follows body)
  final ScrollController _bodyH = ScrollController(); // days / totals
  final ScrollController _vertical = ScrollController();

  @override
  void initState() {
    super.initState();

    // keep the header in step with the body when scrolling sideways
    _bodyH.addListener(() {
      if (_headScroll.hasClients && _headScroll.offset != _bodyH.offset) {
        final max = _headScroll.position.maxScrollExtent;
        _headScroll.jumpTo(_bodyH.offset.clamp(0.0, max));
      }
    });
  }

  @override
  void dispose() {
    _headScroll.dispose();
    _bodyH.dispose();
    _vertical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.rows;
    final sel = widget.sel;

    final mobile = MediaQuery.sizeOf(context).width < _kMobileBreakpoint;
    final days = DateTime(sel.year, sel.month + 1, 0).day;

    final pinnedW = mobile ? 150.0 : 280.0;
    final scrollW = days * _dayW + 7 * _totalW + _hoursW;

    final maxBody = mobile ? 460.0 : 520.0;
    final bodyH = (rows.length * _rowH).clamp(_rowH, maxBody).toDouble();

    return SizedBox(
      height: _headH + bodyH,
      child: Column(
        children: [
          // ---------------- header ----------------
          SizedBox(
            height: _headH,
            child: Row(
              children: [
                Container(
                  width: pinnedW,
                  height: _headH,
                  color: NotificationTableColors.headerBg,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.centerLeft,
                  child: mobile
                      ? const Text('EMPLOYEE', style: _headStyle)
                      : Row(
                    children: const [
                      SizedBox(
                        width: 168,
                        child: Text('EMPLOYEE', style: _headStyle),
                      ),
                      Text('CODE', style: _headStyle),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _headScroll,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      width: scrollW,
                      child: _HeaderRow(days: days),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---------------- body ----------------
          Expanded(
            child: Scrollbar(
              controller: _vertical,
              child: SingleChildScrollView(
                controller: _vertical,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // fixed employee column
                    Container(
                      width: pinnedW,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          right: BorderSide(color: NotificationColors.border),
                        ),
                      ),
                      child: Column(
                        children: [
                          for (final r in rows)
                            _PinnedCell(row: r, mobile: mobile),
                        ],
                      ),
                    ),
                    // scrolling days + totals
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _bodyH,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: scrollW,
                          child: Column(
                            children: [
                              for (final r in rows)
                                _DataRow(row: r, days: days, sel: sel),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _headStyle = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    color: NotificationColors.textLight,
  );
}

class _HeaderRow extends StatelessWidget {
  final int days;
  const _HeaderRow({required this.days});

  @override
  Widget build(BuildContext context) {
    const h = TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      color: NotificationColors.textLight,
    );

    return Container(
      color: NotificationTableColors.headerBg,
      height: 34,
      child: Row(children: [
        for (int d = 1; d <= days; d++)
          _cell(w: 34, child: Text('$d', style: h, textAlign: TextAlign.center)),
        for (final lbl in ['P', 'L', 'HD', 'LV', 'H', 'WO', 'A'])
          _cell(w: 44, child: Text(lbl, style: h, textAlign: TextAlign.center)),
        _cell(w: 64, child: const Text('HOURS', style: h)),
      ]),
    );
  }

  static Widget _cell({required double w, required Widget child}) => SizedBox(
    width: w,
    height: 34,
    child: Center(child: child),
  );
}

/// Employee name + code (stays fixed on the left).
class _PinnedCell extends StatelessWidget {
  final MonthlyMatrixRow row;
  final bool mobile;
  const _PinnedCell({required this.row, required this.mobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: NotificationColors.border)),
      ),
      child: mobile
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            row.employeeName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            row.employeeCode,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: NotificationText.emptySubtitle.copyWith(fontSize: 10.5),
          ),
        ],
      )
          : Row(
        children: [
          SizedBox(
            width: 168,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  row.employeeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  row.department,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NotificationText.emptySubtitle
                      .copyWith(fontSize: 10.5),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              row.employeeCode,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Days + totals of one employee.
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
          width: 64,
          height: 46,
          child: Center(
            child: Text(
              '${row.hours.toStringAsFixed(2)}h',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
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
          border: const Border(
            left: BorderSide(color: NotificationColors.border, width: 0.5),
          ),
        ),
        child: Text(
          (code == '-' || code == null) ? '–' : code,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }

  Widget _numCell(int n, Color? color) => SizedBox(
    width: 44,
    height: 46,
    child: Center(
      child: Text(
        '$n',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color ?? NotificationColors.textDark,
        ),
      ),
    ),
  );
}
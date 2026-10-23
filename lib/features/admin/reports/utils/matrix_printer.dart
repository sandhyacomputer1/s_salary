// lib/features/admin/reports/utils/matrix_printer.dart

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/report_models.dart';
import '../repositories/report_repository.dart';

class MatrixPrinter {
  static Future<void> print(List<MonthlyMatrixRow> rows, SelectedMonth sel) async {
    final doc = pw.Document();
    final days = DateTime(sel.year, sel.month + 1, 0).day;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (ctx) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Monthly Attendance Matrix Spreadsheet', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text('${_monthName(sel.month)} ${sel.year} · P=Present, L=Late, HD=Half Day, LV=Leave, H=Holiday, WO=Week Off, A=Absent', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              pw.SizedBox(height: 12),
            ],
          ),
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            headerStyle: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['Employee', 'Code', for (int d = 1; d <= days; d++) '$d', 'P', 'L', 'HD', 'LV', 'H', 'WO', 'A', 'Hrs'],
            data: [
              for (final r in rows)
                [r.employeeName, r.employeeCode, for (int d = 1; d <= days; d++) r.dailyStatus[d] ?? '–', '${r.present}', '${r.late}', '${r.halfDay}', '${r.leave}', '${r.holiday}', '${r.weekOff}', '${r.absent}', r.hours.toStringAsFixed(2)],
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save(), name: 'Attendance_Matrix_${_monthName(sel.month)}_${sel.year}');
  }

  static String _monthName(int m) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];
}
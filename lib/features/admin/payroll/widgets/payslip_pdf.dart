import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/payroll_slip_model.dart';
import 'payroll_format.dart';

/// Builds a payslip PDF from the slip data on screen and opens the system
/// print / save sheet (Download PDF / Print).
///
/// The rupee sign needs a font that contains it, so Noto Sans is fetched on
/// first use. If that fails (offline), the PDF still works and uses "Rs.".
class PayslipPdf {
  PayslipPdf._();

  static Future<void> open(PayrollSlip slip) async {
    pw.Font? base;
    pw.Font? bold;
    var symbol = '₹';

    try {
      base = await PdfGoogleFonts.notoSansRegular();
      bold = await PdfGoogleFonts.notoSansBold();
    } catch (_) {
      symbol = 'Rs. ';
    }

    final document = pw.Document(
      theme: (base != null && bold != null)
          ? pw.ThemeData.withFont(base: base, bold: bold)
          : null,
    );

    String money(double value) =>
        PayrollFormat.rupees2(value).replaceFirst('₹', symbol);

    String show(String value) => value.trim().isEmpty ? '-' : value.trim();

    pw.Widget cell(
      String text, {
      bool bold = false,
      bool right = false,
      PdfColor? color,
    }) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: pw.Text(
          text,
          textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      );
    }

    final earnings = <(String, double)>[
      ('Basic Salary', slip.baseSalary),
      ('Allowances', slip.allowancesTotal),
      ('Expense Claims / Reimbursements', slip.expenseReimbursement),
    ];

    final deductions = <(String, double)>[
      (
        'Unpaid Absence Cut (${slip.unpaidLeaveDays} days)',
        slip.absenceDeduction,
      ),
      ('Late Penalty Cut (${slip.lateDays} lates)', slip.lateDeduction),
      ('Professional Tax (PT)', slip.ptDeduction),
      ('Provident Fund (PF 5%)', slip.pfDeduction),
      for (final d in slip.ruleDeductions)
        (d.ruleName.isEmpty ? 'Rule deduction' : d.ruleName, d.amount),
    ];

    final rowCount = earnings.length > deductions.length
        ? earnings.length
        : deductions.length;

    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          cell('Earnings', bold: true),
          cell('Amount', bold: true, right: true),
          cell('Deductions', bold: true),
          cell('Amount', bold: true, right: true),
        ],
      ),
      for (var i = 0; i < rowCount; i++)
        pw.TableRow(
          children: [
            cell(i < earnings.length ? earnings[i].$1 : '-'),
            cell(
              i < earnings.length ? money(earnings[i].$2) : '-',
              right: true,
            ),
            cell(i < deductions.length ? deductions[i].$1 : '-'),
            cell(
              i < deductions.length ? money(deductions[i].$2) : '-',
              right: true,
            ),
          ],
        ),
      pw.TableRow(
        children: [
          cell('Gross Salary', bold: true),
          cell(money(slip.grossSalary), bold: true, right: true),
          cell('Total Deductions', bold: true),
          cell(money(slip.totalDeductions), bold: true, right: true),
        ],
      ),
    ];

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Text(
                  'Payslip for ${PayrollFormat.monthName(slip.month)} ${slip.year}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Divider(color: PdfColors.deepOrange, thickness: 1.5),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Employee: ${show(slip.employeeName)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Employee Code: ${show(slip.employeeCode)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Designation: ${show(slip.designation)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Text(
                    'Department: ${show(slip.department)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: const {
                  0: pw.FlexColumnWidth(4),
                  1: pw.FlexColumnWidth(3),
                  2: pw.FlexColumnWidth(4),
                  3: pw.FlexColumnWidth(3),
                },
                children: rows,
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Net Salary Payable:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    money(slip.netSalary),
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final fileName =
        'Payslip-'
        '${show(slip.employeeCode == '' ? slip.employeeName : slip.employeeCode)}'
        '-${PayrollFormat.monthName(slip.month)}-${slip.year}.pdf';

    await Printing.layoutPdf(
      name: fileName.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_'),
      onLayout: (format) async => document.save(),
    );
  }
}

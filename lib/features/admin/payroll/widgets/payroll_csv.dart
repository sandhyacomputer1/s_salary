// lib/features/admin/payroll/widgets/payroll_csv.dart

import 'package:excel_plus/excel_plus.dart';
import '../models/payroll_slip_model.dart';
import 'payroll_format.dart';

class PayrollCsv {
  PayrollCsv._();

  static List<int> buildExcel(List<PayrollSlip> slips) {
    final excel = Excel.createExcel();
    final sheet = excel['Payroll'];

    // 1. Define the headers
    final headers = [
      'Employee Code', 'Employee Name', 'Department', 'Designation', 'Month/Year',
      'Month Days', 'Present Days', 'Absent Days', 'Late Count', 'Base Salary (INR)',
      'Allowances (INR)', 'Reimbursements (INR)', 'Gross Salary (INR)',
      'Absence Cut (INR)', 'Late Cut (INR)', 'PT Deduction (INR)',
      'Total Deductions (INR)', 'Net Salary (INR)',
    ];

    // Add headers to row 0
    for (var col = 0; col < headers.length; col++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).value = TextCellValue(headers[col]);
    }

    // 2. Add the data
    for (var row = 0; row < slips.length; row++) {
      final s = slips[row];
      final totalDeductions = s.grossSalary - s.netSalary;
      final rowData = [
        s.employeeCode,
        s.employeeName,
        s.department,
        s.designation,
        '${PayrollFormat.monthName(s.month)} ${s.year}',
        s.daysInMonth.toString(),
        s.presentDays.toString(),
        s.absentDays.toString(),
        s.lateDays.toString(),
        s.baseSalary.toStringAsFixed(2),
        s.allowancesTotal.toStringAsFixed(2),
        s.expenseReimbursement.toStringAsFixed(2),
        s.grossSalary.toStringAsFixed(2),
        s.absenceDeduction.toStringAsFixed(2),
        s.lateDeduction.toStringAsFixed(2),
        s.ptDeduction.toStringAsFixed(2),
        totalDeductions.toStringAsFixed(2),
        s.netSalary.toStringAsFixed(2),
      ];

      for (var col = 0; col < rowData.length; col++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1)).value = TextCellValue(rowData[col]);
      }
    }

    // 3. Auto-fit column widths
    for (var col = 0; col < headers.length; col++) {
      sheet.setColumnWidth(col, 20.0);
    }

    // 4. Delete the default empty "Sheet1"
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // THE MAGIC FIX: Get raw bytes without triggering internal save
    final fileBytes = excel.encode();
    if (fileBytes == null) throw Exception("Could not generate Excel file");
    return fileBytes;
  }
}
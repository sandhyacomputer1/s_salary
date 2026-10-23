// // lib/features/admin/reports/utils/csv_exporter.dart
//
// import 'dart:io' show File;
// import 'package:excel_plus/excel_plus.dart';
// import 'package:flutter/foundation.dart';
// import 'package:path_provider/path_provider.dart';
// import '../models/report_models.dart';
// import 'csv_export_web_stub.dart'
// if (dart.library.html) 'csv_export_web_real.dart' as platform;
//
// class CsvExporter {
//   static Future<bool> exportMatrix({
//     required List<MonthlyMatrixRow> rows,
//     required int month,
//     required int year,
//   }) async {
//     final days = DateTime(year, month + 1, 0).day;
//     final filename = 'Attendance_Matrix_${_monthName(month)}_$year.xlsx';
//
//     try {
//       // 1. Create the Excel file
//       final excel = Excel.createExcel();
//       final sheet = excel['Attendance'];
//
//       // 2. Set up headers
//       final headers = <String>[
//         'Employee', 'Code', 'Department',
//         for (int d = 1; d <= days; d++) '$d',
//         'P', 'L', 'HD', 'LV', 'H', 'WO', 'A', 'Hours',
//       ];
//
//       for (var col = 0; col < headers.length; col++) {
//         sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).value = TextCellValue(headers[col]);
//       }
//
//       // 3. Fill the data
//       for (var row = 0; row < rows.length; row++) {
//         final r = rows[row];
//         final rowData = <String>[
//           r.employeeName,
//           r.employeeCode,
//           r.department,
//           for (int d = 1; d <= days; d++) r.dailyStatus[d] ?? '',
//           r.present.toString(),
//           r.late.toString(),
//           r.halfDay.toString(),
//           r.leave.toString(),
//           r.holiday.toString(),
//           r.weekOff.toString(),
//           r.absent.toString(),
//           r.hours.toStringAsFixed(2),
//         ];
//
//         for (var col = 0; col < rowData.length; col++) {
//           sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1)).value = TextCellValue(rowData[col]);
//         }
//       }
//
//       // 4. Auto-fit columns
//       for (var col = 0; col < headers.length; col++) {
//         sheet.setColumnWidth(col, 15.0);
//       }
//       sheet.setColumnWidth(0, 30.0); // Wider employee name
//
//       // 5. Delete default Sheet1
//       if (excel.sheets.containsKey('Sheet1')) {
//         excel.delete('Sheet1');
//       }
//
//       // THE MAGIC FIX: Get the raw bytes WITHOUT triggering the library's save
//       final fileBytes = excel.encode();
//       if (fileBytes == null) return false;
//
//       // 6. Download ONLY ONCE
//       if (kIsWeb) {
//         return await platform.downloadBytes(filename, fileBytes);
//       } else {
//         final dir = await getApplicationDocumentsDirectory();
//         final file = File('${dir.path}/$filename');
//         await file.writeAsBytes(fileBytes);
//         return true;
//       }
//     } catch (e) {
//       debugPrint('Excel export failed: $e');
//       return false;
//     }
//   }
//
//   static String _monthName(int m) => const [
//     'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
//     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
//   ][m - 1];
// }




// lib/features/admin/reports/utils/csv_exporter.dart

import 'dart:io' show File;
import 'package:excel_plus/excel_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/report_models.dart';
import 'csv_export_web_stub.dart'
if (dart.library.html) 'csv_export_web_real.dart' as platform;

class CsvExporter {
  static Future<bool> exportMatrix({
    required List<MonthlyMatrixRow> rows,
    required int month,
    required int year,
  }) async {
    final days = DateTime(year, month + 1, 0).day;
    final filename = 'Attendance_Matrix_${_monthName(month)}_$year.xlsx';

    try {
      // 1. Create the Excel file
      final excel = Excel.createExcel();
      final sheet = excel['Attendance'];

      // 2. Set up headers
      final headers = <String>[
        'Employee', 'Code', 'Department',
        for (int d = 1; d <= days; d++) '$d',
        'P', 'L', 'HD', 'LV', 'H', 'WO', 'A', 'Hours',
      ];

      for (var col = 0; col < headers.length; col++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0)).value = TextCellValue(headers[col]);
      }

      // 3. Fill the data
      for (var row = 0; row < rows.length; row++) {
        final r = rows[row];

        final rowData = <String>[
          r.employeeName,
          r.employeeCode,
          r.department,
          for (int d = 1; d <= days; d++) r.dailyStatus[d] ?? '',
          r.present.toString(),
          r.late.toString(),
          r.halfDay.toString(),
          r.leave.toString(),
          r.holiday.toString(),
          r.weekOff.toString(),
          r.absent.toString(),
          r.hours.toStringAsFixed(2),
        ];

        for (var col = 0; col < rowData.length; col++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 1)).value = TextCellValue(rowData[col]);
        }
      }

      // 4. Auto-fit columns
      for (var col = 0; col < headers.length; col++) {
        sheet.setColumnWidth(col, 15.0);
      }
      // Make employee name wider
      sheet.setColumnWidth(0, 30.0);

      // 5. Delete default empty Sheet1
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // 6. Get raw bytes (prevents double download)
      final fileBytes = excel.encode();
      if (fileBytes == null) return false;

      // 7. Download only once
      if (kIsWeb) {
        return await platform.downloadBytes(filename, fileBytes);
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(fileBytes);
        return true;
      }
    } catch (e) {
      debugPrint('Excel export failed: $e');
      return false;
    }
  }

  static String _monthName(int m) => const [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ][m - 1];
}
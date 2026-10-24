// lib/features/employee/salary/utils/payslip_viewer_web.dart

import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'payslip_viewer_base.dart';

/// IMPORTANT: this must be called directly inside the click handler,
/// BEFORE any `await`, otherwise the browser blocks the popup.
PayslipViewer createPayslipViewer() => _WebPayslipViewer();

class _WebPayslipViewer implements PayslipViewer {
  final web.Window? _win = web.window.open('', '_blank');

  @override
  Future<void> show(
      String html, {
        required int month,
        required int year,
      }) async {
    final w = _win;
    if (w == null) {
      throw Exception(
        'Popup blocked. Please allow popups for this site and try again.',
      );
    }

    final doc = w.document;
    doc.open();
    doc.write(html.toJS);
    doc.close();

    // Open the print dialog like the web app does (unless the HTML already
    // triggers it by itself).
    if (!html.contains('window.print')) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      w.focus();
      w.print();
    }
  }

  @override
  void cancel() => _win?.close();
}
// lib/features/employee/salary/utils/payslip_viewer_base.dart

abstract class PayslipViewer {
  /// Show the payslip HTML (web: new tab + print dialog).
  Future<void> show(String html, {required int month, required int year});

  /// Called when fetching the HTML failed (web: closes the blank tab).
  void cancel();
}
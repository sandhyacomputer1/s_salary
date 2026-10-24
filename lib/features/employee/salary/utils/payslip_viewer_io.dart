// lib/features/employee/salary/utils/payslip_viewer_io.dart

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'payslip_viewer_base.dart';

PayslipViewer createPayslipViewer() => _IoPayslipViewer();

class _IoPayslipViewer implements PayslipViewer {
  @override
  Future<void> show(
      String html, {
        required int month,
        required int year,
      }) async {
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/payslip_${year}_${month.toString().padLeft(2, '0')}.html',
    );
    await file.writeAsString(html);

    final ok = await launchUrl(
      Uri.file(file.path),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
      throw Exception('Could not open the payslip in a viewer.');
    }
  }

  @override
  void cancel() {}
}
// lib/features/employee/salary/utils/payslip_viewer.dart
//
// Picks the right implementation per platform:
//   web            -> payslip_viewer_web.dart (new tab + print dialog)
//   android/ios/... -> payslip_viewer_io.dart  (temp file + external viewer)

export 'payslip_viewer_base.dart';
export 'payslip_viewer_io.dart'
if (dart.library.js_interop) 'payslip_viewer_web.dart';
// Web  -> real file download.
// Mobile/desktop -> falls back to copying the CSV text to the clipboard.
export 'admin_csv_download_stub.dart'
if (dart.library.html) 'admin_csv_download_web.dart';
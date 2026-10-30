import 'package:flutter/services.dart';

/// Returns true when a file was downloaded, false when the CSV was only
/// copied to the clipboard (non-web platforms).
Future<bool> adminSaveCsv(String fileName, String content) async {
  await Clipboard.setData(ClipboardData(text: content));
  return false;
}
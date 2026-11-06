import 'dart:convert';
import 'package:web/web.dart' as web;

Future<String?> saveLocalFile(String fileName, List<int> bytes) async {
  final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  final anchor = web.HTMLAnchorElement()
    ..href = 'data:application/octet-stream;base64,${base64Encode(bytes)}'
    ..download = safeName;
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  return '$safeName (browser download requested)';
}

import 'dart:io';

Future<String?> saveLocalFile(String fileName, List<int> bytes) async {
  final userProfile = Platform.environment['USERPROFILE'];
  final home = Platform.environment['HOME'];
  final downloadsPath = userProfile != null
      ? '$userProfile\\Downloads'
      : home != null
      ? '$home/Downloads'
      : Directory.systemTemp.path;
  final downloads = Directory(downloadsPath);
  final destination = downloads.existsSync()
      ? downloads
      : Directory(Directory.systemTemp.path);
  final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  final file = File('${destination.path}${Platform.pathSeparator}$safeName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

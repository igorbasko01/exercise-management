import 'dart:io';

import 'package:exercise_management/core/result.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'export_sink.dart';

ExportSink createPlatformExportSink() => IoExportSink();

/// Writes the exported zip to the platform's Downloads folder, or the
/// documents directory on platforms without one.
class IoExportSink implements ExportSink {
  @override
  Future<Result<ExportLocation>> store(
      String fileName, List<int> bytes) async {
    try {
      final downloadsDir = await _downloadsDirectory();
      final filePath = p.join(downloadsDir.path, fileName);
      await File(filePath).writeAsBytes(bytes);

      return Result.ok(
          ExportLocation(description: downloadsDir.path, filePath: filePath));
    } catch (e) {
      return Result.error(ExportException('Error saving file: $e'));
    }
  }

  Future<Directory> _downloadsDirectory() async {
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else {
      return await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
    }
  }
}

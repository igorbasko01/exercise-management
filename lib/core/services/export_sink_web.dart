import 'dart:convert';

import 'package:exercise_management/core/result.dart';
import 'package:web/web.dart' as web;

import 'export_sink.dart';

ExportSink createPlatformExportSink() => WebExportSink();

/// Triggers a browser download of the exported zip via a data: URI anchor
/// click. There is no real filesystem path on web, so [ExportLocation]
/// carries a human-readable description only.
class WebExportSink implements ExportSink {
  @override
  Future<Result<ExportLocation>> store(
      String fileName, List<int> bytes) async {
    try {
      final base64Data = base64Encode(bytes);
      final anchor = web.HTMLAnchorElement()
        ..href = 'data:application/zip;base64,$base64Data'
        ..download = fileName;
      web.document.body?.appendChild(anchor);
      anchor.click();
      anchor.remove();

      return Result.ok(
          const ExportLocation(description: "your browser's downloads"));
    } catch (e) {
      return Result.error(ExportException('Error saving file: $e'));
    }
  }
}

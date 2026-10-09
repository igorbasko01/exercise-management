import 'package:exercise_management/core/base_exception.dart';
import 'package:exercise_management/core/result.dart';

import 'export_sink_stub.dart'
    if (dart.library.js_interop) 'export_sink_web.dart'
    if (dart.library.io) 'export_sink_io.dart' as platform;

/// Puts an exported backup file somewhere the user can get to it. Platform
/// specific (filesystem on IO, a browser download on web), selected via
/// [createExportSink] so callers depend only on this interface.
abstract class ExportSink {
  Future<Result<ExportLocation>> store(String fileName, List<int> bytes);
}

/// Where [ExportSink.store] put the file, in terms the UI can show on any
/// platform. [filePath] is only populated where the platform exposes a real
/// filesystem path (used to build a share sheet on IO platforms).
class ExportLocation {
  const ExportLocation({required this.description, this.filePath});

  final String description;
  final String? filePath;
}

ExportSink createExportSink() => platform.createPlatformExportSink();

class ExportException implements BaseException {
  @override
  final String message;

  ExportException(this.message);

  @override
  String toString() => 'ExportException: $message';
}

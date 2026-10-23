import 'backup_file_sink.dart';
import 'backup_file_sink_io.dart'
    if (dart.library.js_interop) 'backup_file_sink_web.dart' as platform;

/// Creates the [BackupFileSink] implementation for the current platform: the
/// device's downloads folder on Android/iOS, a browser download on web.
BackupFileSink createBackupFileSink() => platform.createBackupFileSink();

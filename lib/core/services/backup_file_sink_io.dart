import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'backup_file_sink.dart';

BackupFileSink createBackupFileSink() => IoBackupFileSink();

/// Saves backups to the device's downloads folder and shares them with
/// the platform share sheet.
class IoBackupFileSink implements BackupFileSink {
  @override
  Future<SavedBackup> save(String fileName, List<int> bytes) async {
    final downloadsDir = await _getDownloadsDirectory();
    final filePath = path.join(downloadsDir.path, fileName);
    await File(filePath).writeAsBytes(bytes);
    return SavedBackup(
      fileName: fileName,
      location: '${downloadsDir.path} folder',
      path: filePath,
    );
  }

  @override
  bool get canShare => true;

  @override
  Future<void> share(SavedBackup backup) async {
    final filePath = backup.path;
    if (filePath == null) {
      throw ArgumentError('Backup ${backup.fileName} has no file to share.');
    }
    await SharePlus.instance.share(ShareParams(
        files: [XFile(filePath)],
        text: 'Here is my exercise data backup file.'));
  }

  @override
  Future<List<int>> readBytes(String path) => File(path).readAsBytes();

  Future<Directory> _getDownloadsDirectory() async {
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

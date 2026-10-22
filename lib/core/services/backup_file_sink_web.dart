import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'backup_file_sink.dart';

BackupFileSink createBackupFileSink() => WebBackupFileSink();

/// Hands backups to the browser as a file download.
///
/// Sharing is not offered: Chrome's Web Share API refuses `.zip` files.
class WebBackupFileSink implements BackupFileSink {
  // Firefox and Safari read the blob after the click's task ends, so revoking
  // the URL right away would cancel the download.
  static const _revokeDelay = Duration(minutes: 1);

  @override
  Future<SavedBackup> save(String fileName, List<int> bytes) async {
    final blob = web.Blob(
      [Uint8List.fromList(bytes).toJS].toJS,
      web.BlobPropertyBag(type: 'application/zip'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName
      ..style.display = 'none';
    // Safari only downloads from an anchor that is in the document.
    web.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    Timer(_revokeDelay, () => web.URL.revokeObjectURL(url));
    return SavedBackup(fileName: fileName, location: 'your downloads');
  }

  @override
  bool get canShare => false;

  @override
  Future<void> share(SavedBackup backup) =>
      throw UnsupportedError('Sharing backups is not supported on web.');

  @override
  Future<List<int>> readBytes(String path) =>
      throw UnsupportedError('Reading files by path is not supported on web.');
}

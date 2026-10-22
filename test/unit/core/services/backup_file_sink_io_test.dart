import 'dart:io';

import 'package:exercise_management/core/services/backup_file_sink.dart';
import 'package:exercise_management/core/services/backup_file_sink_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory tempDir;
  late IoBackupFileSink sink;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_file_sink_io_');
    sink = IoBackupFileSink();
  });

  tearDown(() => tempDir.delete(recursive: true));

  test('readBytes returns the file content', () async {
    final file = File(path.join(tempDir.path, 'backup.zip'));
    await file.writeAsBytes([1, 2, 3]);

    expect(await sink.readBytes(file.path), [1, 2, 3]);
  });

  test('readBytes throws for a missing file', () {
    expect(sink.readBytes(path.join(tempDir.path, 'missing.zip')),
        throwsA(isA<FileSystemException>()));
  });

  test('share rejects a backup without a file path', () {
    expect(
        sink.share(const SavedBackup(fileName: 'a.zip', location: 'nowhere')),
        throwsArgumentError);
  });

  test('can share', () {
    expect(sink.canShare, isTrue);
  });
}

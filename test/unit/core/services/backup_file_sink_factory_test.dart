import 'package:exercise_management/core/services/backup_file_sink.dart';
import 'package:exercise_management/core/services/backup_file_sink_factory.dart';
import 'package:exercise_management/core/services/backup_file_sink_io.dart'
    show IoBackupFileSink;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('createBackupFileSink selects the IO implementation on this (VM) test '
      'platform', () {
    final sink = createBackupFileSink();

    expect(sink, isA<BackupFileSink>());
    expect(sink, isA<IoBackupFileSink>());
  });
}

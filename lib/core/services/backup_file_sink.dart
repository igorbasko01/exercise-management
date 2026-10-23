/// A backup handed to the user by [BackupFileSink.save].
class SavedBackup {
  const SavedBackup({
    required this.fileName,
    required this.location,
    this.path,
  });

  final String fileName;

  /// Where the user can find the backup, in words fit for the UI.
  final String location;

  /// Filesystem path of the saved file, where the platform has one.
  final String? path;

  @override
  bool operator ==(Object other) =>
      other is SavedBackup &&
      other.fileName == fileName &&
      other.location == location &&
      other.path == path;

  @override
  int get hashCode => Object.hash(fileName, location, path);
}

/// Where backup files go to and come from on the current platform.
abstract class BackupFileSink {
  /// Hands [bytes] to the user as [fileName].
  Future<SavedBackup> save(String fileName, List<int> bytes);

  /// Whether [share] is supported for backups from [save].
  bool get canShare;

  /// Opens the platform share sheet for [backup].
  Future<void> share(SavedBackup backup);

  /// Reads back a file the file picker identified by [path].
  Future<List<int>> readBytes(String path);
}

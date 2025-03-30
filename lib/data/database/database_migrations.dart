import 'package:sqflite/sqflite.dart';

abstract class DatabaseMigrations {
  /// The latest version of the database.
  int get latestVersion;

  /// Returns a map of upgrade actions to be performed when upgrading the database.
  /// The key is the version to upgrade from, and the value is a function that performs the upgrade.
  Map<int, Future<void> Function(Database db)> get upgradeSteps;
}

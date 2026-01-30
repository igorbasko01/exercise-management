import 'package:exercise_management/data/database/database_migrations.dart';
import 'package:sqflite/sqflite.dart';

/// A factory class for creating databases.
class AppDatabaseFactory {
  /// Creates a new database at the given path.
  /// createStatements is a list of SQL statements to execute when creating the database.
  /// migration is an instance of DatabaseMigrations that defines the upgrade steps for the database.
  static Future<Database> createDatabase(String path,
      List<String> createStatements, DatabaseMigrations migration) async {
    return openDatabase(path, version: migration.latestVersion,
        onCreate: (db, version) async {
      for (var statement in createStatements) {
        await db.execute(statement);
      }
    }, onUpgrade: (db, oldVersion, newVersion) async {
      for (var i = oldVersion + 1; i <= newVersion; i++) {
        final step = migration.upgradeSteps[i];
        if (step != null) {
          await step(db);
        }
      }
    });
  }
}

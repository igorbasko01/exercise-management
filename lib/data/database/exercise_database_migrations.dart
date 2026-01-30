import 'package:exercise_management/data/database/database_migrations.dart';
import 'package:sqflite/sqflite.dart';

class ExerciseDatabaseMigrations extends DatabaseMigrations {
  @override
  int get latestVersion => 2;

  @override
  Map<int, Future<void> Function(Database db)> get upgradeSteps => {
        2: (db) async {
          await db.execute(
              'ALTER TABLE exercise_sets ADD COLUMN completed_at TEXT');
        },
      };
}

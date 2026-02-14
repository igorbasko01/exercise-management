import 'package:exercise_management/data/database/database_migrations.dart';
import 'package:sqflite/sqflite.dart';

class ExerciseDatabaseMigrations extends DatabaseMigrations {
  @override
  int get latestVersion => 3;

  @override
  Map<int, Future<void> Function(Database db)> get upgradeSteps => {
        2: (db) async {
          await db.execute(
              'ALTER TABLE exercise_sets ADD COLUMN completed_at TEXT');
        },
        3: (db) async {
          await db.execute('''
            CREATE TABLE exercise_programs (
              id INTEGER PRIMARY KEY,
              name TEXT NOT NULL,
              description TEXT,
              is_active INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE exercise_program_sessions (
              id INTEGER PRIMARY KEY,
              program_id INTEGER NOT NULL REFERENCES exercise_programs(id) ON DELETE CASCADE,
              name TEXT NOT NULL,
              description TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE session_exercises (
              session_id INTEGER NOT NULL REFERENCES exercise_program_sessions(id) ON DELETE CASCADE,
              exercise_template_id INTEGER NOT NULL REFERENCES exercise_templates(id),
              ordering INTEGER NOT NULL,
              PRIMARY KEY (session_id, ordering)
            )
          ''');
        },
      };
}

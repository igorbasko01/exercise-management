import 'package:exercise_management/data/database/database_migrations.dart';
import 'package:sqflite/sqflite.dart';

class ExerciseDatabaseMigrations extends DatabaseMigrations {
  @override
  int get latestVersion => 5;

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
        4: (db) async {
          await db.execute(
              'ALTER TABLE exercise_programs ADD COLUMN progression_type INTEGER NOT NULL DEFAULT 0');
        },
        5: (db) async {
          // Migration to UUIDs and syncing columns

          await db.execute('''
          CREATE TABLE new_exercise_templates (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            muscle_group INTEGER NOT NULL,
            repetitions_range INTEGER NOT NULL,
            description TEXT,
            user_id TEXT,
            sync_status TEXT DEFAULT 'pending_insert',
            last_updated_at TEXT,
            deleted_at TEXT
          )
          ''');

          await db.execute('''
          CREATE TABLE new_exercise_sets (
            id TEXT PRIMARY KEY,
            exercise_template_id TEXT NOT NULL REFERENCES new_exercise_templates(id),
            date_time TEXT NOT NULL,
            equipment_weight REAL NOT NULL,
            plates_weight REAL NOT NULL,
            repetitions INTEGER NOT NULL,
            completed_at TEXT,
            user_id TEXT,
            sync_status TEXT DEFAULT 'pending_insert',
            last_updated_at TEXT,
            deleted_at TEXT
          )
          ''');

          await db.execute('''
          CREATE TABLE new_exercise_programs (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            is_active INTEGER NOT NULL DEFAULT 0,
            progression_type INTEGER NOT NULL DEFAULT 0,
            user_id TEXT,
            sync_status TEXT DEFAULT 'pending_insert',
            last_updated_at TEXT,
            deleted_at TEXT
          )
          ''');

          await db.execute('''
          CREATE TABLE new_exercise_program_sessions (
            id TEXT PRIMARY KEY,
            program_id TEXT NOT NULL REFERENCES new_exercise_programs(id) ON DELETE CASCADE,
            name TEXT NOT NULL,
            description TEXT,
            user_id TEXT,
            sync_status TEXT DEFAULT 'pending_insert',
            last_updated_at TEXT,
            deleted_at TEXT
          )
          ''');

          await db.execute('''
          CREATE TABLE new_session_exercises (
            session_id TEXT NOT NULL REFERENCES new_exercise_program_sessions(id) ON DELETE CASCADE,
            exercise_template_id TEXT NOT NULL REFERENCES new_exercise_templates(id),
            ordering INTEGER NOT NULL,
            user_id TEXT,
            sync_status TEXT DEFAULT 'pending_insert',
            last_updated_at TEXT,
            deleted_at TEXT,
            PRIMARY KEY (session_id, ordering)
          )
          ''');

          await db.execute('ALTER TABLE exercise_templates ADD COLUMN new_id TEXT');
          await db.execute('UPDATE exercise_templates SET new_id = lower(hex(randomblob(16)))');

          await db.execute('ALTER TABLE exercise_sets ADD COLUMN new_id TEXT');
          await db.execute('UPDATE exercise_sets SET new_id = lower(hex(randomblob(16)))');

          await db.execute('ALTER TABLE exercise_programs ADD COLUMN new_id TEXT');
          await db.execute('UPDATE exercise_programs SET new_id = lower(hex(randomblob(16)))');

          await db.execute('ALTER TABLE exercise_program_sessions ADD COLUMN new_id TEXT');
          await db.execute('UPDATE exercise_program_sessions SET new_id = lower(hex(randomblob(16)))');

          await db.execute('''
          INSERT INTO new_exercise_templates (id, name, muscle_group, repetitions_range, description)
          SELECT new_id, name, muscle_group, repetitions_range, description FROM exercise_templates
          ''');

          await db.execute('''
          INSERT INTO new_exercise_sets (id, exercise_template_id, date_time, equipment_weight, plates_weight, repetitions, completed_at)
          SELECT s.new_id, t.new_id, s.date_time, s.equipment_weight, s.plates_weight, s.repetitions, s.completed_at
          FROM exercise_sets s
          JOIN exercise_templates t ON s.exercise_template_id = t.id
          ''');

          await db.execute('''
          INSERT INTO new_exercise_programs (id, name, description, is_active, progression_type)
          SELECT new_id, name, description, is_active, progression_type FROM exercise_programs
          ''');

          await db.execute('''
          INSERT INTO new_exercise_program_sessions (id, program_id, name, description)
          SELECT s.new_id, p.new_id, s.name, s.description
          FROM exercise_program_sessions s
          JOIN exercise_programs p ON s.program_id = p.id
          ''');

          await db.execute('''
          INSERT INTO new_session_exercises (session_id, exercise_template_id, ordering)
          SELECT s.new_id, t.new_id, se.ordering
          FROM session_exercises se
          JOIN exercise_program_sessions s ON se.session_id = s.id
          JOIN exercise_templates t ON se.exercise_template_id = t.id
          ''');

          await db.execute('DROP TABLE session_exercises');
          await db.execute('DROP TABLE exercise_program_sessions');
          await db.execute('DROP TABLE exercise_programs');
          await db.execute('DROP TABLE exercise_sets');
          await db.execute('DROP TABLE exercise_templates');

          await db.execute('ALTER TABLE new_exercise_templates RENAME TO exercise_templates');
          await db.execute('ALTER TABLE new_exercise_sets RENAME TO exercise_sets');
          await db.execute('ALTER TABLE new_exercise_programs RENAME TO exercise_programs');
          await db.execute('ALTER TABLE new_exercise_program_sessions RENAME TO exercise_program_sessions');
          await db.execute('ALTER TABLE new_session_exercises RENAME TO session_exercises');
        }
      };
}

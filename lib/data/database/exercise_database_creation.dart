final List<String> createStatements = [
  '''
CREATE TABLE exercise_templates (
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
''',
  '''
CREATE TABLE exercise_sets (
  id TEXT PRIMARY KEY,
  exercise_template_id TEXT NOT NULL REFERENCES exercise_templates(id),
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
''',
  '''
CREATE TABLE exercise_programs (
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
''',
  '''
CREATE TABLE exercise_program_sessions (
  id TEXT PRIMARY KEY,
  program_id TEXT NOT NULL REFERENCES exercise_programs(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  user_id TEXT,
  sync_status TEXT DEFAULT 'pending_insert',
  last_updated_at TEXT,
  deleted_at TEXT
)
''',
  '''
CREATE TABLE session_exercises (
  session_id TEXT NOT NULL REFERENCES exercise_program_sessions(id) ON DELETE CASCADE,
  exercise_template_id TEXT NOT NULL REFERENCES exercise_templates(id),
  ordering INTEGER NOT NULL,
  user_id TEXT,
  sync_status TEXT DEFAULT 'pending_insert',
  last_updated_at TEXT,
  deleted_at TEXT,
  PRIMARY KEY (session_id, ordering)
)
'''
];

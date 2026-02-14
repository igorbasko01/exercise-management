final List<String> createStatements = [
  '''
CREATE TABLE exercise_templates (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  muscle_group INTEGER NOT NULL,
  repetitions_range INTEGER NOT NULL,
  description TEXT
  )
''',
  '''
CREATE TABLE exercise_sets (
  id INTEGER PRIMARY KEY,
  exercise_template_id INTEGER NOT NULL REFERENCES exercise_templates(id),
  date_time TEXT NOT NULL,
  equipment_weight REAL NOT NULL,
  plates_weight REAL NOT NULL,
  repetitions INTEGER NOT NULL,
  completed_at TEXT
)
''',
  '''
CREATE TABLE exercise_programs (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  is_active INTEGER NOT NULL DEFAULT 0
)
''',
  '''
CREATE TABLE exercise_program_sessions (
  id INTEGER PRIMARY KEY,
  program_id INTEGER NOT NULL REFERENCES exercise_programs(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT
)
''',
  '''
CREATE TABLE session_exercises (
  session_id INTEGER NOT NULL REFERENCES exercise_program_sessions(id) ON DELETE CASCADE,
  exercise_template_id INTEGER NOT NULL REFERENCES exercise_templates(id),
  ordering INTEGER NOT NULL,
  PRIMARY KEY (session_id, ordering)
)
'''
];

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
  repetitions INTEGER NOT NULL
)
'''
];

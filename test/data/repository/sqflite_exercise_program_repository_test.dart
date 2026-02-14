import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/data/models/exercise_program.dart';
import 'package:exercise_management/data/models/exercise_program_session.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/sqflite_exercise_program_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;
  late SqfliteExerciseProgramRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    database = await openDatabase(inMemoryDatabasePath, version: 3,
        onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE exercise_templates (
          id INTEGER PRIMARY KEY,
          name TEXT NOT NULL,
          muscle_group INTEGER NOT NULL,
          repetitions_range INTEGER NOT NULL,
          description TEXT
        )
      ''');
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
    }, onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    });
    repository = SqfliteExerciseProgramRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('should insert and retrieve a program with sessions and exercises',
      () async {
    // 1. Create Exercise Templates
    final exercise1Id = await database.insert('exercise_templates', {
      'name': 'Bench Press',
      'muscle_group': MuscleGroup.quadriceps.index,
      'repetitions_range': RepetitionsRange.medium.index,
    });
    final exercise2Id = await database.insert('exercise_templates', {
      'name': 'Squat',
      'muscle_group': MuscleGroup.quadriceps.index,
      'repetitions_range': RepetitionsRange.medium.index,
    });

    final exercise1 = ExerciseTemplate(
        id: exercise1Id.toString(),
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium);
    final exercise2 = ExerciseTemplate(
        id: exercise2Id.toString(),
        name: 'Squat',
        muscleGroup: MuscleGroup.quadriceps,
        repetitionsRangeTarget: RepetitionsRange.medium);

    // 2. Create Program Data
    final session1 = ExerciseProgramSession(
      name: 'Session A',
      exercises: [exercise1, exercise2],
    );
    final program = ExerciseProgram(
      name: 'Strength Program',
      sessions: [session1],
    );

    // 3. Add to Repository
    final addResult = await repository.addProgram(program);
    expect(addResult, isA<Ok<ExerciseProgram>>());
    final addedProgram = (addResult as Ok<ExerciseProgram>).value;
    expect(addedProgram.id, isNotNull);
    expect(addedProgram.sessions.length, 1);
    expect(addedProgram.sessions.first.exercises.length, 2);

    // 4. Retrieve from Repository
    final getResult = await repository.getProgram(addedProgram.id!);
    expect(getResult, isA<Ok<ExerciseProgram>>());
    final retrievedProgram = (getResult as Ok<ExerciseProgram>).value;
    expect(retrievedProgram.name, 'Strength Program');
    expect(retrievedProgram.sessions.first.name, 'Session A');
    expect(retrievedProgram.sessions.first.exercises[0].id, exercise1.id);
    expect(retrievedProgram.sessions.first.exercises[1].id, exercise2.id);
  });

  test('should update a program and its sessions', () async {
    // Setup initial data
    final exercise1Id = await database.insert('exercise_templates', {
      'name': 'Bench Press',
      'muscle_group': MuscleGroup.quadriceps.index,
      'repetitions_range': RepetitionsRange.medium.index,
    });
    final exercise1 = ExerciseTemplate(
        id: exercise1Id.toString(),
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium);

    final programInfo = ExerciseProgram(name: 'Initial Name', sessions: []);
    final addedProgramResult = await repository.addProgram(programInfo);
    expect(addedProgramResult, isA<Ok<ExerciseProgram>>());
    final addedProgram = (addedProgramResult as Ok<ExerciseProgram>).value;

    // Update
    final newSession =
        ExerciseProgramSession(name: 'Updated Session', exercises: [exercise1]);
    final updatedInfo = addedProgram.copyWith(
      name: 'Updated Name',
      sessions: [newSession],
    );

    final updateResult = await repository.updateProgram(updatedInfo);
    expect(updateResult, isA<Ok<ExerciseProgram>>());

    // Verify
    final getResult = await repository.getProgram(addedProgram.id!);
    expect(getResult, isA<Ok<ExerciseProgram>>());
    final retrieved = (getResult as Ok<ExerciseProgram>).value;
    expect(retrieved.name, 'Updated Name');
    expect(retrieved.sessions.length, 1);
    expect(retrieved.sessions.first.name, 'Updated Session');
    expect(retrieved.sessions.first.exercises.length, 1);
  });

  test('should delete a program', () async {
    final programInfo = ExerciseProgram(name: 'To Delete', sessions: []);
    final addedProgramResult = await repository.addProgram(programInfo);
    final addedProgram = (addedProgramResult as Ok<ExerciseProgram>).value;

    final deleteResult = await repository.deleteProgram(addedProgram.id!);
    expect(deleteResult, isA<Ok<ExerciseProgram>>());

    final getResult = await repository.getProgram(addedProgram.id!);
    expect(getResult, isA<Error<ExerciseProgram>>());
    // Verify cascade (check DB directly)
    final count = Sqflite.firstIntValue(await database.rawQuery(
        'SELECT count(*) FROM exercise_program_sessions WHERE program_id = ?',
        [addedProgram.id]));
    expect(count, 0);
  });

  test('should deactivate other programs when adding a new active program',
      () async {
    // Add first active program
    final program1 =
        ExerciseProgram(name: 'Program 1', sessions: [], isActive: true);
    final result1 = await repository.addProgram(program1);
    final addedProgram1 = (result1 as Ok<ExerciseProgram>).value;

    expect(addedProgram1.isActive, true);

    // Add second active program
    final program2 =
        ExerciseProgram(name: 'Program 2', sessions: [], isActive: true);
    final result2 = await repository.addProgram(program2);
    final addedProgram2 = (result2 as Ok<ExerciseProgram>).value;

    expect(addedProgram2.isActive, true);

    // Verify first program is now inactive
    final retrievedResult1 = await repository.getProgram(addedProgram1.id!);
    final retrievedProgram1 = (retrievedResult1 as Ok<ExerciseProgram>).value;
    expect(retrievedProgram1.isActive, false);
  });

  test('should deactivate other programs when updating a program to be active',
      () async {
    // Add first active program
    final program1 =
        ExerciseProgram(name: 'Program 1', sessions: [], isActive: true);
    final result1 = await repository.addProgram(program1);
    final addedProgram1 = (result1 as Ok<ExerciseProgram>).value;

    // Add second inactive program
    final program2 =
        ExerciseProgram(name: 'Program 2', sessions: [], isActive: false);
    final result2 = await repository.addProgram(program2);
    final addedProgram2 = (result2 as Ok<ExerciseProgram>).value;

    expect(addedProgram1.isActive, true);
    expect(addedProgram2.isActive, false);

    // Update second program to be active
    final updatedProgram2 = addedProgram2.copyWith(isActive: true);
    await repository.updateProgram(updatedProgram2);

    // Verify first program is now inactive
    final retrievedResult1 = await repository.getProgram(addedProgram1.id!);
    final retrievedProgram1 = (retrievedResult1 as Ok<ExerciseProgram>).value;

    final retrievedResult2 = await repository.getProgram(addedProgram2.id!);
    final retrievedProgram2 = (retrievedResult2 as Ok<ExerciseProgram>).value;

    expect(retrievedProgram1.isActive, false);
    expect(retrievedProgram2.isActive, true);
  });
}

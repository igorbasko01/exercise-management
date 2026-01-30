import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/database/database_factory.dart';
import 'package:exercise_management/data/database/exercise_database_creation.dart';
import 'package:exercise_management/data/database/exercise_database_migrations.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/repository/exceptions.dart';
import 'package:exercise_management/data/repository/sqflite_exercise_sets_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late SqfliteExerciseSetsRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await AppDatabaseFactory.createDatabase(
        inMemoryDatabasePath, createStatements, ExerciseDatabaseMigrations());
    repository = SqfliteExerciseSetsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('addExercise and getExercises should work correctly', () async {
    final exerciseSet = ExerciseSet(
        exerciseTemplateId: '1',
        dateTime: DateTime.now(),
        equipmentWeight: 10,
        platesWeight: 20,
        repetitions: 7);

    final addResult = await repository.addExercise(exerciseSet);
    final getResult = await repository.getExercises();

    expect(addResult, isA<Ok>());
    expect(getResult, isA<Ok>());
    expect((getResult as Ok<List<ExerciseSet>>).value.length, 1);
    expect((getResult).value.first, isA<ExerciseSet>());
    expect((getResult).value.first.id, isNotNull);
    expect((getResult).value.first.exerciseTemplateId,
        exerciseSet.exerciseTemplateId);
    expect((getResult).value.first.dateTime, exerciseSet.dateTime);
    expect(
        (getResult).value.first.equipmentWeight, exerciseSet.equipmentWeight);
    expect((getResult).value.first.platesWeight, exerciseSet.platesWeight);
    expect((getResult).value.first.repetitions, exerciseSet.repetitions);
  });

  test('addExercise with existing id should fail', () async {
    final exerciseSet = ExerciseSet(
        id: '1',
        exerciseTemplateId: '1',
        dateTime: DateTime.now(),
        equipmentWeight: 10,
        platesWeight: 20,
        repetitions: 7);

    await repository.addExercise(exerciseSet);

    final duplicateExerciseSet = exerciseSet.copyWith();
    final addResult = await repository.addExercise(duplicateExerciseSet);
    expect(addResult, isA<Error>());
    expect((addResult as Error<ExerciseSet>).error,
        isA<ExerciseAlreadyExistsException>());
  });

  test('getExercises should return empty list when no exercises exist',
      () async {
    final getResult = await repository.getExercises();
    expect(getResult, isA<Ok>());
    expect((getResult as Ok<List<ExerciseSet>>).value, isEmpty);
  });

  test('getExercise should return exercise by id', () async {
    final exerciseSet1 = ExerciseSet(
        exerciseTemplateId: '1',
        dateTime: DateTime.now(),
        equipmentWeight: 10,
        platesWeight: 20,
        repetitions: 7);

    final exerciseSet2 = ExerciseSet(
        exerciseTemplateId: '2',
        dateTime: DateTime.now(),
        equipmentWeight: 15,
        platesWeight: 25,
        repetitions: 10);

    final exerciseSet1Id =
        (await repository.addExercise(exerciseSet1) as Ok<ExerciseSet>)
            .value
            .id;
    final exerciseSet2Id =
        (await repository.addExercise(exerciseSet2) as Ok<ExerciseSet>)
            .value
            .id;

    final getResult1 = await repository.getExercise(exerciseSet1Id.toString());
    expect(getResult1, isA<Ok>());
    expect((getResult1 as Ok<ExerciseSet>).value.id, exerciseSet1Id);
    expect(
        (getResult1).value.exerciseTemplateId, exerciseSet1.exerciseTemplateId);
    expect((getResult1).value.dateTime, exerciseSet1.dateTime);
    expect((getResult1).value.equipmentWeight, exerciseSet1.equipmentWeight);
    expect((getResult1).value.platesWeight, exerciseSet1.platesWeight);
    expect((getResult1).value.repetitions, exerciseSet1.repetitions);

    final getResult2 = await repository.getExercise(exerciseSet2Id.toString());
    expect(getResult2, isA<Ok>());
    expect((getResult2 as Ok<ExerciseSet>).value.id, exerciseSet2Id);
    expect(
        (getResult2).value.exerciseTemplateId, exerciseSet2.exerciseTemplateId);
    expect((getResult2).value.dateTime, exerciseSet2.dateTime);
    expect((getResult2).value.equipmentWeight, exerciseSet2.equipmentWeight);
    expect((getResult2).value.platesWeight, exerciseSet2.platesWeight);
    expect((getResult2).value.repetitions, exerciseSet2.repetitions);
  });

  test('getExercise with non-existing id should fail', () async {
    final getResult = await repository.getExercise('non_existing_id');
    expect(getResult, isA<Error>());
    expect((getResult as Error<ExerciseSet>).error,
        isA<ExerciseNotFoundException>());
  });

  test('deleteExercise should remove exercise by id', () async {
    final exerciseSet = ExerciseSet(
        exerciseTemplateId: '1',
        dateTime: DateTime.now(),
        equipmentWeight: 10,
        platesWeight: 20,
        repetitions: 7);

    final addResult = await repository.addExercise(exerciseSet);
    expect(addResult, isA<Ok>());

    final addedExerciseSet = (addResult as Ok<ExerciseSet>).value;

    final deleteResult = await repository.deleteExercise(addedExerciseSet.id!);
    expect(deleteResult, isA<Ok>());

    final getResult = await repository.getExercise(addedExerciseSet.id!);
    expect(getResult, isA<Error>());
    expect((getResult as Error<ExerciseSet>).error,
        isA<ExerciseNotFoundException>());
  });

  test('deleteExercise with non-existing id should fail', () async {
    final deleteResult = await repository.deleteExercise('non_existing_id');
    expect(deleteResult, isA<Error>());
    expect((deleteResult as Error<ExerciseSet>).error,
        isA<ExerciseNotFoundException>());
  });

  test('updateExercise should update existing exercise', () async {
    final exerciseSet = ExerciseSet(
        exerciseTemplateId: '1',
        dateTime: DateTime.now(),
        equipmentWeight: 10,
        platesWeight: 20,
        repetitions: 7);

    final addResult = await repository.addExercise(exerciseSet);
    expect(addResult, isA<Ok>());

    final updatedExerciseSet =
        (addResult as Ok<ExerciseSet>).value.copyWith(equipmentWeight: 15);
    final updateResult = await repository.updateExercise(updatedExerciseSet);
    expect(updateResult, isA<Ok>());
    expect((updateResult as Ok<ExerciseSet>).value.equipmentWeight, 15);
  });

  test('updateExercise with non-existing id should fail', () async {
    final exerciseSet = ExerciseSet(
        id: 'non_existing_id',
        exerciseTemplateId: '1',
        dateTime: DateTime.now(),
        equipmentWeight: 10,
        platesWeight: 20,
        repetitions: 7);

    final updateResult = await repository.updateExercise(exerciseSet);
    expect(updateResult, isA<Error>());
    expect((updateResult as Error<ExerciseSet>).error,
        isA<ExerciseNotFoundException>());
  });

  test('addExercises should add multiple exercises', () async {
    final exerciseSet1 = ExerciseSet(
        exerciseTemplateId: '1',
        dateTime: DateTime.now(),
        equipmentWeight: 10,
        platesWeight: 20,
        repetitions: 7);

    final exerciseSet2 = ExerciseSet(
        exerciseTemplateId: '2',
        dateTime: DateTime.now(),
        equipmentWeight: 15,
        platesWeight: 25,
        repetitions: 10);

    final addResult =
        await repository.addExercises([exerciseSet1, exerciseSet2]);
    expect(addResult, isA<Ok>());

    final getResult = await repository.getExercises();
    expect(getResult, isA<Ok>());
    expect((getResult as Ok<List<ExerciseSet>>).value.length, 2);
  });

  test('addExercises with existing ids should fail', () async {
    final exerciseSet1 = ExerciseSet(
        id: '1',
        exerciseTemplateId: '1',
        dateTime: DateTime.now(),
        equipmentWeight: 10,
        platesWeight: 20,
        repetitions: 7);

    final exerciseSet2 = ExerciseSet(
        id: '1',
        exerciseTemplateId: '2',
        dateTime: DateTime.now(),
        equipmentWeight: 15,
        platesWeight: 25,
        repetitions: 10);

    final addResult =
        await repository.addExercises([exerciseSet1, exerciseSet2]);
    expect(addResult, isA<Error>());
    expect((addResult as Error<void>).error,
        isA<ExerciseAlreadyExistsException>());
  });

  test('addExercises with some existing ids should fail without adding any',
      () async {
    final exerciseSet1 = ExerciseSet(
        id: '1',
        exerciseTemplateId: '1',
        dateTime: DateTime.now(),
        equipmentWeight: 10,
        platesWeight: 20,
        repetitions: 7);

    final exerciseSet2 = ExerciseSet(
        id: '2',
        exerciseTemplateId: '2',
        dateTime: DateTime.now(),
        equipmentWeight: 15,
        platesWeight: 25,
        repetitions: 10);

    await repository.addExercise(exerciseSet2);

    final addResult =
        await repository.addExercises([exerciseSet1, exerciseSet2]);
    expect(addResult, isA<Error>());
    expect((addResult as Error<void>).error,
        isA<ExerciseAlreadyExistsException>());

    final getResult = await repository.getExercises();
    expect(getResult, isA<Ok>());
    expect((getResult as Ok<List<ExerciseSet>>).value.length, 1);
  });

  test('addExercises with empty list should succeed without adding any',
      () async {
    final addResult = await repository.addExercises([]);
    expect(addResult, isA<Ok>());

    final getResult = await repository.getExercises();
    expect(getResult, isA<Ok>());
    expect((getResult as Ok<List<ExerciseSet>>).value, isEmpty);
  });

  group('completedAt field', () {
    test('addExercise and getExercises should store and retrieve completedAt',
        () async {
      final completedTime = DateTime.now().subtract(const Duration(minutes: 5));
      final exerciseSet = ExerciseSet(
        exerciseTemplateId: '1',
        dateTime: DateTime.now(),
        equipmentWeight: 10,
        platesWeight: 20,
        repetitions: 7,
        completedAt: completedTime,
      );

      final addResult = await repository.addExercise(exerciseSet);
      expect(addResult, isA<Ok>());

      final getResult = await repository.getExercises();
      expect(getResult, isA<Ok>());
      expect((getResult as Ok<List<ExerciseSet>>).value.first.completedAt,
          completedTime);
    });

    test('exercise set without completedAt should have null', () async {
      final exerciseSet = ExerciseSet(
        exerciseTemplateId: '1',
        dateTime: DateTime.now(),
        equipmentWeight: 10,
        platesWeight: 20,
        repetitions: 7,
      );

      final addResult = await repository.addExercise(exerciseSet);
      expect(addResult, isA<Ok>());

      final getResult = await repository.getExercises();
      expect(getResult, isA<Ok>());
      expect(
          (getResult as Ok<List<ExerciseSet>>).value.first.completedAt, isNull);
    });

    test('updateExercise should update completedAt', () async {
      final exerciseSet = ExerciseSet(
        exerciseTemplateId: '1',
        dateTime: DateTime.now(),
        equipmentWeight: 10,
        platesWeight: 20,
        repetitions: 7,
      );

      final addResult = await repository.addExercise(exerciseSet);
      expect(addResult, isA<Ok>());

      final addedExerciseSet = (addResult as Ok<ExerciseSet>).value;
      final completedTime = DateTime.now();
      final updatedExerciseSet =
          addedExerciseSet.copyWith(completedAt: completedTime);

      final updateResult = await repository.updateExercise(updatedExerciseSet);
      expect(updateResult, isA<Ok>());
      expect(
          (updateResult as Ok<ExerciseSet>).value.completedAt, completedTime);

      // Verify persisted
      final getResult = await repository.getExercise(addedExerciseSet.id!);
      expect((getResult as Ok<ExerciseSet>).value.completedAt, completedTime);
    });
  });

  group('backward compatibility', () {
    test('should handle reading from database without completed_at column',
        () async {
      // Close the current database
      await db.close();

      // Create a database with the old schema (without completed_at column)
      final oldDb = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
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
              CREATE TABLE exercise_sets (
                id INTEGER PRIMARY KEY,
                exercise_template_id INTEGER NOT NULL REFERENCES exercise_templates(id),
                date_time TEXT NOT NULL,
                equipment_weight REAL NOT NULL,
                plates_weight REAL NOT NULL,
                repetitions INTEGER NOT NULL
              )
            ''');
          },
        ),
      );

      // Insert data using the old schema (no completed_at)
      await oldDb.insert('exercise_sets', {
        'exercise_template_id': '1',
        'date_time': DateTime.now().toIso8601String(),
        'equipment_weight': 10.0,
        'plates_weight': 20.0,
        'repetitions': 7,
      });

      // Create repository with old database
      final oldSchemaRepository = SqfliteExerciseSetsRepository(oldDb);

      // Reading should work and completedAt should be null
      final getResult = await oldSchemaRepository.getExercises();
      expect(getResult, isA<Ok>());
      final exerciseSets = (getResult as Ok<List<ExerciseSet>>).value;
      expect(exerciseSets.length, 1);
      expect(exerciseSets.first.completedAt, isNull);

      await oldDb.close();
    });
  });
}

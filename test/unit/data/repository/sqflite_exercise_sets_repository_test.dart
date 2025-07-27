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
    db = await AppDatabaseFactory.createDatabase(inMemoryDatabasePath, createStatements, ExerciseDatabaseMigrations());
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
      repetitions: 7
    );

    final addResult = await repository.addExercise(exerciseSet);
    final getResult = await repository.getExercises();

    expect(addResult, isA<Ok>());
    expect(getResult, isA<Ok>());
    expect((getResult as Ok<List<ExerciseSet>>).value.length, 1);
    expect((getResult).value.first, isA<ExerciseSet>());
    expect((getResult).value.first.id, isNotNull);
    expect((getResult).value.first.exerciseTemplateId, exerciseSet.exerciseTemplateId);
    expect((getResult).value.first.dateTime, exerciseSet.dateTime);
    expect((getResult).value.first.equipmentWeight, exerciseSet.equipmentWeight);
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
      repetitions: 7
    );

    await repository.addExercise(exerciseSet);

    final duplicateExerciseSet = exerciseSet.copyWith();
    final addResult = await repository.addExercise(duplicateExerciseSet);
    expect(addResult, isA<Error>());
    expect((addResult as Error<ExerciseSet>).error, isA<ExerciseAlreadyExistsException>());
  });

  test('getExercises should return empty list when no exercises exist', () async {
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
      repetitions: 7
    );

    final exerciseSet2 = ExerciseSet(
      exerciseTemplateId: '2',
      dateTime: DateTime.now(),
      equipmentWeight: 15,
      platesWeight: 25,
      repetitions: 10
    );

    final exerciseSet1Id = (await repository.addExercise(exerciseSet1) as Ok<ExerciseSet>).value.id;
    final exerciseSet2Id = (await repository.addExercise(exerciseSet2) as Ok<ExerciseSet>).value.id;

    final getResult1 = await repository.getExercise(exerciseSet1Id.toString());
    expect(getResult1, isA<Ok>());
    expect((getResult1 as Ok<ExerciseSet>).value.id, exerciseSet1Id);
    expect((getResult1).value.exerciseTemplateId, exerciseSet1.exerciseTemplateId);
    expect((getResult1).value.dateTime, exerciseSet1.dateTime);
    expect((getResult1).value.equipmentWeight, exerciseSet1.equipmentWeight);
    expect((getResult1).value.platesWeight, exerciseSet1.platesWeight);
    expect((getResult1).value.repetitions, exerciseSet1.repetitions);

    final getResult2 = await repository.getExercise(exerciseSet2Id.toString());
    expect(getResult2, isA<Ok>());
    expect((getResult2 as Ok<ExerciseSet>).value.id, exerciseSet2Id);
    expect((getResult2).value.exerciseTemplateId, exerciseSet2.exerciseTemplateId);
    expect((getResult2).value.dateTime, exerciseSet2.dateTime);
    expect((getResult2).value.equipmentWeight, exerciseSet2.equipmentWeight);
    expect((getResult2).value.platesWeight, exerciseSet2.platesWeight);
    expect((getResult2).value.repetitions, exerciseSet2.repetitions);
  });
}
import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/database/database_factory.dart';
import 'package:exercise_management/data/database/exercise_database_creation.dart';
import 'package:exercise_management/data/database/exercise_database_migrations.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exceptions.dart';
import 'package:exercise_management/data/repository/sqflite_exercise_template_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late SqfliteExerciseTemplateRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await AppDatabaseFactory.createDatabase(inMemoryDatabasePath, createStatements, ExerciseDatabaseMigrations());
    repository = SqfliteExerciseTemplateRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('addExercise and getExercises should work correctly', () async {
    final exercise = ExerciseTemplate(
        name: 'Push Up',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium);

    final addResult = await repository.addExercise(exercise);
    expect(addResult, isA<Ok>());

    final getResult = await repository.getExercises();
    expect(getResult, isA<Ok>());
    expect((getResult as Ok<List<ExerciseTemplate>>).value.length, 1);
  });

  test('addExercise with existing id should fail', () async {
    final exercise = ExerciseTemplate(
        id: '1',
        name: 'Push Up',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium);

    await repository.addExercise(exercise);

    final duplicateExercise = exercise.copyWith();
    final addResult = await repository.addExercise(duplicateExercise);
    expect(addResult, isA<Error>());
    expect((addResult as Error<ExerciseTemplate>).error, isA<ExerciseAlreadyExistsException>());
  });

  test('getExercises should return empty list when no exercises exist', () async {
    final getResult = await repository.getExercises();
    expect(getResult, isA<Ok>());
    expect((getResult as Ok<List<ExerciseTemplate>>).value, isEmpty);
  });

  test('getExercise should return exercise by id', () async {
    final exercise1 = ExerciseTemplate(
        name: 'Push Up',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium);

    final exercise2 = ExerciseTemplate(
        name: 'Pull Up',
        muscleGroup: MuscleGroup.lats,
        repetitionsRangeTarget: RepetitionsRange.high);

    final exercise1Id = (await repository.addExercise(exercise1) as Ok<ExerciseTemplate>).value.id;
    final exercise2Id = (await repository.addExercise(exercise2) as Ok<ExerciseTemplate>).value.id;

    final getResult1 = await repository.getExercise(exercise1Id!);
    final getResult2 = await repository.getExercise(exercise2Id!);
    expect(getResult1, isA<Ok>());
    expect((getResult1 as Ok<ExerciseTemplate>).value.name, 'Push Up');
    expect(getResult2, isA<Ok>());
    expect((getResult2 as Ok<ExerciseTemplate>).value.name, 'Pull Up');
  });

  test('getExercise with non-existing id should fail', () async {
    final getResult = await repository.getExercise('non_existing_id');
    expect(getResult, isA<Error>());
    expect((getResult as Error<ExerciseTemplate>).error, isA<ExerciseNotFoundException>());
  });

  test('updateExercise should update existing exercise', () async {
    final exercise = ExerciseTemplate(
        name: 'Push Up',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium);

    final addResult = await repository.addExercise(exercise);
    expect(addResult, isA<Ok>());

    final updatedExercise = (addResult as Ok<ExerciseTemplate>).value.copyWith(name: 'Updated Push Up');
    final updateResult = await repository.updateExercise(updatedExercise);
    expect(updateResult, isA<Ok>());
    expect((updateResult as Ok<ExerciseTemplate>).value.name, 'Updated Push Up');
  });

  test('updateExercise with non-existing id should fail', () async {
    final exercise = ExerciseTemplate(
        id: 'non_existing_id',
        name: 'Push Up',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium);

    final updateResult = await repository.updateExercise(exercise);
    expect(updateResult, isA<Error>());
    expect((updateResult as Error<ExerciseTemplate>).error, isA<ExerciseNotFoundException>());
  });

  test('deleteExercise should delete existing exercise', () async {
    final exercise = ExerciseTemplate(
        name: 'Push Up',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium);

    final addResult = await repository.addExercise(exercise);
    expect(addResult, isA<Ok>());

    final exerciseId = (addResult as Ok<ExerciseTemplate>).value.id;
    final deleteResult = await repository.deleteExercise(exerciseId!);
    expect(deleteResult, isA<Ok>());

    final getResult = await repository.getExercise(exerciseId);
    expect(getResult, isA<Error>());
    expect((getResult as Error<ExerciseTemplate>).error, isA<ExerciseNotFoundException>());
  });

  test('deleteExercise with non-existing id should fail', () async {
    final deleteResult = await repository.deleteExercise('non_existing_id');
    expect(deleteResult, isA<Error>());
    expect((deleteResult as Error<ExerciseTemplate>).error, isA<ExerciseNotFoundException>());
  });
}

import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/repository/exceptions.dart';
import 'package:exercise_management/data/repository/in_memory_exercise_set_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryExerciseSetRepository inMemoryExerciseSetRepository;

  setUp(() {
    inMemoryExerciseSetRepository = InMemoryExerciseSetRepository();
  });

  test('addExerciseSet should add an exercise set', () async {
    final now = DateTime.now();
    final exerciseSetModel = ExerciseSet(
      exerciseTemplateId: '1',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 45,
      repetitions: 10,
    );

    final result =
        await inMemoryExerciseSetRepository.addExercise(exerciseSetModel);

    final exerciseSet = (result as Ok<ExerciseSet>).value;

    expect(exerciseSet.exerciseTemplateId, '1');
    expect(exerciseSet.dateTime, now);
    expect(exerciseSet.equipmentWeight, 0);
    expect(exerciseSet.platesWeight, 45);
    expect(exerciseSet.repetitions, 10);
  });

  test('addExerciseSet should add a fetchable exercise set', () async {
    final now = DateTime.now();
    final exerciseSetModel = ExerciseSet(
      exerciseTemplateId: '1',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 45,
      repetitions: 10,
    );

    await inMemoryExerciseSetRepository.addExercise(exerciseSetModel);

    final result = await inMemoryExerciseSetRepository.getExercises();

    final exerciseSet = (result as Ok<List<ExerciseSet>>).value.first;

    expect(exerciseSet.exerciseTemplateId, '1');
    expect(exerciseSet.dateTime, now);
    expect(exerciseSet.equipmentWeight, 0);
    expect(exerciseSet.platesWeight, 45);
    expect(exerciseSet.repetitions, 10);
  });

  test('addExercise set with existing id should fail', () async {
    final now = DateTime.now();
    final exerciseSetModel = ExerciseSet(
      exerciseTemplateId: '1',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 45,
      repetitions: 10,
    );

    await inMemoryExerciseSetRepository.addExercise(exerciseSetModel);

    final result =
        await inMemoryExerciseSetRepository.addExercise(exerciseSetModel);

    final error = (result as Error).error;

    expect(result, isA<Error>());
    expect(error, isA<ExerciseAlreadyExistsException>());
  });

  test('deleteExerciseSet should delete an exercise set', () async {
    final now = DateTime.now();
    final exerciseSetModel = ExerciseSet(
      exerciseTemplateId: '1',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 45,
      repetitions: 10,
    );

    final result =
        await inMemoryExerciseSetRepository.addExercise(exerciseSetModel);

    final exerciseSet = (result as Ok<ExerciseSet>).value;

    final deleteResult =
        await inMemoryExerciseSetRepository.deleteExercise(exerciseSet.id!);

    final deletedExerciseSet = (deleteResult as Ok<ExerciseSet>).value;

    expect(deleteResult, isA<Ok>());
    expect(deletedExerciseSet.id, exerciseSet.id);
  });

  test('deleteExerciseSet with non-existing id should fail', () async {
    final result = await inMemoryExerciseSetRepository.deleteExercise('1');

    final error = (result as Error).error;

    expect(result, isA<Error>());
    expect(error, isA<ExerciseNotFoundException>());
  });

  test('deleteExerciseSet should delete a fetchable exercise set', () async {
    final now = DateTime.now();
    final exerciseSetModel = ExerciseSet(
      exerciseTemplateId: '1',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 45,
      repetitions: 10,
    );

    final result =
        await inMemoryExerciseSetRepository.addExercise(exerciseSetModel);

    final exerciseSet = (result as Ok<ExerciseSet>).value;

    await inMemoryExerciseSetRepository.deleteExercise(exerciseSet.id!);

    final fetchResult = await inMemoryExerciseSetRepository.getExercises();

    final exerciseSets = (fetchResult as Ok<List<ExerciseSet>>).value;

    expect(exerciseSets, isEmpty);
  });

  test('updateExerciseSet should update an exercise set', () async {
    final now = DateTime.now();
    final exerciseSetModel = ExerciseSet(
      exerciseTemplateId: '1',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 45,
      repetitions: 10,
    );

    final result =
        await inMemoryExerciseSetRepository.addExercise(exerciseSetModel);

    final exerciseSet = (result as Ok<ExerciseSet>).value;

    final updatedExerciseSet = exerciseSet.copyWith(
      equipmentWeight: 10,
      platesWeight: 35,
      repetitions: 5,
    );

    final updateResult =
        await inMemoryExerciseSetRepository.updateExercise(updatedExerciseSet);

    final updatedSet = (updateResult as Ok<ExerciseSet>).value;

    expect(updatedSet.equipmentWeight, 10);
    expect(updatedSet.platesWeight, 35);
    expect(updatedSet.repetitions, 5);
  });

  test('updateExerciseSet with non-existing id should fail', () async {
    final now = DateTime.now();
    final exerciseSetModel = ExerciseSet(
      exerciseTemplateId: '1',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 45,
      repetitions: 10,
    );

    final result =
        await inMemoryExerciseSetRepository.addExercise(exerciseSetModel);

    final exerciseSet = (result as Ok<ExerciseSet>).value;

    final updatedExerciseSet = exerciseSet.copyWith(
      id: '2',
      equipmentWeight: 10,
      platesWeight: 35,
      repetitions: 5,
    );

    final updateResult =
        await inMemoryExerciseSetRepository.updateExercise(updatedExerciseSet);

    final error = (updateResult as Error).error;

    expect(updateResult, isA<Error>());
    expect(error, isA<ExerciseNotFoundException>());
  });

  test('updateExerciseSet should update a fetchable exercise set', () async {
    final now = DateTime.now();
    final exerciseSetModel = ExerciseSet(
      exerciseTemplateId: '1',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 45,
      repetitions: 10,
    );

    final result =
        await inMemoryExerciseSetRepository.addExercise(exerciseSetModel);

    final exerciseSet = (result as Ok<ExerciseSet>).value;

    final updatedExerciseSet = exerciseSet.copyWith(
      equipmentWeight: 10,
      platesWeight: 35,
      repetitions: 5,
    );

    await inMemoryExerciseSetRepository.updateExercise(updatedExerciseSet);

    final fetchResult = await inMemoryExerciseSetRepository.getExercises();

    final exerciseSets = (fetchResult as Ok<List<ExerciseSet>>).value;

    final updatedSet = exerciseSets.first;

    expect(updatedSet.equipmentWeight, 10);
    expect(updatedSet.platesWeight, 35);
    expect(updatedSet.repetitions, 5);
  });

  test('getExercises should return all exercise sets', () async {
    final now = DateTime.now();
    final exerciseSetModel1 = ExerciseSet(
      exerciseTemplateId: '1',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 45,
      repetitions: 10,
    );

    final exerciseSetModel2 = ExerciseSet(
      exerciseTemplateId: '2',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 45,
      repetitions: 10,
    );

    await inMemoryExerciseSetRepository.addExercise(exerciseSetModel1);
    await inMemoryExerciseSetRepository.addExercise(exerciseSetModel2);

    final result = await inMemoryExerciseSetRepository.getExercises();

    final exerciseSets = (result as Ok<List<ExerciseSet>>).value;

    expect(exerciseSets.length, 2);
  });

  test('getExercises should return an empty list if no exercise sets',
      () async {
    final result = await inMemoryExerciseSetRepository.getExercises();

    final exerciseSets = (result as Ok<List<ExerciseSet>>).value;

    expect(exerciseSets, isEmpty);
  });

  test('getExercise should return an exercise set', () async {
    final now = DateTime.now();
    final exerciseSetModel = ExerciseSet(
      exerciseTemplateId: '1',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 45,
      repetitions: 10,
    );

    final result =
        await inMemoryExerciseSetRepository.addExercise(exerciseSetModel);

    final exerciseSet = (result as Ok<ExerciseSet>).value;

    final fetchResult =
        await inMemoryExerciseSetRepository.getExercise(exerciseSet.id!);

    final fetchedExerciseSet = (fetchResult as Ok<ExerciseSet>).value;

    expect(fetchedExerciseSet.id, exerciseSet.id);
  });

  test('getExercise with non-existing id should fail', () async {
    final result = await inMemoryExerciseSetRepository.getExercise('1');

    final error = (result as Error).error;

    expect(result, isA<Error>());
    expect(error, isA<ExerciseNotFoundException>());
  });
}

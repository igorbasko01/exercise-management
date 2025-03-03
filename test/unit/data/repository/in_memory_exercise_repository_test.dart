import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/in_memory_exercise_template_repository.dart';
import 'package:exercise_management/data/repository/exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryExerciseRepository inMemoryExerciseRepository;

  setUp(() {
    inMemoryExerciseRepository = InMemoryExerciseRepository();
  });

  test('addExercise should add an exercise to the repository', () async {
    final exercise = ExerciseTemplate(
      id: '1',
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.medium,
    );

    final result = await inMemoryExerciseRepository.addExercise(exercise);

    final exercises = await inMemoryExerciseRepository.getExercises();

    expect(result, isA<Ok<ExerciseTemplate>>());
    expect((exercises as Ok<List<ExerciseTemplate>>).value, [exercise]);
  });

  test('addExercise should generate an exercise id if null provided', () async {
    final exercise = ExerciseTemplate(
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.medium,
    );

    await inMemoryExerciseRepository.addExercise(exercise);

    final exercises = (await inMemoryExerciseRepository.getExercises()) as Ok<List<ExerciseTemplate>>;

    expect(exercises.value.first.id, isNotNull);
  });

  test('addExercise with an existing exercise should fail', () async {
    final exercise = ExerciseTemplate(
      id: '1',
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.medium,
    );

    final resultOriginal = await inMemoryExerciseRepository.addExercise(exercise) as Ok<ExerciseTemplate>;
    final resultDuplicate = await inMemoryExerciseRepository.addExercise(exercise) as Error<ExerciseTemplate>;

    expect(resultOriginal, isA<Ok<ExerciseTemplate>>());
    expect(resultDuplicate, isA<Error<ExerciseTemplate>>());
    expect(resultDuplicate.error, isA<ExerciseAlreadyExistsException>());
    expect(resultDuplicate.error.toString(), 'ExerciseAlreadyExistsException: Exercise 1 already exists');
  });

  test('getExercises should return all exercises from the repository', () async {
    final exercise1 = ExerciseTemplate(
      id: '1',
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.medium,
    );

    final exercise2 = ExerciseTemplate(
      id: '2',
      name: 'Squat',
      muscleGroup: MuscleGroup.quadriceps,
      repetitionsRangeTarget: RepetitionsRange.high,
    );

    await inMemoryExerciseRepository.addExercise(exercise1);
    await inMemoryExerciseRepository.addExercise(exercise2);

    final exercises = await inMemoryExerciseRepository.getExercises() as Ok<List<ExerciseTemplate>>;

    expect(exercises.value, [exercise1, exercise2]);
  });

  test('getExercises should return an empty list if no exercises are in the repository', () async {
    final exercises = await inMemoryExerciseRepository.getExercises() as Ok<List<ExerciseTemplate>>;

    expect(exercises.value, []);
  });

  test('getExercise should return the exercise with the given id', () async {
    final exercise1 = ExerciseTemplate(
      id: '1',
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.medium,
    );

    final exercise2 = ExerciseTemplate(
      id: '2',
      name: 'Squat',
      muscleGroup: MuscleGroup.quadriceps,
      repetitionsRangeTarget: RepetitionsRange.high,
    );

    await inMemoryExerciseRepository.addExercise(exercise1);
    await inMemoryExerciseRepository.addExercise(exercise2);

    final exercise = await inMemoryExerciseRepository.getExercise('2') as Ok<ExerciseTemplate>;

    expect(exercise.value, exercise2);
  });

  test('getExercise should throw an exception if the exercise does not exist', () async {
    final exercise1 = ExerciseTemplate(
      id: '1',
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.medium,
    );

    final exercise2 = ExerciseTemplate(
      id: '2',
      name: 'Squat',
      muscleGroup: MuscleGroup.quadriceps,
      repetitionsRangeTarget: RepetitionsRange.high,
    );

    await inMemoryExerciseRepository.addExercise(exercise1);
    await inMemoryExerciseRepository.addExercise(exercise2);

    final exercise = await inMemoryExerciseRepository.getExercise('3') as Error<ExerciseTemplate>;

    expect(exercise, isA<Error<ExerciseTemplate>>());
    expect(exercise.error, isA<ExerciseNotFoundException>());
    expect(exercise.error.toString(), 'ExerciseNotFoundException: Exercise 3 not found');
  });

  test('updateExercise should update the exercise with the given id', () async {
    final exercise1 = ExerciseTemplate(
      id: '1',
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.medium,
    );

    final exercise2 = ExerciseTemplate(
      id: '2',
      name: 'Squat',
      muscleGroup: MuscleGroup.quadriceps,
      repetitionsRangeTarget: RepetitionsRange.high,
    );

    await inMemoryExerciseRepository.addExercise(exercise1);
    await inMemoryExerciseRepository.addExercise(exercise2);

    final updatedExercise = exercise2.copyWith(name: 'Better Squat');

    final result = await inMemoryExerciseRepository.updateExercise(updatedExercise);

    final exercises = await inMemoryExerciseRepository.getExercises() as Ok<List<ExerciseTemplate>>;

    expect(result, isA<Ok<ExerciseTemplate>>());
    expect(exercises.value, [exercise1, updatedExercise]);
  });

  test('updateExercise should throw an exception if the exercise does not exist', () async {
    final exercise1 = ExerciseTemplate(
      id: '1',
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.medium,
    );

    final exercise2 = ExerciseTemplate(
      id: '2',
      name: 'Squat',
      muscleGroup: MuscleGroup.quadriceps,
      repetitionsRangeTarget: RepetitionsRange.high,
    );

    await inMemoryExerciseRepository.addExercise(exercise1);
    await inMemoryExerciseRepository.addExercise(exercise2);

    final updatedExercise = ExerciseTemplate(
      id: '3',
      name: 'Better Squat',
      muscleGroup: MuscleGroup.quadriceps,
      repetitionsRangeTarget: RepetitionsRange.high,
    );

    final result = await inMemoryExerciseRepository.updateExercise(updatedExercise) as Error<ExerciseTemplate>;

    expect(result, isA<Error<ExerciseTemplate>>());
    expect(result.error, isA<ExerciseNotFoundException>());
    expect(result.error.toString(), 'ExerciseNotFoundException: Exercise 3 not found');
  });

  test('updateExercise should throw an exception if a null id is provided', () async {
    final exercise = ExerciseTemplate(
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.medium,
    );

    final result = await inMemoryExerciseRepository.updateExercise(exercise) as Error<ExerciseTemplate>;

    expect(result, isA<Error<ExerciseTemplate>>());
    expect(result.error, isA<ExerciseNotFoundException>());
    expect(result.error.toString(), 'ExerciseNotFoundException: Exercise null not found');
  });

  test('deleteExercise should remove the exercise with the given id', () async {
    final exercise1 = ExerciseTemplate(
      id: '1',
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.medium,
    );

    final exercise2 = ExerciseTemplate(
      id: '2',
      name: 'Squat',
      muscleGroup: MuscleGroup.quadriceps,
      repetitionsRangeTarget: RepetitionsRange.high,
    );

    await inMemoryExerciseRepository.addExercise(exercise1);
    await inMemoryExerciseRepository.addExercise(exercise2);

    await inMemoryExerciseRepository.deleteExercise('2');

    final exercises = await inMemoryExerciseRepository.getExercises() as Ok<List<ExerciseTemplate>>;

    expect(exercises.value, [exercise1]);
  });

  test('deleteExercise should remove the exercise with the given id even if not last', () async {
    final exercise1 = ExerciseTemplate(
      id: '1',
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.medium,
    );

    final exercise2 = ExerciseTemplate(
      id: '2',
      name: 'Squat',
      muscleGroup: MuscleGroup.quadriceps,
      repetitionsRangeTarget: RepetitionsRange.high,
    );

    final exercise3 = ExerciseTemplate(
      id: '3',
      name: 'Deadlift',
      muscleGroup: MuscleGroup.hamstrings,
      repetitionsRangeTarget: RepetitionsRange.high,
    );

    await inMemoryExerciseRepository.addExercise(exercise1);
    await inMemoryExerciseRepository.addExercise(exercise2);
    await inMemoryExerciseRepository.addExercise(exercise3);

    await inMemoryExerciseRepository.deleteExercise('2');

    final exercises = await inMemoryExerciseRepository.getExercises() as Ok<List<ExerciseTemplate>>;

    expect(exercises.value, [exercise1, exercise3]);
  });

  test('deleteExercise should throw an exception if the exercise does not exist', () async {
    final exercise1 = ExerciseTemplate(
      id: '1',
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.medium,
    );

    final exercise2 = ExerciseTemplate(
      id: '2',
      name: 'Squat',
      muscleGroup: MuscleGroup.quadriceps,
      repetitionsRangeTarget: RepetitionsRange.high,
    );

    await inMemoryExerciseRepository.addExercise(exercise1);
    await inMemoryExerciseRepository.addExercise(exercise2);

    final result = await inMemoryExerciseRepository.deleteExercise('3') as Error<ExerciseTemplate>;

    expect(result, isA<Error<ExerciseTemplate>>());
    expect(result.error, isA<ExerciseNotFoundException>());
    expect(result.error.toString(), 'ExerciseNotFoundException: Exercise 3 not found');
  });

  test('deleteExercise should throw an exception if an empty id is provided', () async {
    final result = await inMemoryExerciseRepository.deleteExercise('') as Error<ExerciseTemplate>;

    expect(result, isA<Error<ExerciseTemplate>>());
    expect(result.error, isA<ExerciseNotFoundException>());
    expect(result.error.toString(), 'ExerciseNotFoundException: Exercise  not found');
  });
}
import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/data/models/exercise.dart';
import 'package:exercise_management/data/repository/exercise_repository.dart';
import 'package:exercise_management/data/repository/in_memory_exercise_repository.dart';
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

    expect(result.isSuccess, true);
    expect(exercises.data, [exercise]);
  });

  test('addExercise should generate an exercise id if null provided', () async {
    final exercise = ExerciseTemplate(
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.medium,
    );

    await inMemoryExerciseRepository.addExercise(exercise);

    final exercises = (await inMemoryExerciseRepository.getExercises());

    expect(exercises.data?.first.id, isNotNull);
  });

  test('addExercise with an existing exercise should fail', () async {
    final exercise = ExerciseTemplate(
      id: '1',
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.medium,
    );

    final resultOriginal = await inMemoryExerciseRepository.addExercise(exercise);
    final resultDuplicate = await inMemoryExerciseRepository.addExercise(exercise);

    expect(resultOriginal.isSuccess, true);
    expect(resultDuplicate.isSuccess, false);
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

    final exercises = await inMemoryExerciseRepository.getExercises();

    expect(exercises.data, [exercise1, exercise2]);
  });

  test('getExercises should return an empty list if no exercises are in the repository', () async {
    final exercises = await inMemoryExerciseRepository.getExercises();

    expect(exercises.data, []);
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

    final exercise = await inMemoryExerciseRepository.getExercise('2');

    expect(exercise.data, exercise2);
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

    final exercise = await inMemoryExerciseRepository.getExercise('3');

    expect(exercise.isFailure, true);
    expect(exercise.error, isA<ExerciseNotFoundException>());
    expect(exercise.error.toString(), 'ExerciseNotFoundException: Exercise 3 not found');
  });
}
import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/data/models/exercise.dart';
import 'package:exercise_management/data/repository/in_memory_exercise_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryExerciseRepository inMemoryExerciseRepository;

  setUp(() {
    inMemoryExerciseRepository = InMemoryExerciseRepository();
  });

  test('addExercise should add an exercise to the repository', () async {
    final exercise = Exercise(
      id: '1',
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.medium,
    );

    await inMemoryExerciseRepository.addExercise(exercise);

    final exercises = await inMemoryExerciseRepository.getExercises();

    expect(exercises, [exercise]);
  });

  test('deleteExercise should remove an exercise from the repository', () async {
    final exercise = Exercise(
      id: '1',
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.medium,
    );

    await inMemoryExerciseRepository.addExercise(exercise);
    await inMemoryExerciseRepository.deleteExercise(exercise);

    final exercises = await inMemoryExerciseRepository.getExercises();

    expect(exercises, []);
  });

  test('getExercises should return all exercises from the repository', () async {
    final exercise1 = Exercise(
      id: '1',
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.medium,
    );

    final exercise2 = Exercise(
      id: '2',
      name: 'Squat',
      muscleGroup: MuscleGroup.quadriceps,
      repetitionsRangeTarget: RepetitionsRange.high,
    );

    await inMemoryExerciseRepository.addExercise(exercise1);
    await inMemoryExerciseRepository.addExercise(exercise2);

    final exercises = await inMemoryExerciseRepository.getExercises();

    expect(exercises, [exercise1, exercise2]);
  });

  test('getExercise should return the exercise with the given id', () async {
    final exercise1 = Exercise(
      id: '1',
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.medium,
    );

    final exercise2 = Exercise(
      id: '2',
      name: 'Squat',
      muscleGroup: MuscleGroup.quadriceps,
      repetitionsRangeTarget: RepetitionsRange.high,
    );

    await inMemoryExerciseRepository.addExercise(exercise1);
    await inMemoryExerciseRepository.addExercise(exercise2);

    final exercise = await inMemoryExerciseRepository.getExercise('2');

    expect(exercise, exercise2);
  });

  test('updateExercise should update the exercise with the given id', () async {
    final exercise1 = Exercise(
      id: '1',
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.medium,
    );

    final exercise2 = Exercise(
      id: '2',
      name: 'Squat',
      muscleGroup: MuscleGroup.quadriceps,
      repetitionsRangeTarget: RepetitionsRange.high,
    );

    await inMemoryExerciseRepository.addExercise(exercise1);
    await inMemoryExerciseRepository.addExercise(exercise2);

    final updatedExercise = Exercise(
      id: '2',
      name: 'Squat',
      muscleGroup: MuscleGroup.quadriceps,
      repetitionsRangeTarget: RepetitionsRange.low,
    );

    await inMemoryExerciseRepository.updateExercise(updatedExercise);

    final exercises = await inMemoryExerciseRepository.getExercises();

    expect(exercises, [exercise1, updatedExercise]);
  });
}
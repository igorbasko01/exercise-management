import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise.dart';
import 'package:exercise_management/data/repository/exercise_repository.dart';
import 'package:exercise_management/service/exercise_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExerciseRepository extends Mock implements ExerciseRepository {}

void main() {
  group('Exercise service add exercise', () {
    test('should add an exercise to the repository', () async {
      // Arrange
      final exercise = Exercise(
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium,
      );

      final inMemoryExerciseRepository = MockExerciseRepository();
      when(() => inMemoryExerciseRepository.addExercise(exercise)).thenAnswer((_) async => Result.success(exercise));
      when(() => inMemoryExerciseRepository.getExercises()).thenAnswer((_) async => Result.success([exercise]));

      final exerciseService = ExerciseServiceImpl(inMemoryExerciseRepository);

      // Act
      final result = await exerciseService.addExercise(exercise);
      final exercises = await exerciseService.getExercises();

      // Assert
      expect(result.isSuccess, true);
      expect(exercises.data, [exercise]);
    });
  });

  group('getExercises', () {
    test('should return a list of exercises', () async {
      // Arrange
      final exercise = Exercise(
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium,
      );

      final inMemoryExerciseRepository = MockExerciseRepository();
      when(() => inMemoryExerciseRepository.getExercises()).thenAnswer((_) async => Result.success([exercise]));

      final exerciseService = ExerciseServiceImpl(inMemoryExerciseRepository);

      // Act
      final result = await exerciseService.getExercises();

      // Assert
      expect(result.isSuccess, true);
      expect(result.data, [exercise]);
    });
  });

  group('getExercise', () {
    test('should return an exercise', () async {
      // Arrange
      final exercise = Exercise(
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium,
      );

      final inMemoryExerciseRepository = MockExerciseRepository();
      when(() => inMemoryExerciseRepository.getExercise('1')).thenAnswer((_) async => Result.success(exercise));

      final exerciseService = ExerciseServiceImpl(inMemoryExerciseRepository);

      // Act
      final result = await exerciseService.getExercise('1');

      // Assert
      expect(result.isSuccess, true);
      expect(result.data, exercise);
    });
  });
}
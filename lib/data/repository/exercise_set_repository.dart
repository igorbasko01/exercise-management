import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set.dart';

/// This repository handles a specific exercise set that was performed.
abstract class ExerciseSetRepository {
  Future<Result<ExerciseSet>> addExercise(ExerciseSet exerciseSet);
  Future<Result<void>> addExercises(List<ExerciseSet> exerciseSets);
  Future<Result<List<ExerciseSet>>> getExercises();
  Future<Result<ExerciseSet>> getExercise(String id);
  Future<Result<ExerciseSet>> updateExercise(ExerciseSet exerciseSet);
  Future<Result<ExerciseSet>> deleteExercise(String id);
}

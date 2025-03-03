import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set.dart';

abstract class ExerciseSetRepository {
  Future<Result<ExerciseSet>> addExercise(ExerciseSet exerciseSet);
  Future<Result<List<ExerciseSet>>> getExercises();
  Future<Result<ExerciseSet>> getExercise(String id);
  Future<Result<ExerciseSet>> updateExercise(ExerciseSet exerciseSet);
  Future<Result<ExerciseSet>> deleteExercise(String id);
}
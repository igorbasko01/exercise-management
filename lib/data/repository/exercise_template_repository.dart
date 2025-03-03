import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_template.dart';

abstract class ExerciseTemplateRepository {
  Future<Result<ExerciseTemplate>> addExercise(ExerciseTemplate exercise);
  Future<Result<List<ExerciseTemplate>>> getExercises();
  Future<Result<ExerciseTemplate>> getExercise(String id);
  Future<Result<ExerciseTemplate>> updateExercise(ExerciseTemplate exercise);
  Future<Result<ExerciseTemplate>> deleteExercise(String id);
}
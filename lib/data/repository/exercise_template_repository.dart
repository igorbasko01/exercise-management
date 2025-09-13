import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_template.dart';

/// This repository handles a specific exercise template that can be performed.
/// An [ExerciseTemplate] is basically a description of an exercise.
abstract class ExerciseTemplateRepository {
  Future<Result<ExerciseTemplate>> addExercise(ExerciseTemplate exercise);
  Future<Result<List<ExerciseTemplate>>> getExercises();
  Future<Result<ExerciseTemplate>> getExercise(String id);
  Future<Result<ExerciseTemplate>> updateExercise(ExerciseTemplate exercise);
  Future<Result<ExerciseTemplate>> deleteExercise(String id);
  Future<Result<void>> clearAll();
}

import 'package:exercise_management/core/base_exception.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_template.dart';

abstract class ExerciseTemplateRepository {
  Future<Result<ExerciseTemplate>> addExercise(ExerciseTemplate exercise);
  Future<Result<List<ExerciseTemplate>>> getExercises();
  Future<Result<ExerciseTemplate>> getExercise(String id);
  Future<Result<ExerciseTemplate>> updateExercise(ExerciseTemplate exercise);
  Future<Result<ExerciseTemplate>> deleteExercise(String id);
}

class ExerciseNotFoundException extends BaseException {
  ExerciseNotFoundException(super.message);
}

class ExerciseAlreadyExistsException extends BaseException {
  ExerciseAlreadyExistsException(super.message);
}
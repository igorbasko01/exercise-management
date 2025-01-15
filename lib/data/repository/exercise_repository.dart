import 'package:exercise_management/core/base_exception.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise.dart';

abstract class ExerciseRepository {
  Future<Result<Exercise>> addExercise(Exercise exercise);
  Future<Result<List<Exercise>>> getExercises();
  Future<Result<Exercise>> getExercise(String id);
}

class ExerciseNotFoundException extends BaseException {
  ExerciseNotFoundException(super.message);
}

class ExerciseAlreadyExistsException extends BaseException {
  ExerciseAlreadyExistsException(super.message);
}
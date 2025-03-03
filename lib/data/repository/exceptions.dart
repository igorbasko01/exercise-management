import 'package:exercise_management/core/base_exception.dart';

class ExerciseNotFoundException extends BaseException {
  ExerciseNotFoundException(super.message);
}

class ExerciseAlreadyExistsException extends BaseException {
  ExerciseAlreadyExistsException(super.message);
}
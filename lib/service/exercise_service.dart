import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise.dart';
import 'package:exercise_management/data/repository/exercise_repository.dart';

abstract class ExerciseService {
  Future<Result<Exercise>> addExercise(Exercise exercise);
  Future<Result<List<Exercise>>> getExercises();
  Future<Result<Exercise>> getExercise(String id);
}

class ExerciseServiceImpl extends ExerciseService {
  final ExerciseRepository exerciseRepository;

  ExerciseServiceImpl(this.exerciseRepository);

  @override
  Future<Result<Exercise>> addExercise(Exercise exercise) {
    return exerciseRepository.addExercise(exercise);
  }

  @override
  Future<Result<Exercise>> getExercise(String id) {
    return exerciseRepository.getExercise(id);
  }

  @override
  Future<Result<List<Exercise>>> getExercises() {
    return exerciseRepository.getExercises();
  }
}
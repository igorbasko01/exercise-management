import 'package:exercise_management/core/iterable_extensions.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise.dart';
import 'package:exercise_management/data/repository/exercise_repository.dart';

class InMemoryExerciseRepository extends ExerciseRepository {
  final List<ExerciseTemplate> _exercises = [];

  @override
  Future<Result<ExerciseTemplate>> addExercise(ExerciseTemplate exercise) async {
    if (exercise.id == null) {
      exercise = exercise.copyWith(id: uniqueId());
    }

    if (_exercises.contains(exercise)) {
      return Result.failure(ExerciseAlreadyExistsException('Exercise ${exercise.id} already exists'));
    }

    _exercises.add(exercise);
    return Result.success(exercise);
  }

  @override
  Future<Result<List<ExerciseTemplate>>> getExercises() async {
    return Result.success(_exercises);
  }

  @override
  Future<Result<ExerciseTemplate>> getExercise(String id) async {
    var exercise = _exercises.firstWhereOrNull((exercise) => exercise.id == id);
    if (exercise == null) {
      return Result.failure(ExerciseNotFoundException('Exercise $id not found'));
    }
    return Result.success(exercise);
  }

  String uniqueId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
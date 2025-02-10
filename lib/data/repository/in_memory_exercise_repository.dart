import 'package:exercise_management/core/iterable_extensions.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise.dart';
import 'package:exercise_management/data/repository/exercise_repository.dart';

class InMemoryExerciseRepository extends ExerciseTemplateRepository {
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

  @override
  Future<Result<ExerciseTemplate>> deleteExercise(String id) {
    var exerciseIndex = _exercises.indexWhere((e) => e.id == id);
    if (exerciseIndex == -1) {
      return Future.value(Result.failure(ExerciseNotFoundException('Exercise $id not found')));
    }
    var exercise = _exercises.removeAt(exerciseIndex);
    return Future.value(Result.success(exercise));
  }

  @override
  Future<Result<ExerciseTemplate>> updateExercise(ExerciseTemplate exercise) async {
    var exerciseIndex = _exercises.indexWhere((e) => e.id == exercise.id);
    if (exerciseIndex == -1) {
      return Result.failure(ExerciseNotFoundException('Exercise ${exercise.id} not found'));
    }
    var storedExercise = _exercises[exerciseIndex];
    _exercises[exerciseIndex] = exercise.copyWith(id: storedExercise.id);
    return Result.success(exercise);
  }
}
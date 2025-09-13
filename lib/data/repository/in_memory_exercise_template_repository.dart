import 'package:exercise_management/core/iterable_extensions.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/core/utils.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exercise_template_repository.dart';
import 'package:exercise_management/data/repository/exceptions.dart';

class InMemoryExerciseRepository extends ExerciseTemplateRepository {
  final List<ExerciseTemplate> _exercises = [];

  @override
  Future<Result<ExerciseTemplate>> addExercise(ExerciseTemplate exercise) async {
    if (exercise.id == null) {
      exercise = exercise.copyWith(id: uniqueId());
    }

    if (_exercises.contains(exercise)) {
      return Result.error(ExerciseAlreadyExistsException('Exercise ${exercise.id} already exists'));
    }

    _exercises.add(exercise);
    return Result.ok(exercise);
  }

  @override
  Future<Result<List<ExerciseTemplate>>> getExercises() async {
    return Result.ok(_exercises);
  }

  @override
  Future<Result<ExerciseTemplate>> getExercise(String id) async {
    var exercise = _exercises.firstWhereOrNull((exercise) => exercise.id == id);
    if (exercise == null) {
      return Result.error(ExerciseNotFoundException('Exercise $id not found'));
    }
    return Result.ok(exercise);
  }

  @override
  Future<Result<ExerciseTemplate>> deleteExercise(String id) {
    var exerciseIndex = _exercises.indexWhere((e) => e.id == id);
    if (exerciseIndex == -1) {
      return Future.value(Result.error(ExerciseNotFoundException('Exercise $id not found')));
    }
    var exercise = _exercises.removeAt(exerciseIndex);
    return Future.value(Result.ok(exercise));
  }

  @override
  Future<Result<ExerciseTemplate>> updateExercise(ExerciseTemplate exercise) async {
    var exerciseIndex = _exercises.indexWhere((e) => e.id == exercise.id);
    if (exerciseIndex == -1) {
      return Result.error(ExerciseNotFoundException('Exercise ${exercise.id} not found'));
    }
    var storedExercise = _exercises[exerciseIndex];
    _exercises[exerciseIndex] = exercise.copyWith(id: storedExercise.id);
    return Result.ok(exercise);
  }

  @override
  Future<Result<void>> clearAll() {
    _exercises.clear();
    return Future.value(Result.ok(null));
  }
}
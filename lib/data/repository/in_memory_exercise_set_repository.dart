import 'package:exercise_management/core/iterable_extensions.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/core/utils.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/repository/exceptions.dart';
import 'package:exercise_management/data/repository/exercise_set_repository.dart';

class InMemoryExerciseSetRepository implements ExerciseSetRepository {
  final List<ExerciseSet> _exerciseSets = [];

  @override
  Future<Result<ExerciseSet>> addExercise(ExerciseSet exerciseSet) async {
    if (exerciseSet.id == null) {
      exerciseSet = exerciseSet.copyWith(id: uniqueId());
    }

    if (_exerciseSets.contains(exerciseSet)) {
      return Result.error(ExerciseAlreadyExistsException('Exercise set ${exerciseSet.id} already exists'));
    }

    _exerciseSets.add(exerciseSet);
    return Result.ok(exerciseSet);
  }

  @override
  Future<Result<ExerciseSet>> deleteExercise(String id) async {
    final index = _exerciseSets.indexWhere((element) => element.id == id);
    if (index == -1) {
      return Result.error(ExerciseNotFoundException('Exercise set $id not found'));
    }
    final exerciseSet = _exerciseSets.removeAt(index);
    return Result.ok(exerciseSet);
  }

  @override
  Future<Result<ExerciseSet>> getExercise(String id) async {
    final exerciseSet = _exerciseSets.firstWhereOrNull((exerciseSet) => exerciseSet.id == id);
    if (exerciseSet == null) {
      return Result.error(ExerciseNotFoundException('Exercise set $id not found'));
    }
    return Result.ok(exerciseSet);
  }

  @override
  Future<Result<List<ExerciseSet>>> getExercises() async {
    return Result.ok(_exerciseSets);
  }

  @override
  Future<Result<ExerciseSet>> updateExercise(ExerciseSet exerciseSet) async {
    final index = _exerciseSets.indexWhere((element) => element.id == exerciseSet.id);
    if (index == -1) {
      return Result.error(ExerciseNotFoundException('Exercise set ${exerciseSet.id} not found'));
    }
    _exerciseSets[index] = exerciseSet;
    return Result.ok(exerciseSet);
  }

  @override
  Future<Result<void>> addExercises(List<ExerciseSet> exerciseSets) async {
    for (var exerciseSet in exerciseSets) {
      if (exerciseSet.id == null) {
        exerciseSet = exerciseSet.copyWith(id: uniqueId());
      }

      if (_exerciseSets.contains(exerciseSet)) {
        return Result.error(ExerciseAlreadyExistsException('Exercise set ${exerciseSet.id} already exists'));
      }

      _exerciseSets.add(exerciseSet);
    }
    return Result.ok(null);
  }

  @override
  Future<Result<void>> clearAll() {
    _exerciseSets.clear();
    return Future.value(Result.ok(null));
  }
}
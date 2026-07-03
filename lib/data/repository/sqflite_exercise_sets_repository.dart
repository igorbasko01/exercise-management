import 'dart:async';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/core/value.dart';

import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/repository/exceptions.dart';
import 'package:exercise_management/data/repository/exercise_set_repository.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteExerciseSetsRepository extends ExerciseSetRepository {
  final Database database;
  static String tableName = 'exercise_sets';
  final _controller = StreamController<void>.broadcast();

  SqfliteExerciseSetsRepository(this.database);

  @override
  Stream<void> watchExerciseSets() => _controller.stream;

  void _notify() => _controller.add(null);

  @override
  Future<Result<ExerciseSet>> addExercise(ExerciseSet exerciseSet) async {
    try {
      final map = exerciseSet.toMap();
      final id = exerciseSet.id ?? DateTime.now().millisecondsSinceEpoch.toString() + 'temp' + exerciseSet.hashCode.toString();
      map['id'] = id;
      map['sync_status'] = 'pending_insert';
      map['last_updated_at'] = DateTime.now().toUtc().toIso8601String();

      await database.insert(tableName, map,
          conflictAlgorithm: ConflictAlgorithm.rollback);
      _notify();
      return Result.ok(exerciseSet.copyWith(id: Value(id.toString())));
    } catch (e) {
      return Result.error(
          ExerciseAlreadyExistsException("Exercise already exists"));
    }
  }

  @override
  Future<Result<ExerciseSet>> deleteExercise(String id) async {
    final exerciseSetResult = await getExercise(id);
    if (exerciseSetResult is Error<ExerciseSet>) {
      return exerciseSetResult;
    }

    final exerciseSet = (exerciseSetResult as Ok<ExerciseSet>).value;

    final count = await database.update(
      tableName,
      {
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
        'sync_status': 'pending_delete',
        'last_updated_at': DateTime.now().toUtc().toIso8601String()
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count == 0) {
      return Result.error(ExerciseNotFoundException('Exercise $id not found'));
    }
    _notify();
    return Result.ok(exerciseSet);
  }

  @override
  Future<Result<ExerciseSet>> getExercise(String id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    if (maps.isEmpty) {
      return Result.error(ExerciseNotFoundException('Exercise $id not found'));
    }
    return Result.ok(ExerciseSet.fromMap(maps.first));
  }

  @override
  Future<Result<List<ExerciseSet>>> getExercises() async {
    final List<Map<String, dynamic>> maps =
        await database.query(tableName, where: 'deleted_at IS NULL', orderBy: 'id');
    return Result.ok(maps.map((e) => ExerciseSet.fromMap(e)).toList());
  }

  @override
  Future<Result<ExerciseSet>> updateExercise(ExerciseSet exerciseSet) async {
    try {
      final map = exerciseSet.toMap();
      map['sync_status'] = 'pending_update';
      map['last_updated_at'] = DateTime.now().toUtc().toIso8601String();

      int count = await database.update(
        tableName,
        map,
        where: 'id = ?',
        whereArgs: [exerciseSet.id],
      );
      if (count == 0) {
        return Result.error(
            ExerciseNotFoundException('Exercise ${exerciseSet.id} not found'));
      }
      _notify();
      return Result.ok(exerciseSet);
    } catch (e) {
      return Result.error(
          ExerciseNotFoundException('Exercise ${exerciseSet.id} not found'));
    }
  }

  @override
  Future<Result<void>> addExercises(List<ExerciseSet> exerciseSets) async {
    final batch = database.batch();
    for (var exerciseSet in exerciseSets) {
      final map = exerciseSet.toMap();
      final id = exerciseSet.id ?? DateTime.now().millisecondsSinceEpoch.toString() + 'temp' + exerciseSet.hashCode.toString();
      map['id'] = id;
      map['sync_status'] = 'pending_insert';
      map['last_updated_at'] = DateTime.now().toUtc().toIso8601String();
      batch.insert(tableName, map,
          conflictAlgorithm: ConflictAlgorithm.rollback);
    }
    try {
      await batch.commit(noResult: true);
      _notify();
      return Result.ok(null);
    } catch (e) {
      return Result.error(ExerciseAlreadyExistsException(
          "One or more exercises already exist"));
    }
  }

  @override
  Future<Result<void>> clearAll() async {
    try {
      await database.delete(tableName);
      _notify();
      return Result.ok(null);
    } catch (e) {
      return Result.error(
          ExerciseNotFoundException('Error clearing exercises: $e'));
    }
  }
}

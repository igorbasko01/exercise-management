import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/repository/exceptions.dart';
import 'package:exercise_management/data/repository/exercise_set_repository.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteExerciseSetsRepository extends ExerciseSetRepository {
  final Database database;
  static String tableName = 'exercise_sets';

  SqfliteExerciseSetsRepository(this.database);

  @override
  Future<Result<ExerciseSet>> addExercise(ExerciseSet exerciseSet) async {
    try {
      final id = await database.insert(tableName, exerciseSet.toMap(),
          conflictAlgorithm: ConflictAlgorithm.rollback);
      return Result.ok(exerciseSet.copyWith(id: id.toString()));
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

    final count = await database.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count == 0)
    {
      return Result.error(ExerciseNotFoundException('Exercise $id not found'));
    }
    return Result.ok(exerciseSet);
  }

  @override
  Future<Result<ExerciseSet>> getExercise(String id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) {
      return Result.error(ExerciseNotFoundException('Exercise $id not found'));
    }
    return Result.ok(ExerciseSet.fromMap(maps.first));
  }

  @override
  Future<Result<List<ExerciseSet>>> getExercises() async {
    final List<Map<String, dynamic>> maps = await database.query(tableName, orderBy: 'id');
    return Result.ok(maps.map((e) => ExerciseSet.fromMap(e)).toList());
  }

  @override
  Future<Result<ExerciseSet>> updateExercise(ExerciseSet exerciseSet) async {
    try {
      int count = await database.update(
        tableName,
        exerciseSet.toMap(),
        where: 'id = ?',
        whereArgs: [exerciseSet.id],
      );
      if (count == 0) {
        return Result.error(
            ExerciseNotFoundException('Exercise ${exerciseSet.id} not found'));
      }
      return Result.ok(exerciseSet);
    } catch (e) {
      return Result.error(
          ExerciseNotFoundException('Exercise ${exerciseSet.id} not found'));
    }
  }
}

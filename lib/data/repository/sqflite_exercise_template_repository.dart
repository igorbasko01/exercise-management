import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/core/value.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exceptions.dart';
import 'package:exercise_management/data/repository/exercise_template_repository.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteExerciseTemplateRepository implements ExerciseTemplateRepository {
  final Database database;
  static String tableName = 'exercise_templates';

  SqfliteExerciseTemplateRepository(this.database);

  @override
  Future<Result<ExerciseTemplate>> addExercise(
      ExerciseTemplate exercise) async {
    try {
      final map = exercise.toMap();
      final id = exercise.id ?? DateTime.now().millisecondsSinceEpoch.toString() + 'temp';
      map['id'] = id;
      map['sync_status'] = 'pending_insert';
      map['last_updated_at'] = DateTime.now().toUtc().toIso8601String();

      await database.insert(tableName, map,
          conflictAlgorithm: ConflictAlgorithm.rollback);
      return Result.ok(exercise.copyWith(id: Value(id.toString())));
    } catch (e) {
      return Result.error(
          ExerciseAlreadyExistsException("Exercise already exists"));
    }
  }

  @override
  Future<Result<List<ExerciseTemplate>>> getExercises() async {
    final List<Map<String, dynamic>> maps =
        await database.query(tableName, where: 'deleted_at IS NULL', orderBy: 'id');
    return Result.ok(maps.map((e) => ExerciseTemplate.fromMap(e)).toList());
  }

  @override
  Future<Result<ExerciseTemplate>> getExercise(String id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [id],
    );
    if (maps.isEmpty) {
      return Result.error(ExerciseNotFoundException('Exercise $id not found'));
    }
    return Result.ok(ExerciseTemplate.fromMap(maps.first));
  }

  @override
  Future<Result<ExerciseTemplate>> updateExercise(
      ExerciseTemplate exercise) async {
    try {
      final map = exercise.toMap();
      map['sync_status'] = 'pending_update';
      map['last_updated_at'] = DateTime.now().toUtc().toIso8601String();

      int count = await database.update(
        tableName,
        map,
        where: 'id = ?',
        whereArgs: [exercise.id],
      );
      if (count == 0) {
        return Result.error(
            ExerciseNotFoundException('Exercise ${exercise.id} not found'));
      }
      return Result.ok(exercise);
    } catch (e) {
      return Result.error(
          ExerciseNotFoundException('Exercise ${exercise.id} not found'));
    }
  }

  @override
  Future<Result<ExerciseTemplate>> deleteExercise(String id) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) {
        return Result.error(
            ExerciseNotFoundException('Exercise $id not found'));
      }

      final exercise = ExerciseTemplate.fromMap(maps.first);

      final int count = await database.update(
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
        return Result.error(
            ExerciseNotFoundException('Exercise $id not found'));
      }

      return Result.ok(exercise);
    } catch (e) {
      return Result.error(ExerciseNotFoundException('Exercise $id not found'));
    }
  }

  @override
  Future<Result<void>> clearAll() async {
    try {
      await database.delete(tableName);
      return Result.ok(null);
    } catch (e) {
      return Result.error(
          ExerciseNotFoundException('Error clearing exercise templates: $e'));
    }
  }
}

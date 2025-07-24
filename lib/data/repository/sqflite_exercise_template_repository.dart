import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exceptions.dart';
import 'package:exercise_management/data/repository/exercise_template_repository.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteExerciseTemplateRepository implements ExerciseTemplateRepository {
  final Database database;
  final String tableName = 'exercise_templates';

  SqfliteExerciseTemplateRepository(this.database);

  @override
  Future<Result<ExerciseTemplate>> addExercise(
      ExerciseTemplate exercise) async {
    try {
      final id = await database.insert(tableName, exercise.toMap(),
          conflictAlgorithm: ConflictAlgorithm.rollback);
      return Result.ok(exercise.copyWith(id: id.toString()));
    } catch (e) {
      return Result.error(
          ExerciseAlreadyExistsException("Exercise already exists"));
    }
  }

  @override
  Future<Result<List<ExerciseTemplate>>> getExercises() async {
    final List<Map<String, dynamic>> maps =
        await database.query(tableName, orderBy: 'id');
    return Result.ok(maps.map((e) => ExerciseTemplate.fromMap(e)).toList());
  }

  @override
  Future<Result<ExerciseTemplate>> getExercise(String id) async {
    final List<Map<String, dynamic>> maps = await database.query(
      tableName,
      where: 'id = ?',
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
      int count = await database.update(
        tableName,
        exercise.toMap(),
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

      final int count = await database.delete(
        tableName,
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
}

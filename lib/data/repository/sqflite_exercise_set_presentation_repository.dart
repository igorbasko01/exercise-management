import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:exercise_management/data/models/exercise_set_presentation_mapper.dart';
import 'package:exercise_management/data/repository/exceptions.dart';
import 'package:exercise_management/data/repository/exercise_set_presentation_repository.dart';
import 'package:exercise_management/data/repository/sqflite_exercise_sets_repository.dart';
import 'package:exercise_management/data/repository/sqflite_exercise_template_repository.dart';
import 'package:sqflite/sqflite.dart';


class SqfliteExerciseSetPresentationRepository extends ExerciseSetPresentationRepository {
  final Database database;

  SqfliteExerciseSetPresentationRepository(this.database);

  @override
  Future<Result<List<ExerciseSetPresentation>>> getExerciseSets({int lastNDays = 7}) async {
    try {
      // First, get the last N distinct dates that have exercises
      final List<Map<String, dynamic>> distinctDates = await database.rawQuery('''
      SELECT DISTINCT DATE(date_time) as exercise_date
      FROM ${SqfliteExerciseSetsRepository.tableName}
      ORDER BY DATE(date_time) DESC
      LIMIT ?
      ''', [lastNDays]);

      if (distinctDates.isEmpty) {
        return Result.ok([]);
      }

      // Get the oldest date from the last N days
      final oldestDate = distinctDates.last['exercise_date'] as String;
      
      // Fetch all exercise sets from those N days
      final List<Map<String, dynamic>> maps = await database.rawQuery('''
      SELECT 
        es.id AS id,
        et.id AS exercise_template_id,
        es.date_time AS date_time,
        es.equipment_weight AS equipment_weight,
        es.plates_weight AS plates_weight,
        es.repetitions AS repetitions,
        et.name AS display_name,
        et.repetitions_range AS repetitions_range
      FROM ${SqfliteExerciseSetsRepository.tableName} es
      LEFT JOIN ${SqfliteExerciseTemplateRepository.tableName} et ON es.exercise_template_id = et.id
      WHERE DATE(es.date_time) >= ?
      ORDER BY es.id DESC
      ''', [oldestDate]);

      final exerciseSetPresentations = maps.map((map) => ExerciseSetPresentationMapper.fromMap(map)).toList();
      return Result.ok(exerciseSetPresentations);
    } catch (e) {
      return Result.error(ExerciseDatabaseException('Failed to fetch exercise sets: $e'));
    }
  }

  @override
  Future<Result<ExerciseSetPresentation>> getExerciseSet(String setId) async {
    try {
      final List<Map<String, dynamic>> maps = await database.rawQuery('''
      SELECT 
        es.id AS id,
        et.id AS exercise_template_id,
        es.date_time AS date_time,
        es.equipment_weight AS equipment_weight,
        es.plates_weight AS plates_weight,
        es.repetitions AS repetitions,
        et.name AS display_name,
        et.repetitions_range AS repetitions_range
      FROM ${SqfliteExerciseSetsRepository.tableName} es
      LEFT JOIN ${SqfliteExerciseTemplateRepository.tableName} et ON es.exercise_template_id = et.id
      WHERE es.id = ?
      ''', [setId]);

      if (maps.isEmpty) {
        return Result.error(ExerciseNotFoundException('Exercise set $setId not found'));
      }

      final exerciseSetPresentation = ExerciseSetPresentationMapper.fromMap(maps.first);
      return Result.ok(exerciseSetPresentation);
    } catch (e) {
      return Result.error(ExerciseDatabaseException('Failed to fetch exercise set: $e'));
    }
  }
}
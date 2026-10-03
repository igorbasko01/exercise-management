import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/core/services/exercise_ranking_manager.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:exercise_management/data/models/exercise_set_presentation_mapper.dart';
import 'package:exercise_management/data/repository/exceptions.dart';
import 'package:exercise_management/data/repository/exercise_set_presentation_repository.dart';
import 'package:exercise_management/data/repository/sqflite_exercise_sets_repository.dart';
import 'package:exercise_management/data/repository/sqflite_exercise_template_repository.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteExerciseSetPresentationRepository
    extends ExerciseSetPresentationRepository {
  final Database database;

  SqfliteExerciseSetPresentationRepository(this.database);

  /// Shared SELECT+JOIN shape behind every presentation query; callers
  /// append their own WHERE/ORDER BY/LIMIT and parameters.
  static final String _presentationSelectFromJoin = '''
      SELECT
        es.id AS id,
        et.id AS exercise_template_id,
        es.date_time AS date_time,
        es.equipment_weight AS equipment_weight,
        es.plates_weight AS plates_weight,
        es.repetitions AS repetitions,
        et.name AS display_name,
        et.repetitions_range AS repetitions_range,
        es.completed_at AS completed_at
      FROM ${SqfliteExerciseSetsRepository.tableName} es
      LEFT JOIN ${SqfliteExerciseTemplateRepository.tableName} et ON es.exercise_template_id = et.id
      ''';

  @override
  Future<Result<List<ExerciseSetPresentation>>> getExerciseSets(
      {int lastNDays = 7, String? exerciseTemplateId}) async {
    try {
      // Build the WHERE clause for filtering by exercise template ID
      final templateFilter =
          exerciseTemplateId != null ? 'AND es.exercise_template_id = ?' : '';
      final templateParams =
          exerciseTemplateId != null ? [exerciseTemplateId] : [];

      // First, get the last N distinct dates that have exercises
      final List<Map<String, dynamic>> distinctDates =
          await database.rawQuery('''
      SELECT DISTINCT DATE(date_time) as exercise_date
      FROM ${SqfliteExerciseSetsRepository.tableName} es
      WHERE 1=1 $templateFilter
      ORDER BY DATE(date_time) DESC
      LIMIT ?
      ''', [...templateParams, lastNDays]);

      if (distinctDates.isEmpty) {
        return Result.ok([]);
      }

      // Get the oldest date from the last N days
      final oldestDate = distinctDates.last['exercise_date'].toString();

      // Fetch all exercise sets from those N days
      final List<Map<String, dynamic>> maps = await database.rawQuery('''
      $_presentationSelectFromJoin
      WHERE DATE(es.date_time) >= ? $templateFilter
      ORDER BY es.id DESC
      ''', [oldestDate, ...templateParams]);

      final exerciseSetPresentations = maps
          .map((map) => ExerciseSetPresentationMapper.fromMap(map))
          .toList();
      return Result.ok(exerciseSetPresentations);
    } catch (e) {
      return Result.error(
          ExerciseDatabaseException('Failed to fetch exercise sets: $e'));
    }
  }

  @override
  Future<Result<Map<RankKey, int>>> getSessionVolumeRanks(
      {String? exerciseTemplateId}) async {
    try {
      final templateFilter =
          exerciseTemplateId != null ? 'AND exercise_template_id = ?' : '';
      final templateParams =
          exerciseTemplateId != null ? [exerciseTemplateId] : [];

      // RANK() gives standard competition ranking (1, 1, 3, 4, 4, 6...)
      // directly, matching ExerciseRankingManager.calculateRanks, so ties on
      // total volume share a rank without any post-processing here.
      final List<Map<String, dynamic>> rows = await database.rawQuery('''
      SELECT exercise_template_id, exercise_date,
        RANK() OVER (
          PARTITION BY exercise_template_id ORDER BY volume DESC
        ) AS rank
      FROM (
        SELECT exercise_template_id,
          DATE(date_time) AS exercise_date,
          SUM((equipment_weight + plates_weight) * repetitions) AS volume
        FROM ${SqfliteExerciseSetsRepository.tableName}
        WHERE 1=1 $templateFilter
        GROUP BY exercise_template_id, DATE(date_time)
      )
      ''', templateParams);

      final ranks = <RankKey, int>{};
      for (final row in rows) {
        final templateId = row['exercise_template_id'].toString();
        final date = row['exercise_date'].toString();
        ranks[RankKey(date, templateId)] = int.parse(row['rank'].toString());
      }
      return Result.ok(ranks);
    } catch (e) {
      return Result.error(ExerciseDatabaseException(
          'Failed to compute session volume ranks: $e'));
    }
  }

  @override
  Future<Result<ExerciseSetPresentation>> getExerciseSet(String setId) async {
    try {
      final List<Map<String, dynamic>> maps = await database.rawQuery('''
      $_presentationSelectFromJoin
      WHERE es.id = ?
      ''', [setId]);

      if (maps.isEmpty) {
        return Result.error(
            ExerciseNotFoundException('Exercise set $setId not found'));
      }

      final exerciseSetPresentation =
          ExerciseSetPresentationMapper.fromMap(maps.first);
      return Result.ok(exerciseSetPresentation);
    } catch (e) {
      return Result.error(
          ExerciseDatabaseException('Failed to fetch exercise set: $e'));
    }
  }

  @override
  Future<Result<Map<String, DateTime>>> getMostRecentCompletionDate(List<String> templateIds) async {
    if (templateIds.isEmpty) return Result.ok({});

    try {
      final placeholders = List.filled(templateIds.length, '?').join(', ');
      
      final List<Map<String, dynamic>> result = await database.rawQuery('''
      SELECT exercise_template_id, MAX(DATE(date_time)) as exercise_date
      FROM ${SqfliteExerciseSetsRepository.tableName}
      WHERE exercise_template_id IN ($placeholders)
      GROUP BY exercise_template_id
      ''', templateIds);

      final map = <String, DateTime>{};
      for (var row in result) {
        final templateId = row['exercise_template_id'].toString();
        final dateStr = row['exercise_date'].toString();
        map[templateId] = DateTime.parse(dateStr);
      }

      return Result.ok(map);
    } catch (e) {
      return Result.error(ExerciseDatabaseException('Failed to get most recent completion dates: $e'));
    }
  }

  @override
  Future<Result<DateTime?>> getStrictMostRecentRoutineCompletionDate(List<String> templateIds) async {
    if (templateIds.isEmpty) return Result.ok(null);

    try {
      final placeholders = List.filled(templateIds.length, '?').join(', ');
      
      final List<Map<String, dynamic>> result = await database.rawQuery('''
      SELECT DATE(date_time) as exercise_date
      FROM ${SqfliteExerciseSetsRepository.tableName}
      WHERE exercise_template_id IN ($placeholders)
      GROUP BY DATE(date_time)
      HAVING COUNT(DISTINCT exercise_template_id) = ?
      ORDER BY DATE(date_time) DESC
      LIMIT 1
      ''', [...templateIds, templateIds.length]);

      if (result.isEmpty) {
        return Result.ok(null);
      }

      final dateStr = result.first['exercise_date'].toString();
      return Result.ok(DateTime.parse(dateStr));
    } catch (e) {
      return Result.error(ExerciseDatabaseException('Failed to get strict most recent completion date: $e'));
    }
  }

  @override
  Future<Result<List<ExerciseSetPresentation>>> getExerciseSetsByDateAndTemplates(Map<String, DateTime> templateDates) async {
    if (templateDates.isEmpty) return Result.ok([]);

    try {
      final conditions = <String>[];
      final args = <Object>[];

      for (final entry in templateDates.entries) {
        final dateStr = '${entry.value.year}-${entry.value.month.toString().padLeft(2, '0')}-${entry.value.day.toString().padLeft(2, '0')}';
        conditions.add('(et.id = ? AND DATE(es.date_time) = ?)');
        args.add(entry.key);
        args.add(dateStr);
      }
      
      final whereClause = conditions.join(' OR ');

      final List<Map<String, dynamic>> maps = await database.rawQuery('''
      $_presentationSelectFromJoin
      WHERE $whereClause
      ORDER BY es.id ASC
      ''', args);

      final exerciseSetPresentations = maps
          .map((map) => ExerciseSetPresentationMapper.fromMap(map))
          .toList();
      return Result.ok(exerciseSetPresentations);
    } catch (e) {
      return Result.error(
          ExerciseDatabaseException('Failed to fetch exercise sets by date and templates: $e'));
    }
  }

  @override
  Future<Result<List<ExerciseSetPresentation>>> getBestMatchingHistoricalSession({
    required String exerciseTemplateId,
    required double firstSetWeight,
    required int firstSetReps,
    required DateTime excludeDate,
  }) async {
    try {
      final excludeDateStr =
          '${excludeDate.year}-${excludeDate.month.toString().padLeft(2, '0')}-${excludeDate.day.toString().padLeft(2, '0')}';

      // A session's "first set" is the earliest one logged that day (by
      // date_time, then id as a tiebreaker for sets sharing a timestamp,
      // e.g. ones copied forward together by progressSets).
      final List<Map<String, dynamic>> dateRows = await database.rawQuery('''
      WITH session_sets AS (
        SELECT *,
          ROW_NUMBER() OVER (
            PARTITION BY DATE(date_time)
            ORDER BY date_time ASC, id ASC
          ) AS set_order
        FROM ${SqfliteExerciseSetsRepository.tableName}
        WHERE exercise_template_id = ?
      ),
      session_summary AS (
        SELECT DATE(date_time) AS exercise_date,
          SUM((equipment_weight + plates_weight) * repetitions) AS volume,
          MAX(CASE WHEN set_order = 1 THEN (equipment_weight + plates_weight) END) AS first_weight,
          MAX(CASE WHEN set_order = 1 THEN repetitions END) AS first_reps
        FROM session_sets
        GROUP BY DATE(date_time)
      )
      SELECT exercise_date FROM session_summary
      WHERE first_weight = ? AND first_reps = ? AND exercise_date != ?
      ORDER BY volume DESC, exercise_date DESC
      LIMIT 1
      ''', [exerciseTemplateId, firstSetWeight, firstSetReps, excludeDateStr]);

      if (dateRows.isEmpty) {
        return Result.ok([]);
      }

      final bestDate = dateRows.first['exercise_date'].toString();

      final List<Map<String, dynamic>> maps = await database.rawQuery('''
      $_presentationSelectFromJoin
      WHERE es.exercise_template_id = ? AND DATE(es.date_time) = ?
      ORDER BY es.date_time ASC, es.id ASC
      ''', [exerciseTemplateId, bestDate]);

      final exerciseSetPresentations = maps
          .map((map) => ExerciseSetPresentationMapper.fromMap(map))
          .toList();
      return Result.ok(exerciseSetPresentations);
    } catch (e) {
      return Result.error(ExerciseDatabaseException(
          'Failed to fetch best matching historical session: $e'));
    }
  }
}

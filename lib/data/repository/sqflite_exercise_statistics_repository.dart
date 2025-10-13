import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_volume_statistic.dart';
import 'package:exercise_management/data/repository/exceptions.dart';
import 'package:exercise_management/data/repository/exercise_statistics_repository.dart';
import 'package:exercise_management/data/repository/sqflite_exercise_sets_repository.dart';
import 'package:exercise_management/data/repository/sqflite_exercise_template_repository.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteExerciseStatisticsRepository extends ExerciseStatisticsRepository {
  final Database database;

  SqfliteExerciseStatisticsRepository(this.database);

  @override
  Future<Result<List<bool>>> getCurrentWeekExerciseDays(
      {bool startFromSunday = true}) async {
    try {
      final now = DateTime.now();
      final startOfWeek = _getStartOfWeek(now, startFromSunday);
      final endOfWeek = startOfWeek.add(Duration(days: 6));
      final tableName = SqfliteExerciseSetsRepository.tableName;
      final result = await database.rawQuery('''
        SELECT DISTINCT DATE(date_time) as exercise_date
        FROM $tableName
        WHERE DATE(date_time) BETWEEN ? AND ?
        ''', [
        startOfWeek.toIso8601String().substring(0, 10),
        endOfWeek.toIso8601String().substring(0, 10)
      ]);

      final exerciseDates = result
          .map((row) => DateTime.parse(row['exercise_date'] as String))
          .toSet();
      final daysOfWeek = List.generate(7, (index) {
        final day = startOfWeek.add(Duration(days: index));
        return exerciseDates.contains(DateTime(day.year, day.month, day.day));
      });

      return Result.ok(daysOfWeek);
    } catch (e) {
      return Result.error(
          ExerciseDatabaseException('Failed to fetch exercise statistics: $e'));
    }
  }

  @override
  Future<Result<double>> getAverageWeeklyExerciseDays(int daysLookBack) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: daysLookBack));
      final tableName = SqfliteExerciseSetsRepository.tableName;

      final result = await database.rawQuery('''
        SELECT DISTINCT DATE(date_time) as exercise_date
        FROM $tableName
        WHERE DATE(date_time) BETWEEN ? AND ?
        ORDER BY exercise_date
        ''', [
        startDate.toIso8601String().substring(0, 10),
        now.toIso8601String().substring(0, 10)
      ]);

      final exerciseDates = result
          .map((row) => DateTime.parse(row['exercise_date'] as String))
          .toSet();

      // Calculate total exercise days
      final totalExerciseDays = exerciseDates.length;

      // Calculate number of weeks in the period
      final totalWeeks = daysLookBack / 7.0;

      // Calculate average exercise days per week
      final averagePerWeek = totalExerciseDays / totalWeeks;

      return Result.ok(averagePerWeek);
    } catch (e) {
      return Result.error(ExerciseDatabaseException(
          'Failed to fetch average weekly exercise statistics: $e'));
    }
  }

  @override
  Future<Result<List<ExerciseVolumeStatistics>>> getExerciseVolumeStatistics(
      {int numberOfExercises = 5}) async {
    try {
      final result = await database.rawQuery('''
    select 
      date(s.date_time), 
      s.exercise_template_id, 
      t.name, 
      sum((s.equipment_weight + s.plates_weight) * s.repetitions) as total_volume
    from ${SqfliteExerciseSetsRepository.tableName} s
    left join ${SqfliteExerciseTemplateRepository.tableName} t on t.id = s.exercise_template_id
    group by date(s.date_time), s.exercise_template_id, t.name
    having date(s.date_time) >= date('now', '-180 days')
    order by s.date_time asc
    ''');

      final exerciseVolumeStats = <int, ExerciseVolumeStatistics>{};

      for (var row in result) {
        final exerciseTemplateId = row['exercise_template_id'] as int;
        final exerciseName = row['name'] as String? ?? 'Unknown';
        final totalVolume = (row['total_volume'] as num).toInt();

        if (!exerciseVolumeStats.containsKey(exerciseTemplateId)) {
          exerciseVolumeStats[exerciseTemplateId] = ExerciseVolumeStatistics(
            exerciseName: exerciseName,
            volumePerDay: [],
          );
        }

        final stat = exerciseVolumeStats[exerciseTemplateId]!;
        stat.volumePerDay.add(totalVolume);
      }

      return Result.ok(
          exerciseVolumeStats.values.take(numberOfExercises).toList());
    } catch (e) {
      return Result.error(ExerciseDatabaseException(
          'Failed to fetch exercise volume statistics: $e'));
    }
  }

  DateTime _getStartOfWeek(DateTime date, bool startFromSunday) {
    final int weekday = date.weekday; // 1 (Mon) - 7 (Sun)
    final int daysToSubtract = startFromSunday
        ? (weekday % 7) // Sunday as start of the week
        : (weekday - 1); // Monday as start of the week
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysToSubtract));
  }
}

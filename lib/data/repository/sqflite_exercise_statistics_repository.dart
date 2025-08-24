import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/repository/exceptions.dart';
import 'package:exercise_management/data/repository/exercise_statistics_repository.dart';
import 'package:exercise_management/data/repository/sqflite_exercise_sets_repository.dart';
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

  DateTime _getStartOfWeek(DateTime date, bool startFromSunday) {
    final int weekday = date.weekday; // 1 (Mon) - 7 (Sun)
    final int daysToSubtract = startFromSunday
        ? (weekday % 7) // Sunday as start of the week
        : (weekday - 1); // Monday as start of the week
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysToSubtract));
  }
}

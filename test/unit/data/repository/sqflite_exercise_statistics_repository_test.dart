import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/database/database_factory.dart';
import 'package:exercise_management/data/database/exercise_database_creation.dart';
import 'package:exercise_management/data/database/exercise_database_migrations.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/models/exercise_volume_statistic.dart';
import 'package:exercise_management/data/repository/sqflite_exercise_sets_repository.dart';
import 'package:exercise_management/data/repository/sqflite_exercise_statistics_repository.dart';
import 'package:exercise_management/data/repository/sqflite_exercise_template_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late SqfliteExerciseSetsRepository setsRepository;
  late SqfliteExerciseTemplateRepository templatesRepository;
  late SqfliteExerciseStatisticsRepository statisticsRepository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await AppDatabaseFactory.createDatabase(
        inMemoryDatabasePath, createStatements, ExerciseDatabaseMigrations());
    setsRepository = SqfliteExerciseSetsRepository(db);
    templatesRepository = SqfliteExerciseTemplateRepository(db);
    statisticsRepository = SqfliteExerciseStatisticsRepository(db);

    await templatesRepository.addExercise(ExerciseTemplate(
        id: '1',
        name: 'Squat',
        muscleGroup: MuscleGroup.quadriceps,
        repetitionsRangeTarget: RepetitionsRange.medium));

    await templatesRepository.addExercise(ExerciseTemplate(
        id: '2',
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium));
  });

  tearDown(() async {
    await db.close();
  });

  test('getExerciseVolumeStatistics should return empty list when no data',
      () async {
    final result = await statisticsRepository.getExerciseVolumeStatistics();
    expect(result, isA<Ok<List<ExerciseVolumeStatistics>>>());
    final stats = (result as Ok<List<ExerciseVolumeStatistics>>).value;
    expect(stats, isEmpty);
  });

  test(
      'getExerciseVolumeStatistics should return correct statistics for single day single exercise',
      () async {
    final now = DateTime.now();

    // Add exercise sets for the last 5 days
    for (int i = 0; i < 4; i++) {
      await setsRepository.addExercise(ExerciseSet(
        exerciseTemplateId: '1',
        dateTime: now,
        equipmentWeight: 10,
        platesWeight: 20,
        repetitions: 5,
      ));
    }

    final result = await statisticsRepository.getExerciseVolumeStatistics();
    expect(result, isA<Ok<List<ExerciseVolumeStatistics>>>());
    final stats = (result as Ok<List<ExerciseVolumeStatistics>>).value;
    expect(stats.length, 1);
    expect(stats[0].volumePerDay[0], 4 * (10 + 20) * 5);
  });

  test(
      'getExerciseVolumeStatistics should return correct statistics for multiple days, single exercise',
      () async {
    final now = DateTime.now();
    for (int day = 0; day < 3; day++) {
      final date = now.subtract(Duration(days: day));
      for (int i = 0; i < 4; i++) {
        await setsRepository.addExercise(ExerciseSet(
          exerciseTemplateId: '1',
          dateTime: date,
          equipmentWeight: 10,
          platesWeight: 20,
          repetitions: 6 + i,
        ));
      }
    }

    final result = await statisticsRepository.getExerciseVolumeStatistics();
    expect(result, isA<Ok<List<ExerciseVolumeStatistics>>>());
    final stats = (result as Ok<List<ExerciseVolumeStatistics>>).value;
    expect(stats.length, 1);
    expect(stats[0].volumePerDay.length, 3);
    expect(stats[0].volumePerDay.reduce((a, b) => a + b),
        3 * (10 + 20) * (6 + 7 + 8 + 9));
  });

  test(
      'getExerciseVolumeStatistics should return correct statistics for multiple days, multiple exercises',
      () async {
    final now = DateTime.now();
    final days = 3;
    for (int day = 0; day < days; day++) {
      final date = now.subtract(Duration(days: day));
      for (int i = 0; i < 4; i++) {
        await setsRepository.addExercise(ExerciseSet(
            exerciseTemplateId: '1',
            dateTime: date,
            equipmentWeight: 20,
            platesWeight: 10,
            repetitions: 6 + (days - day)));
        await setsRepository.addExercise(ExerciseSet(
            exerciseTemplateId: '2',
            dateTime: date,
            equipmentWeight: 20,
            platesWeight: 10,
            repetitions: 6 + (days - day)));
      }
    }

    final result = await statisticsRepository.getExerciseVolumeStatistics();
    expect(result, isA<Ok<List<ExerciseVolumeStatistics>>>());
    final stats = (result as Ok<List<ExerciseVolumeStatistics>>).value;
    expect(stats.length, 2);
    for (var stat in stats) {
      expect(stat.volumePerDay.length, 3);
      expect(stat.volumePerDay.reduce((a, b) => a + b),
          4 * (20 + 10) * (9 + 8 + 7));
    }
  });

  test('getCurrentWeekExerciseDays should return correct days', () async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));

    // Add exercise sets on Monday, Wednesday, and Friday
    final daysToAdd = [1, 3, 5];
    for (var day in daysToAdd) {
      final date = startOfWeek.add(Duration(days: day));
      await setsRepository.addExercise(ExerciseSet(
        exerciseTemplateId: '1',
        dateTime: date,
        equipmentWeight: 10,
        platesWeight: 20,
        repetitions: 7,
      ));
    }

    final result = await statisticsRepository.getCurrentWeekExerciseDays(
        startFromSunday: true);

    expect(result, isA<Ok<List<bool>>>());
    final days = (result as Ok<List<bool>>).value;
    expect(days.length, 7);
    expect(days[0], false); // Sunday
    expect(days[1], true); // Monday
    expect(days[2], false); // Tuesday
    expect(days[3], true); // Wednesday
    expect(days[4], false); // Thursday
    expect(days[5], true); // Friday
    expect(days[6], false); // Saturday
  });

  test('getCurrentWeekExerciseDays with no exercises should return all false',
      () async {
    final result = await statisticsRepository.getCurrentWeekExerciseDays(
        startFromSunday: true);

    expect(result, isA<Ok<List<bool>>>());
    final days = (result as Ok<List<bool>>).value;
    expect(days.length, 7);
    expect(days.every((day) => day == false), true);
  });

  test('getCurrentWeekExerciseDays should handle exceptions', () async {
    // Close the database to simulate an error
    await db.close();

    final result = await statisticsRepository.getCurrentWeekExerciseDays(
        startFromSunday: true);

    expect(result, isA<Error<List<bool>>>());
  });

  test(
      'getCurrentWeekExerciseDays with Monday as start should return correct days',
      () async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    // Add exercise sets on Monday, Wednesday, and Friday
    final daysToAdd = [0, 2, 4];
    for (var day in daysToAdd) {
      final date = startOfWeek.add(Duration(days: day));
      await setsRepository.addExercise(ExerciseSet(
        exerciseTemplateId: '1',
        dateTime: date,
        equipmentWeight: 10,
        platesWeight: 20,
        repetitions: 7,
      ));
    }

    final result = await statisticsRepository.getCurrentWeekExerciseDays(
        startFromSunday: false);

    expect(result, isA<Ok<List<bool>>>());
    final days = (result as Ok<List<bool>>).value;
    expect(days.length, 7);
    expect(days[0], true); // Monday
    expect(days[1], false); // Tuesday
    expect(days[2], true); // Wednesday
    expect(days[3], false); // Thursday
    expect(days[4], true); // Friday
    expect(days[5], false); // Saturday
    expect(days[6], false); // Sunday
  });
}

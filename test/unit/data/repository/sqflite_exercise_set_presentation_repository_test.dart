import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/database/database_factory.dart';
import 'package:exercise_management/data/database/exercise_database_creation.dart';
import 'package:exercise_management/data/database/exercise_database_migrations.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exceptions.dart';
import 'package:exercise_management/data/repository/sqflite_exercise_set_presentation_repository.dart';
import 'package:exercise_management/data/repository/sqflite_exercise_sets_repository.dart';
import 'package:exercise_management/data/repository/sqflite_exercise_template_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';


void main() {
  late Database db;
  late SqfliteExerciseSetPresentationRepository presentationRepository;
  late SqfliteExerciseSetsRepository setsRepository;
  late SqfliteExerciseTemplateRepository templatesRepository;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await AppDatabaseFactory.createDatabase(inMemoryDatabasePath, createStatements, ExerciseDatabaseMigrations());
    templatesRepository = SqfliteExerciseTemplateRepository(db);
    setsRepository = SqfliteExerciseSetsRepository(db);
    presentationRepository = SqfliteExerciseSetPresentationRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('getExerciseSetPresentation should return correct data', () async {
    // Arrange
    final exerciseTemplateResult = await templatesRepository.addExercise(
      ExerciseTemplate(name: 'Bench Press', muscleGroup: MuscleGroup.chest, repetitionsRangeTarget: RepetitionsRange.medium)
    );

    final exerciseTemplate = (exerciseTemplateResult as Ok<ExerciseTemplate>).value;

    final exerciseSetResult = await setsRepository.addExercise(
      ExerciseSet(
        exerciseTemplateId: exerciseTemplate.id!,
        dateTime: DateTime.now(),
        equipmentWeight: 50,
        platesWeight: 20,
        repetitions: 10
      )
    );

    final exerciseSet = (exerciseSetResult as Ok<ExerciseSet>).value;

    // Act
    final result = await presentationRepository.getExerciseSet(exerciseSet.id!);
    final exercisePresentation = (result as Ok<ExerciseSetPresentation>).value;

    // Assert
    expect(result, isA<Ok<ExerciseSetPresentation>>());
    expect(exercisePresentation.setId, exerciseSet.id);
    expect(exercisePresentation.displayName, exerciseTemplate.name);
    expect(exercisePresentation.repetitions, exerciseSet.repetitions);
    expect(exercisePresentation.platesWeight, exerciseSet.platesWeight);
    expect(exercisePresentation.equipmentWeight, exerciseSet.equipmentWeight);
    expect(exercisePresentation.dateTime, exerciseSet.dateTime);
    expect(exercisePresentation.exerciseTemplateId, exerciseTemplate.id);
  });

  test('getExerciseSet with non-existing id should return error', () async {
    // Act
    final result = await presentationRepository.getExerciseSet('non-existing-id');

    // Assert
    expect(result, isA<Error>());
    expect((result as Error).error, isA<ExerciseNotFoundException>());
  });

  test('getExerciseSets should return all exercise sets', () async {
    // Arrange
    final exerciseTemplateResult = await templatesRepository.addExercise(
      ExerciseTemplate(name: 'Squat', muscleGroup: MuscleGroup.quadriceps, repetitionsRangeTarget: RepetitionsRange.high)
    );

    final exerciseTemplate = (exerciseTemplateResult as Ok<ExerciseTemplate>).value;

    await setsRepository.addExercise(
      ExerciseSet(
        exerciseTemplateId: exerciseTemplate.id!,
        dateTime: DateTime.now(),
        equipmentWeight: 60,
        platesWeight: 30,
        repetitions: 8
      )
    );

    await setsRepository.addExercise(
      ExerciseSet(
        exerciseTemplateId: exerciseTemplate.id!,
        dateTime: DateTime.now().add(Duration(days: 1)),
        equipmentWeight: 70,
        platesWeight: 40,
        repetitions: 6
      )
    );

    // Act
    final result = await presentationRepository.getExerciseSets();

    // Assert
    expect(result, isA<Ok<List<ExerciseSetPresentation>>>());
    expect((result as Ok<List<ExerciseSetPresentation>>).value.length, 2);
    for (var presentation in result.value) {
      expect(presentation.displayName, exerciseTemplate.name);
      expect(presentation.exerciseTemplateId, exerciseTemplate.id);
      expect(presentation.repetitionsRange, exerciseTemplate.repetitionsRangeTarget);
    }
  });

  test('getExerciseSets should return empty list if no sets exist', () async {
    // Act
    final result = await presentationRepository.getExerciseSets();

    // Assert
    expect(result, isA<Ok<List<ExerciseSetPresentation>>>());
    expect((result as Ok<List<ExerciseSetPresentation>>).value, isEmpty);
  });

  test('getExerciseSets should filter sets older than lastNDays', () async {
    // Arrange
    final exerciseTemplateResult = await templatesRepository.addExercise(
      ExerciseTemplate(name: 'Deadlift', muscleGroup: MuscleGroup.back, repetitionsRangeTarget: RepetitionsRange.low)
    );

    final exerciseTemplate = (exerciseTemplateResult as Ok<ExerciseTemplate>).value;

    // Add a set from 10 days ago (should be filtered out with default lastNDays=7)
    await setsRepository.addExercise(
      ExerciseSet(
        exerciseTemplateId: exerciseTemplate.id!,
        dateTime: DateTime.now().subtract(Duration(days: 10)),
        equipmentWeight: 100,
        platesWeight: 50,
        repetitions: 5
      )
    );

    // Add a set from 5 days ago (should be included with default lastNDays=7)
    await setsRepository.addExercise(
      ExerciseSet(
        exerciseTemplateId: exerciseTemplate.id!,
        dateTime: DateTime.now().subtract(Duration(days: 5)),
        equipmentWeight: 110,
        platesWeight: 55,
        repetitions: 5
      )
    );

    // Add a set from today (should be included with default lastNDays=7)
    await setsRepository.addExercise(
      ExerciseSet(
        exerciseTemplateId: exerciseTemplate.id!,
        dateTime: DateTime.now(),
        equipmentWeight: 120,
        platesWeight: 60,
        repetitions: 5
      )
    );

    // Act
    final result = await presentationRepository.getExerciseSets();

    // Assert
    expect(result, isA<Ok<List<ExerciseSetPresentation>>>());
    expect((result as Ok<List<ExerciseSetPresentation>>).value.length, 2);
  });

  test('getExerciseSets should respect custom lastNDays parameter', () async {
    // Arrange
    final exerciseTemplateResult = await templatesRepository.addExercise(
      ExerciseTemplate(name: 'Push-up', muscleGroup: MuscleGroup.chest, repetitionsRangeTarget: RepetitionsRange.high)
    );

    final exerciseTemplate = (exerciseTemplateResult as Ok<ExerciseTemplate>).value;

    // Add a set from 15 days ago
    await setsRepository.addExercise(
      ExerciseSet(
        exerciseTemplateId: exerciseTemplate.id!,
        dateTime: DateTime.now().subtract(Duration(days: 15)),
        equipmentWeight: 0,
        platesWeight: 0,
        repetitions: 20
      )
    );

    // Add a set from 12 days ago
    await setsRepository.addExercise(
      ExerciseSet(
        exerciseTemplateId: exerciseTemplate.id!,
        dateTime: DateTime.now().subtract(Duration(days: 12)),
        equipmentWeight: 0,
        platesWeight: 0,
        repetitions: 22
      )
    );

    // Add a set from 5 days ago
    await setsRepository.addExercise(
      ExerciseSet(
        exerciseTemplateId: exerciseTemplate.id!,
        dateTime: DateTime.now().subtract(Duration(days: 5)),
        equipmentWeight: 0,
        platesWeight: 0,
        repetitions: 25
      )
    );

    // Act - request last 14 days
    final result = await presentationRepository.getExerciseSets(lastNDays: 14);

    // Assert - should get 2 sets (12 days ago and 5 days ago)
    expect(result, isA<Ok<List<ExerciseSetPresentation>>>());
    expect((result as Ok<List<ExerciseSetPresentation>>).value.length, 2);
  });
}
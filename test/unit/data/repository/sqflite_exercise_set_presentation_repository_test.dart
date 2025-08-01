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
  });

  test('getExerciseSets should return empty list if no sets exist', () async {
    // Act
    final result = await presentationRepository.getExerciseSets();

    // Assert
    expect(result, isA<Ok<List<ExerciseSetPresentation>>>());
    expect((result as Ok<List<ExerciseSetPresentation>>).value, isEmpty);
  });
}
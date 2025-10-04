import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exceptions.dart';
import 'package:exercise_management/data/repository/in_memory_exercise_set_presentation_repository.dart';
import 'package:exercise_management/data/repository/in_memory_exercise_set_repository.dart';
import 'package:exercise_management/data/repository/in_memory_exercise_template_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryExerciseSetPresentationRepository
      inMemoryExerciseSetPresentationRepository;
  late InMemoryExerciseRepository inMemoryExerciseRepository;
  late InMemoryExerciseSetRepository inMemoryExerciseSetRepository;

  setUp(() {
    inMemoryExerciseRepository = InMemoryExerciseRepository();
    inMemoryExerciseSetRepository = InMemoryExerciseSetRepository();
    inMemoryExerciseSetPresentationRepository =
        InMemoryExerciseSetPresentationRepository(
            exerciseSetRepository: inMemoryExerciseSetRepository,
            exerciseTemplateRepository: inMemoryExerciseRepository);
  });

  test('getExerciseSets should return a list of exercise set presentations',
      () async {
    final now = DateTime.now();
    final exerciseSetModel = ExerciseSet(
      exerciseTemplateId: '1',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 45,
      repetitions: 10,
    );

    final exerciseTemplate = ExerciseTemplate(
        id: '1',
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium);

    await inMemoryExerciseRepository.addExercise(exerciseTemplate);
    await inMemoryExerciseSetRepository.addExercise(exerciseSetModel);

    final result =
        await inMemoryExerciseSetPresentationRepository.getExerciseSets();

    final exerciseSetPresentation =
        (result as Ok<List<ExerciseSetPresentation>>).value.first;

    expect(exerciseSetPresentation.exerciseTemplateId, '1');
    expect(exerciseSetPresentation.dateTime, now);
    expect(exerciseSetPresentation.equipmentWeight, 0);
    expect(exerciseSetPresentation.platesWeight, 45);
    expect(exerciseSetPresentation.repetitions, 10);
  });

  test('getExerciseSets should return multiple set presentations', () async {
    final now = DateTime.now();
    final next = now.add(const Duration(days: 1));
    final exerciseSetModel = ExerciseSet(
      id: '1',
      exerciseTemplateId: '1',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 45,
      repetitions: 10,
    );

    final exerciseTemplate = ExerciseTemplate(
        id: '1',
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium);

    await inMemoryExerciseRepository.addExercise(exerciseTemplate);
    await inMemoryExerciseSetRepository.addExercise(exerciseSetModel);

    final exerciseSetModel2 = ExerciseSet(
      id: '2',
      exerciseTemplateId: '1',
      dateTime: next,
      equipmentWeight: 0,
      platesWeight: 45,
      repetitions: 10,
    );

    final expectedPresentations = [
      ExerciseSetPresentation(
        setId: '1',
        exerciseTemplateId: '1',
        displayName: 'Bench Press',
        dateTime: now,
        equipmentWeight: 0,
        platesWeight: 45,
        repetitions: 10,
        repetitionsRange: RepetitionsRange.medium
      ),
      ExerciseSetPresentation(
        setId: '2',
        exerciseTemplateId: '1',
        displayName: 'Bench Press',
        dateTime: next,
        equipmentWeight: 0,
        platesWeight: 45,
        repetitions: 10,
        repetitionsRange: RepetitionsRange.medium
      ),
    ];

    await inMemoryExerciseSetRepository.addExercise(exerciseSetModel2);

    final result =
        await inMemoryExerciseSetPresentationRepository.getExerciseSets();

    final exerciseSetPresentation =
        (result as Ok<List<ExerciseSetPresentation>>).value;

    expect(exerciseSetPresentation.length, 2);
    expect(exerciseSetPresentation, unorderedEquals(expectedPresentations));
  });

  test('getExerciseSets should return empty list when no sets are present',
      () async {
    final result =
        await inMemoryExerciseSetPresentationRepository.getExerciseSets();

    final exerciseSetPresentation =
        (result as Ok<List<ExerciseSetPresentation>>).value;

    expect(exerciseSetPresentation.isEmpty, true);
  });

  test(
      'getExerciseSets should return multiple presentations from multiple templates',
      () async {
    final now = DateTime.now();
    final next = now.add(const Duration(days: 1));
    final exerciseSetModel = ExerciseSet(
      id: '1',
      exerciseTemplateId: '1',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 45,
      repetitions: 10,
    );

    final exerciseTemplate = ExerciseTemplate(
        id: '1',
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium);

    await inMemoryExerciseRepository.addExercise(exerciseTemplate);
    await inMemoryExerciseSetRepository.addExercise(exerciseSetModel);

    final exerciseSetModel2 = ExerciseSet(
      id: '2',
      exerciseTemplateId: '2',
      dateTime: next,
      equipmentWeight: 0,
      platesWeight: 45,
      repetitions: 10,
    );

    final exerciseTemplate2 = ExerciseTemplate(
        id: '2',
        name: 'Squat',
        muscleGroup: MuscleGroup.quadriceps,
        repetitionsRangeTarget: RepetitionsRange.medium);

    await inMemoryExerciseRepository.addExercise(exerciseTemplate2);
    await inMemoryExerciseSetRepository.addExercise(exerciseSetModel2);

    final expectedPresentations = [
      ExerciseSetPresentation(
        setId: '1',
        exerciseTemplateId: '1',
        displayName: 'Bench Press',
        dateTime: now,
        equipmentWeight: 0,
        platesWeight: 45,
        repetitions: 10,
        repetitionsRange: RepetitionsRange.medium
      ),
      ExerciseSetPresentation(
        setId: '2',
        exerciseTemplateId: '2',
        displayName: 'Squat',
        dateTime: next,
        equipmentWeight: 0,
        platesWeight: 45,
        repetitions: 10,
        repetitionsRange: RepetitionsRange.medium
      ),
    ];

    final result =
        await inMemoryExerciseSetPresentationRepository.getExerciseSets();

    final exerciseSetPresentation =
        (result as Ok<List<ExerciseSetPresentation>>).value;

    expect(exerciseSetPresentation.length, 2);
    expect(exerciseSetPresentation, unorderedEquals(expectedPresentations));
  });

  test('getExerciseSets should return partial list if template doesnt exist',
      () async {
    final now = DateTime.now();
    final next = now.add(const Duration(days: 1));
    final exerciseSetModel = ExerciseSet(
      id: '1',
      exerciseTemplateId: '1',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 45,
      repetitions: 10,
    );

    final exerciseTemplate = ExerciseTemplate(
        id: '1',
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium);

    await inMemoryExerciseRepository.addExercise(exerciseTemplate);
    await inMemoryExerciseSetRepository.addExercise(exerciseSetModel);

    final exerciseSetModel2 = ExerciseSet(
      id: '2',
      exerciseTemplateId: '2',
      dateTime: next,
      equipmentWeight: 0,
      platesWeight: 45,
      repetitions: 10,
    );

    final expectedPresentations = [
      ExerciseSetPresentation(
        setId: '1',
        exerciseTemplateId: '1',
        displayName: 'Bench Press',
        dateTime: now,
        equipmentWeight: 0,
        platesWeight: 45,
        repetitions: 10,
        repetitionsRange: RepetitionsRange.medium
      ),
    ];

    await inMemoryExerciseSetRepository.addExercise(exerciseSetModel2);

    final result =
        await inMemoryExerciseSetPresentationRepository.getExerciseSets();

    final exerciseSetPresentation =
        (result as Ok<List<ExerciseSetPresentation>>).value;

    expect(exerciseSetPresentation.length, 1);
    expect(exerciseSetPresentation, unorderedEquals(expectedPresentations));
  });

  test('getExerciseSet should return a single set presentation', () async {
    final now = DateTime.now();
    final exerciseSetModel = ExerciseSet(
      id: '1',
      exerciseTemplateId: '1',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 45,
      repetitions: 10,
    );

    final exerciseTemplate = ExerciseTemplate(
        id: '1',
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium);

    await inMemoryExerciseRepository.addExercise(exerciseTemplate);
    await inMemoryExerciseSetRepository.addExercise(exerciseSetModel);

    final result = await inMemoryExerciseSetPresentationRepository
        .getExerciseSet(exerciseSetModel.id!);

    final exerciseSetPresentation =
        (result as Ok<ExerciseSetPresentation>).value;

    expect(exerciseSetPresentation.exerciseTemplateId, '1');
    expect(exerciseSetPresentation.dateTime, now);
    expect(exerciseSetPresentation.equipmentWeight, 0);
    expect(exerciseSetPresentation.platesWeight, 45);
    expect(exerciseSetPresentation.repetitions, 10);
    expect(exerciseSetPresentation.displayName, 'Bench Press');
  });

  test('getExerciseSet should return an error if set doesnt exist', () async {
    final result =
        await inMemoryExerciseSetPresentationRepository.getExerciseSet('1');
    final error = (result as Error).error;

    expect(result, isA<Error>());
    expect(error, isA<ExerciseNotFoundException>());
  });

  test('getExerciseSets should filter sets older than lastNDays', () async {
    final now = DateTime.now();
    final old = now.subtract(const Duration(days: 10));
    final recent = now.subtract(const Duration(days: 5));
    
    final exerciseTemplate = ExerciseTemplate(
        id: '1',
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium);

    await inMemoryExerciseRepository.addExercise(exerciseTemplate);

    // Add set from 10 days ago
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(
      id: '1',
      exerciseTemplateId: '1',
      dateTime: old,
      equipmentWeight: 0,
      platesWeight: 45,
      repetitions: 10,
    ));

    // Add set from 5 days ago
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(
      id: '2',
      exerciseTemplateId: '1',
      dateTime: recent,
      equipmentWeight: 0,
      platesWeight: 50,
      repetitions: 10,
    ));

    // Add set from today
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(
      id: '3',
      exerciseTemplateId: '1',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 55,
      repetitions: 10,
    ));

    final result =
        await inMemoryExerciseSetPresentationRepository.getExerciseSets();

    final exerciseSetPresentation =
        (result as Ok<List<ExerciseSetPresentation>>).value;

    // Should only include sets from last 7 days (2 sets)
    expect(exerciseSetPresentation.length, 2);
    expect(exerciseSetPresentation.any((s) => s.setId == '1'), false);
    expect(exerciseSetPresentation.any((s) => s.setId == '2'), true);
    expect(exerciseSetPresentation.any((s) => s.setId == '3'), true);
  });

  test('getExerciseSets should respect custom lastNDays parameter', () async {
    final now = DateTime.now();
    final old = now.subtract(const Duration(days: 15));
    final midOld = now.subtract(const Duration(days: 12));
    final recent = now.subtract(const Duration(days: 5));
    
    final exerciseTemplate = ExerciseTemplate(
        id: '1',
        name: 'Squat',
        muscleGroup: MuscleGroup.quadriceps,
        repetitionsRangeTarget: RepetitionsRange.high);

    await inMemoryExerciseRepository.addExercise(exerciseTemplate);

    // Add set from 15 days ago
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(
      id: '1',
      exerciseTemplateId: '1',
      dateTime: old,
      equipmentWeight: 0,
      platesWeight: 100,
      repetitions: 12,
    ));

    // Add set from 12 days ago
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(
      id: '2',
      exerciseTemplateId: '1',
      dateTime: midOld,
      equipmentWeight: 0,
      platesWeight: 110,
      repetitions: 12,
    ));

    // Add set from 5 days ago
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(
      id: '3',
      exerciseTemplateId: '1',
      dateTime: recent,
      equipmentWeight: 0,
      platesWeight: 120,
      repetitions: 12,
    ));

    // Request last 14 days
    final result =
        await inMemoryExerciseSetPresentationRepository.getExerciseSets(lastNDays: 14);

    final exerciseSetPresentation =
        (result as Ok<List<ExerciseSetPresentation>>).value;

    // Should include 2 sets (from 12 days ago and 5 days ago)
    expect(exerciseSetPresentation.length, 2);
    expect(exerciseSetPresentation.any((s) => s.setId == '1'), false);
    expect(exerciseSetPresentation.any((s) => s.setId == '2'), true);
    expect(exerciseSetPresentation.any((s) => s.setId == '3'), true);
  });
}

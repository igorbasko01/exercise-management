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

  test('getExerciseSets should return sets from last N distinct logged days', () async {
    final now = DateTime.now();
    final old = now.subtract(const Duration(days: 100));
    final midOld = now.subtract(const Duration(days: 50));
    
    final exerciseTemplate = ExerciseTemplate(
        id: '1',
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium);

    await inMemoryExerciseRepository.addExercise(exerciseTemplate);

    // Add set from 100 days ago
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(
      id: '1',
      exerciseTemplateId: '1',
      dateTime: old,
      equipmentWeight: 0,
      platesWeight: 45,
      repetitions: 10,
    ));

    // Add set from 50 days ago
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(
      id: '2',
      exerciseTemplateId: '1',
      dateTime: midOld,
      equipmentWeight: 0,
      platesWeight: 50,
      repetitions: 10,
    ));

    // Add 2 sets from today (same day)
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(
      id: '3',
      exerciseTemplateId: '1',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 55,
      repetitions: 10,
    ));
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(
      id: '4',
      exerciseTemplateId: '1',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 60,
      repetitions: 10,
    ));

    // Request last 2 distinct days
    final result =
        await inMemoryExerciseSetPresentationRepository.getExerciseSets(lastNDays: 2);

    final exerciseSetPresentation =
        (result as Ok<List<ExerciseSetPresentation>>).value;

    // Should include 3 sets (1 from 50 days ago and 2 from today, excluding 100 days ago)
    expect(exerciseSetPresentation.length, 3);
    expect(exerciseSetPresentation.any((s) => s.setId == '1'), false);
    expect(exerciseSetPresentation.any((s) => s.setId == '2'), true);
    expect(exerciseSetPresentation.any((s) => s.setId == '3'), true);
    expect(exerciseSetPresentation.any((s) => s.setId == '4'), true);
  });

  test('getExerciseSets should respect custom lastNDays parameter for distinct days', () async {
    final now = DateTime.now();
    final old = now.subtract(const Duration(days: 60));
    final midOld1 = now.subtract(const Duration(days: 40));
    final midOld2 = now.subtract(const Duration(days: 20));
    
    final exerciseTemplate = ExerciseTemplate(
        id: '1',
        name: 'Squat',
        muscleGroup: MuscleGroup.quadriceps,
        repetitionsRangeTarget: RepetitionsRange.high);

    await inMemoryExerciseRepository.addExercise(exerciseTemplate);

    // Add set from 60 days ago
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(
      id: '1',
      exerciseTemplateId: '1',
      dateTime: old,
      equipmentWeight: 0,
      platesWeight: 100,
      repetitions: 12,
    ));

    // Add set from 40 days ago
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(
      id: '2',
      exerciseTemplateId: '1',
      dateTime: midOld1,
      equipmentWeight: 0,
      platesWeight: 110,
      repetitions: 12,
    ));

    // Add set from 20 days ago
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(
      id: '3',
      exerciseTemplateId: '1',
      dateTime: midOld2,
      equipmentWeight: 0,
      platesWeight: 120,
      repetitions: 12,
    ));

    // Add set from today
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(
      id: '4',
      exerciseTemplateId: '1',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 130,
      repetitions: 12,
    ));

    // Request last 3 distinct days
    final result =
        await inMemoryExerciseSetPresentationRepository.getExerciseSets(lastNDays: 3);

    final exerciseSetPresentation =
        (result as Ok<List<ExerciseSetPresentation>>).value;

    // Should include 3 sets (from 40, 20 days ago and today, excluding 60 days ago)
    expect(exerciseSetPresentation.length, 3);
    expect(exerciseSetPresentation.any((s) => s.setId == '1'), false);
    expect(exerciseSetPresentation.any((s) => s.setId == '2'), true);
    expect(exerciseSetPresentation.any((s) => s.setId == '3'), true);
    expect(exerciseSetPresentation.any((s) => s.setId == '4'), true);
  });

  test('getExerciseSets should filter by exercise template ID', () async {
    final now = DateTime.now();
    
    final exerciseTemplate1 = ExerciseTemplate(
        id: '1',
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium);

    final exerciseTemplate2 = ExerciseTemplate(
        id: '2',
        name: 'Squat',
        muscleGroup: MuscleGroup.quadriceps,
        repetitionsRangeTarget: RepetitionsRange.medium);

    await inMemoryExerciseRepository.addExercise(exerciseTemplate1);
    await inMemoryExerciseRepository.addExercise(exerciseTemplate2);

    // Add sets for exercise template 1
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(
      id: '1',
      exerciseTemplateId: '1',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 45,
      repetitions: 10,
    ));
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(
      id: '2',
      exerciseTemplateId: '1',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 50,
      repetitions: 10,
    ));

    // Add sets for exercise template 2
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(
      id: '3',
      exerciseTemplateId: '2',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 100,
      repetitions: 12,
    ));

    // Filter by exercise template 1
    final result = await inMemoryExerciseSetPresentationRepository
        .getExerciseSets(exerciseTemplateId: '1');

    final exerciseSetPresentation =
        (result as Ok<List<ExerciseSetPresentation>>).value;

    // Should only include sets from template 1
    expect(exerciseSetPresentation.length, 2);
    expect(exerciseSetPresentation.every((s) => s.exerciseTemplateId == '1'), true);
    expect(exerciseSetPresentation.any((s) => s.setId == '1'), true);
    expect(exerciseSetPresentation.any((s) => s.setId == '2'), true);
    expect(exerciseSetPresentation.any((s) => s.setId == '3'), false);
  });

  test('getExerciseSets should return empty list when filtering by non-existent template ID', () async {
    final now = DateTime.now();
    
    final exerciseTemplate = ExerciseTemplate(
        id: '1',
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium);

    await inMemoryExerciseRepository.addExercise(exerciseTemplate);

    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(
      id: '1',
      exerciseTemplateId: '1',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 45,
      repetitions: 10,
    ));

    // Filter by non-existent template ID
    final result = await inMemoryExerciseSetPresentationRepository
        .getExerciseSets(exerciseTemplateId: 'nonexistent');

    final exerciseSetPresentation =
        (result as Ok<List<ExerciseSetPresentation>>).value;
    
    expect(exerciseSetPresentation.isEmpty, true);
  });

  test('getMostRecentCompletionDate should return correct date', () async {
    final t1 = ExerciseTemplate(id: 't1', name: 'T1', muscleGroup: MuscleGroup.chest, repetitionsRangeTarget: RepetitionsRange.medium);
    final t2 = ExerciseTemplate(id: 't2', name: 'T2', muscleGroup: MuscleGroup.chest, repetitionsRangeTarget: RepetitionsRange.medium);
    await inMemoryExerciseRepository.addExercise(t1);
    await inMemoryExerciseRepository.addExercise(t2);

    final date1 = DateTime(2023, 1, 1);
    final date2 = DateTime(2023, 1, 2);

    // On date1, only t1 was done
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(id: 's1', exerciseTemplateId: t1.id!, dateTime: date1, equipmentWeight: 0, platesWeight: 0, repetitions: 0));
    
    // On date2, both t1 and t2 were done
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(id: 's2', exerciseTemplateId: t1.id!, dateTime: date2, equipmentWeight: 0, platesWeight: 0, repetitions: 0));
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(id: 's3', exerciseTemplateId: t2.id!, dateTime: date2, equipmentWeight: 0, platesWeight: 0, repetitions: 0));

    final result = await inMemoryExerciseSetPresentationRepository.getMostRecentCompletionDate([t1.id!, t2.id!]);
    expect(result, isA<Ok<Map<String, DateTime>>>());
    final d = (result as Ok<Map<String, DateTime>>).value;
    expect(d[t1.id!]?.day, 2);
    expect(d[t2.id!]?.day, 2);
  });

  test('getMostRecentCompletionDate should return separate dates for different completion dates', () async {
    final t1 = ExerciseTemplate(id: 't1', name: 'T1', muscleGroup: MuscleGroup.chest, repetitionsRangeTarget: RepetitionsRange.medium);
    final t2 = ExerciseTemplate(id: 't2', name: 'T2', muscleGroup: MuscleGroup.chest, repetitionsRangeTarget: RepetitionsRange.medium);
    await inMemoryExerciseRepository.addExercise(t1);
    await inMemoryExerciseRepository.addExercise(t2);

    final date1 = DateTime(2023, 1, 1);
    final date2 = DateTime(2023, 1, 2);

    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(id: 's1', exerciseTemplateId: t1.id!, dateTime: date1, equipmentWeight: 0, platesWeight: 0, repetitions: 0));
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(id: 's2', exerciseTemplateId: t2.id!, dateTime: date2, equipmentWeight: 0, platesWeight: 0, repetitions: 0));

    final result = await inMemoryExerciseSetPresentationRepository.getMostRecentCompletionDate([t1.id!, t2.id!]);
    expect(result, isA<Ok<Map<String, DateTime>>>());
    final d = (result as Ok<Map<String, DateTime>>).value;
    expect(d[t1.id!]?.day, 1);
    expect(d[t2.id!]?.day, 2);
  });

  test('getExerciseSetsByDateAndTemplates should return correct sets', () async {
    final t1 = ExerciseTemplate(id: 't1', name: 'T1', muscleGroup: MuscleGroup.chest, repetitionsRangeTarget: RepetitionsRange.medium);
    final t2 = ExerciseTemplate(id: 't2', name: 'T2', muscleGroup: MuscleGroup.chest, repetitionsRangeTarget: RepetitionsRange.medium);
    await inMemoryExerciseRepository.addExercise(t1);
    await inMemoryExerciseRepository.addExercise(t2);

    final targetDate = DateTime(2023, 1, 1);
    final otherDate = DateTime(2023, 1, 2);

    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(id: 's1', exerciseTemplateId: t1.id!, dateTime: targetDate, equipmentWeight: 10, platesWeight: 0, repetitions: 5));
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(id: 's2', exerciseTemplateId: t2.id!, dateTime: targetDate, equipmentWeight: 20, platesWeight: 0, repetitions: 5));
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(id: 's3', exerciseTemplateId: t1.id!, dateTime: otherDate, equipmentWeight: 30, platesWeight: 0, repetitions: 5));

    final result = await inMemoryExerciseSetPresentationRepository.getExerciseSetsByDateAndTemplates({
      t1.id!: targetDate,
      t2.id!: targetDate,
    });
    expect(result, isA<Ok<List<ExerciseSetPresentation>>>());
    final sets = (result as Ok<List<ExerciseSetPresentation>>).value;
    
    expect(sets.length, 2);
    expect(sets.any((s) => s.exerciseTemplateId == t1.id! && s.equipmentWeight == 10), isTrue);
    expect(sets.any((s) => s.exerciseTemplateId == t2.id! && s.equipmentWeight == 20), isTrue);
  });

  test('getStrictMostRecentRoutineCompletionDate should return date when all templates exist on same date', () async {
    final t1 = ExerciseTemplate(id: 't1', name: 'T1', muscleGroup: MuscleGroup.chest, repetitionsRangeTarget: RepetitionsRange.medium);
    final t2 = ExerciseTemplate(id: 't2', name: 'T2', muscleGroup: MuscleGroup.chest, repetitionsRangeTarget: RepetitionsRange.medium);
    await inMemoryExerciseRepository.addExercise(t1);
    await inMemoryExerciseRepository.addExercise(t2);

    final date1 = DateTime(2023, 1, 1);
    final date2 = DateTime(2023, 1, 2);

    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(id: 's1', exerciseTemplateId: t1.id!, dateTime: date1, equipmentWeight: 0, platesWeight: 0, repetitions: 0));
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(id: 's2', exerciseTemplateId: t1.id!, dateTime: date2, equipmentWeight: 0, platesWeight: 0, repetitions: 0));
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(id: 's3', exerciseTemplateId: t2.id!, dateTime: date2, equipmentWeight: 0, platesWeight: 0, repetitions: 0));

    final result = await inMemoryExerciseSetPresentationRepository.getStrictMostRecentRoutineCompletionDate([t1.id!, t2.id!]);
    expect(result, isA<Ok<DateTime?>>());
    final d = (result as Ok<DateTime?>).value;
    expect(d, isNotNull);
    expect(d!.day, 2);
  });

  test('getStrictMostRecentRoutineCompletionDate should return null when templates not done on same date', () async {
    final t1 = ExerciseTemplate(id: 't1', name: 'T1', muscleGroup: MuscleGroup.chest, repetitionsRangeTarget: RepetitionsRange.medium);
    final t2 = ExerciseTemplate(id: 't2', name: 'T2', muscleGroup: MuscleGroup.chest, repetitionsRangeTarget: RepetitionsRange.medium);
    await inMemoryExerciseRepository.addExercise(t1);
    await inMemoryExerciseRepository.addExercise(t2);

    final date1 = DateTime(2023, 1, 1);
    final date2 = DateTime(2023, 1, 2);

    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(id: 's1', exerciseTemplateId: t1.id!, dateTime: date1, equipmentWeight: 0, platesWeight: 0, repetitions: 0));
    await inMemoryExerciseSetRepository.addExercise(ExerciseSet(id: 's2', exerciseTemplateId: t2.id!, dateTime: date2, equipmentWeight: 0, platesWeight: 0, repetitions: 0));

    final result = await inMemoryExerciseSetPresentationRepository.getStrictMostRecentRoutineCompletionDate([t1.id!, t2.id!]);
    expect(result, isA<Ok<DateTime?>>());
    final d = (result as Ok<DateTime?>).value;
    expect(d, isNull);
  });
}

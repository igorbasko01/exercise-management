import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/in_memory_exercise_set_repository.dart';
import 'package:exercise_management/data/repository/in_memory_exercise_template_repository.dart';
import 'package:exercise_management/presentation/models/exercise_set_presentation.dart';
import 'package:exercise_management/presentation/view_models/exercise_sets_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryExerciseRepository exerciseTemplateRepository;
  late InMemoryExerciseSetRepository exerciseSetRepository;
  late ExerciseSetsViewModel viewModel;

  setUp(() {
    exerciseTemplateRepository = InMemoryExerciseRepository();
    exerciseSetRepository = InMemoryExerciseSetRepository();
    viewModel = ExerciseSetsViewModel(
        exerciseSetRepository: exerciseSetRepository,
        exerciseTemplateRepository: exerciseTemplateRepository);
  });

  test('fetchExerciseSets returns a list of ExerciseSetPresentation on success',
      () async {
    final exerciseTemplate = ExerciseTemplate(
      id: '1',
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.medium,
    );

    final now = DateTime.now();

    final exerciseSet = ExerciseSet(
      id: '1',
      exerciseTemplateId: '1',
      repetitions: 10,
      platesWeight: 20,
      equipmentWeight: 0,
      dateTime: now,
    );
    exerciseTemplateRepository.addExercise(exerciseTemplate);
    exerciseSetRepository.addExercise(exerciseSet);

    final expectedValue = [
      ExerciseSetPresentation(
        setId: '1',
        displayName: 'Bench Press',
        repetitions: 10,
        platesWeight: 20,
        equipmentWeight: 0,
        dateTime: now,
        exerciseTemplateId: '1',
      )
    ];

    await viewModel.fetchExerciseSets.execute();
    final result = viewModel.fetchExerciseSets.result;

    final value = (result as Ok<List<ExerciseSetPresentation>>).value;

    expect(result, isA<Ok<List<ExerciseSetPresentation>>>());
    expect(value.length, 1);
    expect(value, equals(expectedValue));
  });

  test('fetchExerciseSets returns an empty list if no sets are available',
      () async {
    await viewModel.fetchExerciseSets.execute();
    final result = viewModel.fetchExerciseSets.result;

    final value = (result as Ok<List<ExerciseSetPresentation>>).value;

    expect(result, isA<Ok<List<ExerciseSetPresentation>>>());
    expect(value.length, 0);
  });

  test('fetchExerciseSets returns all valid sets if some are invalid',
      () async {
    final exerciseTemplate = ExerciseTemplate(
        id: '1',
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium);

    final now = DateTime.now();

    final exerciseSet = ExerciseSet(
      id: '1',
      exerciseTemplateId: '1',
      repetitions: 10,
      platesWeight: 20,
      equipmentWeight: 0,
      dateTime: now,
    );

    final invalidExerciseSet = ExerciseSet(
      id: '2',
      exerciseTemplateId: '2',
      repetitions: 10,
      platesWeight: 20,
      equipmentWeight: 0,
      dateTime: now,
    );

    exerciseTemplateRepository.addExercise(exerciseTemplate);
    exerciseSetRepository.addExercise(exerciseSet);
    exerciseSetRepository.addExercise(invalidExerciseSet);

    final expectedValue = [
      ExerciseSetPresentation(
        setId: '1',
        displayName: 'Bench Press',
        repetitions: 10,
        platesWeight: 20,
        equipmentWeight: 0,
        dateTime: now,
        exerciseTemplateId: '1',
      )
    ];

    await viewModel.fetchExerciseSets.execute();
    final result = viewModel.fetchExerciseSets.result;

    final value = (result as Ok<List<ExerciseSetPresentation>>).value;

    expect(result, isA<Ok<List<ExerciseSetPresentation>>>());
    expect(value.length, 1);
    expect(value, equals(expectedValue));
  });

  test('fetchExerciseSets returns empty list if all sets are invalid',
      () async {
    final now = DateTime.now();

    final invalidExerciseSet = ExerciseSet(
      id: '2',
      exerciseTemplateId: '2',
      repetitions: 10,
      platesWeight: 20,
      equipmentWeight: 0,
      dateTime: now,
    );

    exerciseSetRepository.addExercise(invalidExerciseSet);

    await viewModel.fetchExerciseSets.execute();
    final result = viewModel.fetchExerciseSets.result;

    final value = (result as Ok<List<ExerciseSetPresentation>>).value;

    expect(result, isA<Ok<List<ExerciseSetPresentation>>>());
    expect(value.length, 0);
  });

  test('addExerciseSet adds exercise set to the repository', () async {
    final exerciseTemplate = ExerciseTemplate(
        id: '1',
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium);

    final now = DateTime.now();

    final exerciseSet = ExerciseSet(
      id: '1',
      exerciseTemplateId: '1',
      repetitions: 10,
      platesWeight: 20,
      equipmentWeight: 0,
      dateTime: now,
    );

    exerciseTemplateRepository.addExercise(exerciseTemplate);

    await viewModel.addExerciseSet.execute(exerciseSet);
    final result = viewModel.addExerciseSet.result;

    final value = (result as Ok<ExerciseSet>).value;

    final exerciseSetsResult = await exerciseSetRepository.getExercises();
    final exerciseSets = (exerciseSetsResult as Ok<List<ExerciseSet>>).value;

    expect(result, isA<Ok<ExerciseSet>>());
    expect(value, equals(exerciseSet));
    expect(exerciseSets.length, 1);
  });

  test('deleteExerciseSet deletes exercise set from the repository', () async {
    final exerciseTemplate = ExerciseTemplate(
        id: '1',
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium);

    final now = DateTime.now();

    final exerciseSet = ExerciseSet(
      id: '1',
      exerciseTemplateId: '1',
      repetitions: 10,
      platesWeight: 20,
      equipmentWeight: 0,
      dateTime: now,
    );

    exerciseTemplateRepository.addExercise(exerciseTemplate);
    exerciseSetRepository.addExercise(exerciseSet);

    await viewModel.deleteExerciseSet.execute('1');
    final result = viewModel.deleteExerciseSet.result;

    final value = (result as Ok<ExerciseSet>).value;

    final exerciseSetsResult = await exerciseSetRepository.getExercises();
    final exerciseSets = (exerciseSetsResult as Ok<List<ExerciseSet>>).value;

    expect(result, isA<Ok<ExerciseSet>>());
    expect(value, equals(exerciseSet));
    expect(exerciseSets.length, 0);
  });

  test('updateExerciseSet updates exercise set in the repository', () async {
    final exerciseTemplate = ExerciseTemplate(
        id: '1',
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium);

    final now = DateTime.now();

    final exerciseSet = ExerciseSet(
      id: '1',
      exerciseTemplateId: '1',
      repetitions: 10,
      platesWeight: 20,
      equipmentWeight: 0,
      dateTime: now,
    );

    final updatedExerciseSet = ExerciseSet(
      id: '1',
      exerciseTemplateId: '1',
      repetitions: 15,
      platesWeight: 25,
      equipmentWeight: 5,
      dateTime: now,
    );

    exerciseTemplateRepository.addExercise(exerciseTemplate);
    exerciseSetRepository.addExercise(exerciseSet);

    await viewModel.updateExerciseSet.execute(updatedExerciseSet);
    final result = viewModel.updateExerciseSet.result;

    final value = (result as Ok<ExerciseSet>).value;

    final exerciseSetsResult = await exerciseSetRepository.getExercises();
    final exerciseSets = (exerciseSetsResult as Ok<List<ExerciseSet>>).value;

    expect(result, isA<Ok<ExerciseSet>>());
    expect(value, equals(updatedExerciseSet));
    expect(exerciseSets.length, 1);
    expect(exerciseSets[0], equals(updatedExerciseSet));
  });
}

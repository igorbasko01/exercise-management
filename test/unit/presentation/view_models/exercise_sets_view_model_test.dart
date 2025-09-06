import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exercise_set_presentation_repository.dart';
import 'package:exercise_management/data/repository/exercise_set_repository.dart';
import 'package:exercise_management/data/repository/exercise_template_repository.dart';
import 'package:exercise_management/data/repository/in_memory_exercise_set_presentation_repository.dart';
import 'package:exercise_management/data/repository/in_memory_exercise_set_repository.dart';
import 'package:exercise_management/data/repository/in_memory_exercise_template_repository.dart';
import 'package:exercise_management/presentation/view_models/exercise_sets_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExerciseSetRepository extends Mock implements ExerciseSetRepository {}

class MockExerciseTemplateRepository extends Mock
    implements ExerciseTemplateRepository {}

class MockExerciseSetPresentationRepository extends Mock
    implements ExerciseSetPresentationRepository {}

void main() {
  group('ExerciseSetsViewModel Progressive Sets', () {
    late MockExerciseSetRepository mockExerciseSetRepository;
    late MockExerciseTemplateRepository mockExerciseTemplateRepository;
    late MockExerciseSetPresentationRepository
        mockExerciseSetPresentationRepository;
    late ExerciseSetsViewModel viewModel;

    final chestTemplate = ExerciseTemplate(
      id: '1',
      name: 'Bench Press',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.medium,
    );

    final chestSet1 = ExerciseSet(
      id: '1',
      exerciseTemplateId: '1',
      repetitions: 7,
      platesWeight: 20,
      equipmentWeight: 0,
      dateTime: DateTime.now(),
    );

    final chestSet2 = ExerciseSet(
      id: '2',
      exerciseTemplateId: '1',
      repetitions: 7,
      platesWeight: 20,
      equipmentWeight: 0,
      dateTime: DateTime.now(),
    );

    final chestSet3 = ExerciseSet(
      id: '3',
      exerciseTemplateId: '1',
      repetitions: 7,
      platesWeight: 20,
      equipmentWeight: 0,
      dateTime: DateTime.now(),
    );

    setUpAll(() {
      // Register fallback values for the mock methods so we don't get errors when using any()
      registerFallbackValue(ExerciseSet(
        id: 'fallback',
        exerciseTemplateId: 'fallback',
        repetitions: 0,
        platesWeight: 0,
        equipmentWeight: 0,
        dateTime: DateTime.now(),
      ));
    });

    setUp(() {
      mockExerciseSetRepository = MockExerciseSetRepository();
      mockExerciseTemplateRepository = MockExerciseTemplateRepository();
      mockExerciseSetPresentationRepository =
          MockExerciseSetPresentationRepository();
      viewModel = ExerciseSetsViewModel(
          exerciseSetRepository: mockExerciseSetRepository,
          exerciseSetPresentationRepository:
              mockExerciseSetPresentationRepository,
          exerciseTemplateRepository: mockExerciseTemplateRepository);

      when(() => mockExerciseSetRepository.addExercises(any()))
          .thenAnswer((invocation) async {
        return Result.ok(null);
      });

      when(() => mockExerciseTemplateRepository.getExercise(chestTemplate.id!))
          .thenAnswer((invocation) async {
        return Result.ok(chestTemplate);
      });
    });

    test('returns cloned set if provided only single set', () async {
      await viewModel.progressSets.execute([chestSet1]);

      final chestSet1New = chestSet1.copyWithoutId();

      verify(() => mockExerciseSetRepository.addExercises([chestSet1New]))
          .called(1);
    });

    test('returns cloned sets if provided 2 sets of same exercise', () async {
      await viewModel.progressSets.execute([chestSet1, chestSet2]);

      final chestSet2New = chestSet2.copyWithoutId();
      final chestSet1New = chestSet1.copyWithoutId();

      verify(() => mockExerciseSetRepository
          .addExercises([chestSet1New, chestSet2New])).called(1);
    });

    test(
        'returns progressed repetition sets when provided 3 sets of same exercise',
        () async {
      await viewModel.progressSets.execute([chestSet1, chestSet2, chestSet3]);

      final chestSet3New = chestSet3.copyWithoutId(repetitions: 8);
      final chestSet2New = chestSet2.copyWithoutId(repetitions: 8);
      final chestSet1New = chestSet1.copyWithoutId(repetitions: 8);

      verify(() => mockExerciseSetRepository
          .addExercises([chestSet1New, chestSet2New, chestSet3New])).called(1);
    });

    test(
        'returns regressed repetition sets when provided 3 sets of different repetitions',
        () async {
      final chestSet3DifferentReps = chestSet3.copyWith(repetitions: 4);
      await viewModel.progressSets
          .execute([chestSet1, chestSet2, chestSet3DifferentReps]);

      final chestSet3New = chestSet3DifferentReps.copyWithoutId(repetitions: 6);
      final chestSet2New = chestSet2.copyWithoutId(repetitions: 6);
      final chestSet1New = chestSet1.copyWithoutId(repetitions: 6);

      verify(() => mockExerciseSetRepository
          .addExercises([chestSet1New, chestSet2New, chestSet3New])).called(1);
    });

    test(
        'returns progressed sets when provided 4 sets but at least 3 of same highest repetitions',
        () async {
      final chestSet4 = chestSet3.copyWith(id: '4', repetitions: 6);
      await viewModel.progressSets
          .execute([chestSet1, chestSet2, chestSet3, chestSet4]);

      final chestSet4New = chestSet4.copyWithoutId(repetitions: 8);
      final chestSet3New = chestSet3.copyWithoutId(repetitions: 8);
      final chestSet2New = chestSet2.copyWithoutId(repetitions: 8);
      final chestSet1New = chestSet1.copyWithoutId(repetitions: 8);

      verify(() => mockExerciseSetRepository.addExercises(
          [chestSet1New, chestSet2New, chestSet3New, chestSet4New])).called(1);
    });

    test(
        'returns regressed sets when provided 4 sets but no 3 of same highest repetitions',
        () async {
      final chestSet4 = chestSet3.copyWith(id: '4', repetitions: 8);
      await viewModel.progressSets
          .execute([chestSet1, chestSet2, chestSet3, chestSet4]);

      final chestSet4New = chestSet4.copyWithoutId(repetitions: 7);
      final chestSet3New = chestSet3.copyWithoutId(repetitions: 7);
      final chestSet2New = chestSet2.copyWithoutId(repetitions: 7);
      final chestSet1New = chestSet1.copyWithoutId(repetitions: 7);

      verify(() => mockExerciseSetRepository.addExercises(
          [chestSet1New, chestSet2New, chestSet3New, chestSet4New])).called(1);
    });

    test(
        'returns progressed sets with higher plates weight (10%) when provided 3 sets of highest repetitions for exercise',
        () async {
      final chestSet1max =
          chestSet1.copyWith(repetitions: 10, platesWeight: 25);
      final chestSet2max =
          chestSet2.copyWith(repetitions: 10, platesWeight: 25);
      final chestSet3max =
          chestSet3.copyWith(repetitions: 10, platesWeight: 25);
      final chestSet4 =
          chestSet3.copyWith(id: '4', repetitions: 4, platesWeight: 25);
      await viewModel.progressSets
          .execute([chestSet1max, chestSet2max, chestSet3max, chestSet4]);

      final chestSet4New =
          chestSet4.copyWithoutId(repetitions: 6, platesWeight: 27.5);
      final chestSet3New =
          chestSet3.copyWithoutId(repetitions: 6, platesWeight: 27.5);
      final chestSet2New =
          chestSet2.copyWithoutId(repetitions: 6, platesWeight: 27.5);
      final chestSet1New =
          chestSet1.copyWithoutId(repetitions: 6, platesWeight: 27.5);

      verify(() => mockExerciseSetRepository.addExercises(
          [chestSet1New, chestSet2New, chestSet3New, chestSet4New])).called(1);
    });

    test(
        'returns regressed sets with lower plates weight (10%) when provided with 3 of different reps with highest rep is lowest possible for target range',
        () async {
          final chestSet1max =
          chestSet1.copyWith(repetitions: 6, platesWeight: 25);
          final chestSet2max =
          chestSet2.copyWith(repetitions: 5, platesWeight: 25);
          final chestSet3max =
          chestSet3.copyWith(repetitions: 5, platesWeight: 25);
          final chestSet4 =
          chestSet3.copyWith(id: '4', repetitions: 4, platesWeight: 25);
          await viewModel.progressSets
              .execute([chestSet1max, chestSet2max, chestSet3max, chestSet4]);

          final chestSet4New =
          chestSet4.copyWithoutId(repetitions: 10, platesWeight: 22.5);
          final chestSet3New =
          chestSet3.copyWithoutId(repetitions: 10, platesWeight: 22.5);
          final chestSet2New =
          chestSet2.copyWithoutId(repetitions: 10, platesWeight: 22.5);
          final chestSet1New =
          chestSet1.copyWithoutId(repetitions: 10, platesWeight: 22.5);

          verify(() => mockExerciseSetRepository.addExercises(
              [chestSet1New, chestSet2New, chestSet3New, chestSet4New])).called(1);
        });
  });

  group('ExerciseSetsViewModel CRUD Operations', () {
    late InMemoryExerciseRepository exerciseTemplateRepository;
    late InMemoryExerciseSetRepository exerciseSetRepository;
    late InMemoryExerciseSetPresentationRepository
        exerciseSetPresentationRepository;
    late ExerciseSetsViewModel viewModel;

    setUp(() {
      exerciseTemplateRepository = InMemoryExerciseRepository();
      exerciseSetRepository = InMemoryExerciseSetRepository();
      exerciseSetPresentationRepository =
          InMemoryExerciseSetPresentationRepository(
              exerciseSetRepository: exerciseSetRepository,
              exerciseTemplateRepository: exerciseTemplateRepository);
      viewModel = ExerciseSetsViewModel(
          exerciseSetRepository: exerciseSetRepository,
          exerciseSetPresentationRepository: exerciseSetPresentationRepository,
          exerciseTemplateRepository: exerciseTemplateRepository);
    });

    test(
        'fetchExerciseSets returns a list of ExerciseSetPresentation on success',
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
          repetitionsRange: RepetitionsRange.medium,
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
          repetitionsRange: RepetitionsRange.medium,
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

    test('deleteExerciseSet deletes exercise set from the repository',
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
  });
}

import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exercise_set_presentation_repository.dart';
import 'package:exercise_management/data/repository/exercise_set_repository.dart';
import 'package:exercise_management/data/repository/exercise_template_repository.dart';
import 'package:exercise_management/presentation/pages/exercise_sets_page.dart';
import 'package:exercise_management/presentation/view_models/exercise_sets_view_model.dart';
import 'package:exercise_management/presentation/view_models/training_session_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockExerciseSetRepository extends Mock implements ExerciseSetRepository {}

class MockExerciseTemplateRepository extends Mock
    implements ExerciseTemplateRepository {}

class MockExerciseSetPresentationRepository extends Mock
    implements ExerciseSetPresentationRepository {}

void main() {
  group('ExerciseSetsPage Ranking', () {
    late MockExerciseSetRepository mockExerciseSetRepository;
    late MockExerciseTemplateRepository mockExerciseTemplateRepository;
    late MockExerciseSetPresentationRepository
        mockExerciseSetPresentationRepository;
    late ExerciseSetsViewModel viewModel;
    late TrainingSessionManager trainingSessionManager;

    final date1 = DateTime(2023, 1, 1);
    final date2 = DateTime(2023, 1, 2);

    setUpAll(() {
      // Register fallback values
      registerFallbackValue(<ExerciseSet>[]);
      registerFallbackValue(ExerciseSet(
        id: 'fallback',
        exerciseTemplateId: 'fallback',
        repetitions: 0,
        platesWeight: 0,
        equipmentWeight: 0,
        dateTime: DateTime(2023, 1, 1),
      ));
    });

    setUp(() {
      mockExerciseSetRepository = MockExerciseSetRepository();
      mockExerciseTemplateRepository = MockExerciseTemplateRepository();
      mockExerciseSetPresentationRepository =
          MockExerciseSetPresentationRepository();
      trainingSessionManager = TrainingSessionManager();

      viewModel = ExerciseSetsViewModel(
          exerciseSetRepository: mockExerciseSetRepository,
          exerciseSetPresentationRepository:
              mockExerciseSetPresentationRepository,
          exerciseTemplateRepository: mockExerciseTemplateRepository);

      when(() => mockExerciseSetRepository.addExercises(any()))
          .thenAnswer((invocation) async {
        return Result.ok(null);
      });
      when(() => mockExerciseTemplateRepository.getExercises())
          .thenAnswer((invocation) async {
        return Result.ok([]);
      });
    });

    testWidgets('displays rank based on total volume', (WidgetTester tester) async {
      // Create test data with different total volumes
      // Date 1, Template 1: 3 sets * (20 + 20) * 10 = 1200 total volume
      final date1Template1Sets = [
        ExerciseSetPresentation(
          setId: '1',
          exerciseTemplateId: 'template1',
          repetitions: 10,
          platesWeight: 20,
          equipmentWeight: 20,
          dateTime: date1,
          displayName: 'Bench Press',
          repetitionsRange: RepetitionsRange.medium,
        ),
        ExerciseSetPresentation(
          setId: '2',
          exerciseTemplateId: 'template1',
          repetitions: 10,
          platesWeight: 20,
          equipmentWeight: 20,
          dateTime: date1,
          displayName: 'Bench Press',
          repetitionsRange: RepetitionsRange.medium,
        ),
        ExerciseSetPresentation(
          setId: '3',
          exerciseTemplateId: 'template1',
          repetitions: 10,
          platesWeight: 20,
          equipmentWeight: 20,
          dateTime: date1,
          displayName: 'Bench Press',
          repetitionsRange: RepetitionsRange.medium,
        ),
      ];

      // Date 2, Template 2: 2 sets * (15 + 15) * 8 = 480 total volume
      final date2Template2Sets = [
        ExerciseSetPresentation(
          setId: '4',
          exerciseTemplateId: 'template2',
          repetitions: 8,
          platesWeight: 15,
          equipmentWeight: 15,
          dateTime: date2,
          displayName: 'Squat',
          repetitionsRange: RepetitionsRange.medium,
        ),
        ExerciseSetPresentation(
          setId: '5',
          exerciseTemplateId: 'template2',
          repetitions: 8,
          platesWeight: 15,
          equipmentWeight: 15,
          dateTime: date2,
          displayName: 'Squat',
          repetitionsRange: RepetitionsRange.medium,
        ),
      ];

      final allSets = [...date1Template1Sets, ...date2Template2Sets];

      when(() => mockExerciseSetPresentationRepository.getExerciseSets(
              lastNDays: any(named: 'lastNDays'),
              exerciseTemplateId: any(named: 'exerciseTemplateId')))
          .thenAnswer((invocation) async {
        return Result.ok(allSets);
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ExerciseSetsViewModel>.value(
              value: viewModel,
            ),
            ChangeNotifierProvider<TrainingSessionManager>.value(
              value: trainingSessionManager,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ExerciseSetsPage(),
            ),
          ),
        ),
      );

      // Trigger the fetch
      await viewModel.fetchExerciseSets.execute();
      await tester.pumpAndSettle();

      // Verify that ranks are displayed correctly
      // Bench Press should be Rank #1 (higher volume)
      expect(find.textContaining('Rank: #1'), findsOneWidget);
      // Squat should be Rank #2 (lower volume)
      expect(find.textContaining('Rank: #2'), findsOneWidget);
    });

    testWidgets('ranks update when sets are added', (WidgetTester tester) async {
      // Initial data
      final initialSets = [
        ExerciseSetPresentation(
          setId: '1',
          exerciseTemplateId: 'template1',
          repetitions: 5,
          platesWeight: 10,
          equipmentWeight: 10,
          dateTime: date1,
          displayName: 'Exercise A',
          repetitionsRange: RepetitionsRange.medium,
        ),
      ];

      when(() => mockExerciseSetPresentationRepository.getExerciseSets(
              lastNDays: any(named: 'lastNDays'),
              exerciseTemplateId: any(named: 'exerciseTemplateId')))
          .thenAnswer((invocation) async {
        return Result.ok(initialSets);
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ExerciseSetsViewModel>.value(
              value: viewModel,
            ),
            ChangeNotifierProvider<TrainingSessionManager>.value(
              value: trainingSessionManager,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ExerciseSetsPage(),
            ),
          ),
        ),
      );

      await viewModel.fetchExerciseSets.execute();
      await tester.pumpAndSettle();

      // Should show rank #1 for the only exercise
      expect(find.textContaining('Rank: #1'), findsOneWidget);

      // Add a new exercise with higher volume
      final updatedSets = [
        ...initialSets,
        ExerciseSetPresentation(
          setId: '2',
          exerciseTemplateId: 'template2',
          repetitions: 10,
          platesWeight: 20,
          equipmentWeight: 20,
          dateTime: date2,
          displayName: 'Exercise B',
          repetitionsRange: RepetitionsRange.medium,
        ),
      ];

      when(() => mockExerciseSetPresentationRepository.getExerciseSets(
              lastNDays: any(named: 'lastNDays'),
              exerciseTemplateId: any(named: 'exerciseTemplateId')))
          .thenAnswer((invocation) async {
        return Result.ok(updatedSets);
      });

      await viewModel.fetchExerciseSets.execute();
      await tester.pumpAndSettle();

      // Now we should see both ranks
      expect(find.textContaining('Rank: #1'), findsOneWidget);
      expect(find.textContaining('Rank: #2'), findsOneWidget);
    });
  });
}

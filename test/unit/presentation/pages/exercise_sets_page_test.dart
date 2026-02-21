import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:exercise_management/data/repository/exercise_set_presentation_repository.dart';
import 'package:exercise_management/data/repository/exercise_set_repository.dart';
import 'package:exercise_management/data/repository/exercise_template_repository.dart';
import 'package:exercise_management/presentation/pages/exercise_sets_page.dart';
import 'package:exercise_management/core/services/exercise_ranking_manager.dart';
import 'package:exercise_management/presentation/view_models/exercise_sets_view_model.dart';
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
    late ExerciseRankingManager rankingManager;

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
      rankingManager = ExerciseRankingManager();

      viewModel = ExerciseSetsViewModel(
          exerciseSetRepository: mockExerciseSetRepository,
          exerciseSetPresentationRepository:
              mockExerciseSetPresentationRepository,
          exerciseTemplateRepository: mockExerciseTemplateRepository,
          rankingManager: rankingManager);

      when(() => mockExerciseSetRepository.addExercises(any()))
          .thenAnswer((invocation) async {
        return Result.ok(null);
      });
      when(() => mockExerciseTemplateRepository.getExercises())
          .thenAnswer((invocation) async {
        return Result.ok([]);
      });
    });

    testWidgets('displays rank based on total volume within same template',
        (WidgetTester tester) async {
      // Create test data with different total volumes for the SAME template
      // Date 1, Template 1: 3 sets * (20 + 20) * 10 = 1200 total volume (Rank #1)
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

      // Date 2, Template 1: 2 sets * (15 + 15) * 8 = 480 total volume (Rank #2)
      // Same template as above, so it should be ranked against date1
      final date2Template1Sets = [
        ExerciseSetPresentation(
          setId: '4',
          exerciseTemplateId: 'template1',
          repetitions: 8,
          platesWeight: 15,
          equipmentWeight: 15,
          dateTime: date2,
          displayName: 'Bench Press',
          repetitionsRange: RepetitionsRange.medium,
        ),
        ExerciseSetPresentation(
          setId: '5',
          exerciseTemplateId: 'template1',
          repetitions: 8,
          platesWeight: 15,
          equipmentWeight: 15,
          dateTime: date2,
          displayName: 'Bench Press',
          repetitionsRange: RepetitionsRange.medium,
        ),
      ];

      final allSets = [...date1Template1Sets, ...date2Template1Sets];

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
            Provider<ExerciseRankingManager>.value(
              value: rankingManager,
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

      // Expand the date-level ExpansionTiles to reveal template-level tiles with rank badges
      // Find and tap the date1 expansion tile
      final date1Tile = find.text('2023-01-01');
      expect(date1Tile, findsOneWidget);
      await tester.tap(date1Tile);
      await tester.pumpAndSettle();

      // Find and tap the date2 expansion tile
      final date2Tile = find.text('2023-01-02');
      expect(date2Tile, findsOneWidget);
      await tester.tap(date2Tile);
      await tester.pumpAndSettle();

      // Verify that ranks are displayed correctly within the same template
      // Date 1 Bench Press should be Rank #1 (higher volume)
      expect(find.text('#1'), findsOneWidget);
      // Date 2 Bench Press should be Rank #2 (lower volume, but same template)
      expect(find.text('#2'), findsOneWidget);
    });

    testWidgets('different templates each get their own rank #1',
        (WidgetTester tester) async {
      // Initial data - template 1
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
            Provider<ExerciseRankingManager>.value(
              value: rankingManager,
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

      // Expand the date1 expansion tile to reveal the exercise template tile
      final date1Tile = find.text('2023-01-01');
      expect(date1Tile, findsOneWidget);
      await tester.tap(date1Tile);
      await tester.pumpAndSettle();

      // Should show rank #1 for the only exercise
      expect(find.text('#1'), findsOneWidget);

      // Add a new exercise from a DIFFERENT template
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

      // Expand only the lower tile as the first tile is already expanded
      final date1TileAgain = find.text('2023-01-01');
      expect(date1TileAgain, findsOneWidget);
      await tester.tap(date1TileAgain);
      await tester.pumpAndSettle();

      // a way to capture golden snapshot
      // to create the golden file, run the test with --update-goldens
      // e.g. flutter test test/unit/presentation/pages/exercise_sets_page_test.dart --update-goldens
      // await expectLater(
      //     find.byType(MaterialApp),
      //     matchesGoldenFile('debug_snapshot.png')
      // );

      // Both exercises are in different templates, so both should be rank #1
      expect(find.text('#1'), findsNWidgets(2));
    });
  });

  group('ExerciseSetsPage Groups Sorting', () {
    late MockExerciseSetRepository mockExerciseSetRepository;
    late MockExerciseTemplateRepository mockExerciseTemplateRepository;
    late MockExerciseSetPresentationRepository
        mockExerciseSetPresentationRepository;
    late ExerciseSetsViewModel viewModel;
    late ExerciseRankingManager rankingManager;

    final testDate = DateTime(2023, 1, 1);

    setUpAll(() {
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
      rankingManager = ExerciseRankingManager();

      viewModel = ExerciseSetsViewModel(
          exerciseSetRepository: mockExerciseSetRepository,
          exerciseSetPresentationRepository:
              mockExerciseSetPresentationRepository,
          exerciseTemplateRepository: mockExerciseTemplateRepository,
          rankingManager: rankingManager);

      when(() => mockExerciseSetRepository.addExercises(any()))
          .thenAnswer((invocation) async {
        return Result.ok(null);
      });
      when(() => mockExerciseTemplateRepository.getExercises())
          .thenAnswer((invocation) async {
        return Result.ok([]);
      });
    });

    testWidgets(
        'groups are sorted by latest completedAt descending, nulls last',
        (WidgetTester tester) async {
      final completedEarlier = DateTime(2023, 1, 1, 9, 0);
      final completedLater = DateTime(2023, 1, 1, 10, 0);

      // Template A was completed earlier; template B was completed later.
      // Expected order: template B first, then template A, then template C (null).
      final sets = [
        ExerciseSetPresentation(
          setId: '1',
          exerciseTemplateId: 'templateA',
          repetitions: 10,
          platesWeight: 10,
          equipmentWeight: 10,
          dateTime: testDate,
          displayName: 'Exercise A',
          repetitionsRange: RepetitionsRange.medium,
          completedAt: completedEarlier,
        ),
        ExerciseSetPresentation(
          setId: '2',
          exerciseTemplateId: 'templateB',
          repetitions: 10,
          platesWeight: 10,
          equipmentWeight: 10,
          dateTime: testDate,
          displayName: 'Exercise B',
          repetitionsRange: RepetitionsRange.medium,
          completedAt: completedLater,
        ),
        ExerciseSetPresentation(
          setId: '3',
          exerciseTemplateId: 'templateC',
          repetitions: 10,
          platesWeight: 10,
          equipmentWeight: 10,
          dateTime: testDate,
          displayName: 'Exercise C',
          repetitionsRange: RepetitionsRange.medium,
          completedAt: null,
        ),
      ];

      when(() => mockExerciseSetPresentationRepository.getExerciseSets(
              lastNDays: any(named: 'lastNDays'),
              exerciseTemplateId: any(named: 'exerciseTemplateId')))
          .thenAnswer((invocation) async {
        return Result.ok(sets);
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ExerciseSetsViewModel>.value(
              value: viewModel,
            ),
            Provider<ExerciseRankingManager>.value(
              value: rankingManager,
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

      // Expand the date tile to reveal the template groups
      final dateTile = find.text('2023-01-01');
      await tester.tap(dateTile);
      await tester.pumpAndSettle();

      // Verify all three template groups are visible
      expect(find.text('Exercise A'), findsOneWidget);
      expect(find.text('Exercise B'), findsOneWidget);
      expect(find.text('Exercise C'), findsOneWidget);

      // Verify order: Exercise B (latest completedAt) before Exercise A, before Exercise C (null)
      final exerciseBOffset =
          tester.getTopLeft(find.text('Exercise B')).dy;
      final exerciseAOffset =
          tester.getTopLeft(find.text('Exercise A')).dy;
      final exerciseCOffset =
          tester.getTopLeft(find.text('Exercise C')).dy;

      expect(exerciseBOffset, lessThan(exerciseAOffset));
      expect(exerciseAOffset, lessThan(exerciseCOffset));
    });
  });

  group('ExerciseSetsPage Toggle Completion', () {
    late MockExerciseSetRepository mockExerciseSetRepository;
    late MockExerciseTemplateRepository mockExerciseTemplateRepository;
    late MockExerciseSetPresentationRepository
        mockExerciseSetPresentationRepository;
    late ExerciseSetsViewModel viewModel;
    late ExerciseRankingManager rankingManager;

    final testDate = DateTime(2023, 1, 1);

    setUpAll(() {
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
      rankingManager = ExerciseRankingManager();

      viewModel = ExerciseSetsViewModel(
          exerciseSetRepository: mockExerciseSetRepository,
          exerciseSetPresentationRepository:
              mockExerciseSetPresentationRepository,
          exerciseTemplateRepository: mockExerciseTemplateRepository,
          rankingManager: rankingManager);

      when(() => mockExerciseSetRepository.addExercises(any()))
          .thenAnswer((invocation) async {
        return Result.ok(null);
      });
      when(() => mockExerciseTemplateRepository.getExercises())
          .thenAnswer((invocation) async {
        return Result.ok([]);
      });
    });

    testWidgets('long press on unmarked set calls update with completedAt set',
        (WidgetTester tester) async {
      // Create an unmarked exercise set (completedAt is null)
      final unmarkedSet = ExerciseSetPresentation(
        setId: '1',
        exerciseTemplateId: 'template1',
        repetitions: 10,
        platesWeight: 20,
        equipmentWeight: 20,
        dateTime: testDate,
        displayName: 'Bench Press',
        repetitionsRange: RepetitionsRange.medium,
        completedAt: null, // Not completed
      );

      when(() => mockExerciseSetPresentationRepository.getExerciseSets(
              lastNDays: any(named: 'lastNDays'),
              exerciseTemplateId: any(named: 'exerciseTemplateId')))
          .thenAnswer((invocation) async {
        return Result.ok([unmarkedSet]);
      });

      ExerciseSet? capturedExerciseSet;
      when(() => mockExerciseSetRepository.updateExercise(any()))
          .thenAnswer((invocation) async {
        capturedExerciseSet = invocation.positionalArguments[0] as ExerciseSet;
        return Result.ok(capturedExerciseSet!);
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ExerciseSetsViewModel>.value(
              value: viewModel,
            ),
            Provider<ExerciseRankingManager>.value(
              value: rankingManager,
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

      // Expand the date tile to reveal the exercise
      final dateTile = find.text('2023-01-01');
      await tester.tap(dateTile);
      await tester.pumpAndSettle();

      // Expand the template tile to reveal the list tile
      final templateTile = find.text('Bench Press').first;
      await tester.tap(templateTile);
      await tester.pumpAndSettle();

      // Long press on the exercise to toggle completion
      final exerciseTile = find.widgetWithText(ListTile, 'Bench Press').last;
      await tester.longPress(exerciseTile);
      await tester.pumpAndSettle();

      // Verify updateExercise was called with completedAt set (not null)
      expect(capturedExerciseSet, isNotNull);
      expect(capturedExerciseSet!.completedAt, isNotNull);
    });

    testWidgets('long press on marked set calls update with completedAt null',
        (WidgetTester tester) async {
      final completedTime = DateTime(2023, 1, 1, 10, 30);

      // Create a marked exercise set (completedAt is set)
      final markedSet = ExerciseSetPresentation(
        setId: '1',
        exerciseTemplateId: 'template1',
        repetitions: 10,
        platesWeight: 20,
        equipmentWeight: 20,
        dateTime: testDate,
        displayName: 'Bench Press',
        repetitionsRange: RepetitionsRange.medium,
        completedAt: completedTime, // Already completed
      );

      when(() => mockExerciseSetPresentationRepository.getExerciseSets(
              lastNDays: any(named: 'lastNDays'),
              exerciseTemplateId: any(named: 'exerciseTemplateId')))
          .thenAnswer((invocation) async {
        return Result.ok([markedSet]);
      });

      ExerciseSet? capturedExerciseSet;
      when(() => mockExerciseSetRepository.updateExercise(any()))
          .thenAnswer((invocation) async {
        capturedExerciseSet = invocation.positionalArguments[0] as ExerciseSet;
        return Result.ok(capturedExerciseSet!);
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ExerciseSetsViewModel>.value(
              value: viewModel,
            ),
            Provider<ExerciseRankingManager>.value(
              value: rankingManager,
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

      // Expand the date tile to reveal the exercise
      final dateTile = find.text('2023-01-01');
      await tester.tap(dateTile);
      await tester.pumpAndSettle();

      // Expand the template tile to reveal the list tile
      final templateTile = find.text('Bench Press').first;
      await tester.tap(templateTile);
      await tester.pumpAndSettle();

      // Long press on the exercise to toggle completion (unmark)
      final exerciseTile = find.widgetWithText(ListTile, 'Bench Press').last;
      await tester.longPress(exerciseTile);
      await tester.pumpAndSettle();

      // Verify updateExercise was called with completedAt set to null (unmarked)
      expect(capturedExerciseSet, isNotNull);
      expect(capturedExerciseSet!.completedAt, isNull);
    });
  });
}

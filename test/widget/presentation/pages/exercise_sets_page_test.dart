import 'package:exercise_management/core/command.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/presentation/pages/exercise_sets_page.dart';
import 'package:exercise_management/presentation/view_models/exercise_sets_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockExerciseSetsViewModel extends Mock implements ExerciseSetsViewModel {}

class MockCommand0<T> extends Mock implements Command0<T> {}

void main() {
  late MockExerciseSetsViewModel mockViewModel;
  late MockCommand0<List<ExerciseSetPresentation>> mockFetchExerciseSets;
  late MockCommand0<List<ExerciseTemplate>> mockFetchExerciseTemplates;
  late MockCommand0<List<ExerciseSetPresentation>> mockFetchMoreExerciseSets;

  setUp(() {
    mockViewModel = MockExerciseSetsViewModel();
    mockFetchExerciseSets = MockCommand0<List<ExerciseSetPresentation>>();
    mockFetchExerciseTemplates = MockCommand0<List<ExerciseTemplate>>();
    mockFetchMoreExerciseSets = MockCommand0<List<ExerciseSetPresentation>>();

    when(() => mockViewModel.addListener(any())).thenReturn(null);
    when(() => mockViewModel.removeListener(any())).thenReturn(null);
    when(() => mockViewModel.fetchExerciseSets)
        .thenReturn(mockFetchExerciseSets);
    when(() => mockViewModel.fetchExerciseTemplates)
        .thenReturn(mockFetchExerciseTemplates);
    when(() => mockViewModel.fetchMoreExerciseSets)
        .thenReturn(mockFetchMoreExerciseSets);

    when(() => mockFetchExerciseSets.running).thenReturn(false);
    when(() => mockFetchExerciseSets.error).thenReturn(false);
    when(() => mockFetchExerciseSets.execute()).thenAnswer((_) async {});

    when(() => mockFetchMoreExerciseSets.running).thenReturn(false);
    when(() => mockFetchMoreExerciseSets.error).thenReturn(false);
    when(() => mockFetchMoreExerciseSets.execute()).thenAnswer((_) async {});

    when(() => mockViewModel.selectedExerciseTemplateId).thenReturn(null);
    when(() => mockViewModel.exerciseTemplates).thenReturn([]);
    // Default rank to 1
    when(() => mockViewModel.getRank(any(), any())).thenReturn(1);
  });

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<ExerciseSetsViewModel>.value(
      value: mockViewModel,
      child: const MaterialApp(
        home: Scaffold(
          body: ExerciseSetsPage(),
        ),
      ),
    );
  }

  testWidgets('Exercise groups are sorted by latest completion time',
      (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Group A: Completed at 10:00
    // Group B: Completed at 09:00
    // If sorted ascending, B should be first.

    final groupASet = ExerciseSetPresentation(
      setId: '1',
      exerciseTemplateId: 'A',
      dateTime: today,
      equipmentWeight: 0,
      platesWeight: 100,
      repetitions: 10,
      displayName: 'Group A',
      repetitionsRange: RepetitionsRange.medium,
      completedAt: DateTime(today.year, today.month, today.day, 10, 0),
    );

    final groupBSet = ExerciseSetPresentation(
      setId: '2',
      exerciseTemplateId: 'B',
      dateTime: today,
      equipmentWeight: 0,
      platesWeight: 100,
      repetitions: 10,
      displayName: 'Group B',
      repetitionsRange: RepetitionsRange.medium,
      completedAt: DateTime(today.year, today.month, today.day, 9, 0),
    );

    // Provide them in reverse order of expected sort (A then B)
    // If not sorted, they will appear as A then B.
    // If sorted by time (ascending), they should appear as B then A.
    when(() => mockViewModel.exerciseSets).thenReturn([groupASet, groupBSet]);
    when(() => mockFetchExerciseSets.result)
        .thenReturn(Result.ok([groupASet, groupBSet]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Tap to expand date
    await tester.tap(find.text(dateString));
    await tester.pumpAndSettle();

    // Verify groups are displayed
    expect(find.text('Group A'), findsOneWidget);
    expect(find.text('Group B'), findsOneWidget);

    // Check order
    final groupAFinder = find.text('Group A');
    final groupBFinder = find.text('Group B');

    final groupALocation = tester.getTopLeft(groupAFinder);
    final groupBLocation = tester.getTopLeft(groupBFinder);

    // If B is before A, B.dy < A.dy
    // Current behavior (unsorted groups, insertion order): A then B. So A.dy < B.dy.
    // We expect this test to FAIL if the current behavior is unsorted/insertion order.
    // We want B.dy < A.dy.

    expect(groupBLocation.dy, lessThan(groupALocation.dy), reason: 'Group B (09:00) should be above Group A (10:00)');
  });
}

import 'package:exercise_management/core/command.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
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
  late MockCommand0<List<ExerciseSetPresentation>> mockFetchMoreExerciseSets;

  setUp(() {
    mockViewModel = MockExerciseSetsViewModel();
    mockFetchExerciseSets = MockCommand0<List<ExerciseSetPresentation>>();
    mockFetchMoreExerciseSets = MockCommand0<List<ExerciseSetPresentation>>();

    when(() => mockViewModel.addListener(any())).thenReturn(null);
    when(() => mockViewModel.removeListener(any())).thenReturn(null);

    when(() => mockViewModel.fetchExerciseSets).thenReturn(mockFetchExerciseSets);
    when(() => mockViewModel.fetchMoreExerciseSets).thenReturn(mockFetchMoreExerciseSets);

    when(() => mockFetchExerciseSets.running).thenReturn(false);
    when(() => mockFetchExerciseSets.error).thenReturn(false);
    when(() => mockFetchMoreExerciseSets.running).thenReturn(false);

    // Default rank return
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

  testWidgets('Groups are sorted by latest completion time', (tester) async {
    final now = DateTime(2025, 2, 18);

    // Group A: Latest completion 10:10
    final setA1 = ExerciseSetPresentation(
      setId: '1',
      exerciseTemplateId: 'A',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 0,
      repetitions: 10,
      displayName: 'Template A',
      repetitionsRange: RepetitionsRange.medium,
      completedAt: now.add(const Duration(hours: 10, minutes: 0)), // 10:00
    );
    final setA2 = ExerciseSetPresentation(
      setId: '2',
      exerciseTemplateId: 'A',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 0,
      repetitions: 10,
      displayName: 'Template A',
      repetitionsRange: RepetitionsRange.medium,
      completedAt: now.add(const Duration(hours: 10, minutes: 10)), // 10:10 (Latest for A)
    );

    // Group B: Latest completion 09:10
    final setB1 = ExerciseSetPresentation(
      setId: '3',
      exerciseTemplateId: 'B',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 0,
      repetitions: 10,
      displayName: 'Template B',
      repetitionsRange: RepetitionsRange.medium,
      completedAt: now.add(const Duration(hours: 9, minutes: 0)), // 09:00
    );
    final setB2 = ExerciseSetPresentation(
      setId: '4',
      exerciseTemplateId: 'B',
      dateTime: now,
      equipmentWeight: 0,
      platesWeight: 0,
      repetitions: 10,
      displayName: 'Template B',
      repetitionsRange: RepetitionsRange.medium,
      completedAt: now.add(const Duration(hours: 9, minutes: 10)), // 09:10 (Latest for B)
    );

    // Input order: A first, then B.
    // If sorted by insertion/input: A, B.
    // If sorted by latest completion time (Ascending): B (09:10) < A (10:10). So B, A.
    final exercises = [setA1, setA2, setB1, setB2];

    when(() => mockFetchExerciseSets.result).thenReturn(Result.ok(exercises));
    when(() => mockViewModel.exerciseSets).thenReturn(exercises);
    when(() => mockViewModel.exerciseTemplates).thenReturn([]);
    when(() => mockViewModel.selectedExerciseTemplateId).thenReturn(null);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify date expansion tile is expanded or verify contents under it.
    // Assuming ExpansionTile is collapsed by default? No, usually depends on interaction.
    // But ExpansionTile doesn't auto-expand unless initiallyExpanded is true.
    // Let's tap the Date tile.

    // The date tile title is formated date.
    // _formatDate: '2025-02-18'
    final dateFinder = find.text('2025-02-18');
    expect(dateFinder, findsOneWidget);
    await tester.tap(dateFinder);
    await tester.pumpAndSettle();

    final templateAFinder = find.text('Template A');
    final templateBFinder = find.text('Template B');

    expect(templateAFinder, findsOneWidget);
    expect(templateBFinder, findsOneWidget);

    // Verify order
    final templateAPosition = tester.getTopLeft(templateAFinder).dy;
    final templateBPosition = tester.getTopLeft(templateBFinder).dy;

    // We expect B (09:10) to be before A (10:10).
    // So B.y < A.y
    expect(templateBPosition, lessThan(templateAPosition), reason: 'Template B (09:10) should be before Template A (10:10)');
  });
}

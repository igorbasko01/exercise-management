import 'package:exercise_management/data/models/exercise_program.dart';
import 'package:exercise_management/data/models/exercise_rank_summary.dart';
import 'package:exercise_management/presentation/view_models/home_exercise_ranks_view_model.dart';
import 'package:exercise_management/presentation/view_models/program_progression_view_model.dart';
import 'package:exercise_management/presentation/widgets/exercise_all_time_ranks_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockProgramProgressionViewModel extends Mock
    implements ProgramProgressionViewModel {}

class MockHomeExerciseRanksViewModel extends Mock
    implements HomeExerciseRanksViewModel {}

void main() {
  late MockProgramProgressionViewModel mockProgressionViewModel;
  late MockHomeExerciseRanksViewModel mockRanksViewModel;

  setUp(() {
    mockProgressionViewModel = MockProgramProgressionViewModel();
    mockRanksViewModel = MockHomeExerciseRanksViewModel();

    when(() => mockProgressionViewModel.addListener(any())).thenReturn(null);
    when(() => mockProgressionViewModel.removeListener(any()))
        .thenReturn(null);
    when(() => mockProgressionViewModel.activeProgram).thenReturn(null);

    when(() => mockRanksViewModel.addListener(any())).thenReturn(null);
    when(() => mockRanksViewModel.removeListener(any())).thenReturn(null);
    when(() => mockRanksViewModel.setActiveProgram(any()))
        .thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProgramProgressionViewModel>.value(
            value: mockProgressionViewModel),
        ChangeNotifierProvider<HomeExerciseRanksViewModel>.value(
            value: mockRanksViewModel),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ExerciseAllTimeRanksWidget()),
      ),
    );
  }

  testWidgets('renders nothing when there are no summaries', (tester) async {
    when(() => mockRanksViewModel.exerciseRankSummaries).thenReturn([]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Personal Records'), findsNothing);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('requests ranks for the active program after the first frame',
      (tester) async {
    final program = ExerciseProgram(id: 'p1', name: 'Program 1', sessions: const []);
    when(() => mockProgressionViewModel.activeProgram).thenReturn(program);
    when(() => mockRanksViewModel.exerciseRankSummaries).thenReturn([]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    verify(() => mockRanksViewModel.setActiveProgram(program)).called(1);
  });

  testWidgets(
      'renders an exercise with only one recorded session (no second row)',
      (tester) async {
    final session = ExerciseSessionSummary(
      date: DateTime(2026, 6, 2),
      totalVolume: 1410,
      rank: 1,
      setsLabel: '4 x 100 kg x 5',
    );
    when(() => mockRanksViewModel.exerciseRankSummaries).thenReturn([
      ExerciseRankSummary(
        exerciseTemplateId: 't1',
        exerciseName: 'Bench Press',
        recentSessions: [session],
        bestSession: session,
      ),
    ]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Personal Records'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('#1'), findsOneWidget);
    expect(find.textContaining('Best: 1410 kg'), findsOneWidget);
    expect(find.textContaining('4 x 100 kg x 5'), findsOneWidget);
  });

  testWidgets('renders the two most recent sessions and the best session',
      (tester) async {
    final recent1 = ExerciseSessionSummary(
      date: DateTime(2026, 8, 28),
      totalVolume: 1240,
      rank: 3,
      setsLabel: '4 x 100 kg x 5',
    );
    final recent2 = ExerciseSessionSummary(
      date: DateTime(2026, 8, 21),
      totalVolume: 1180,
      rank: 6,
      setsLabel: '4 x 100 kg x 5',
    );
    final best = ExerciseSessionSummary(
      date: DateTime(2026, 6, 2),
      totalVolume: 1410,
      rank: 1,
      setsLabel: '4 x 100 kg x 5',
    );
    when(() => mockRanksViewModel.exerciseRankSummaries).thenReturn([
      ExerciseRankSummary(
        exerciseTemplateId: 't1',
        exerciseName: 'Bench Press',
        recentSessions: [recent1, recent2],
        bestSession: best,
      ),
    ]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('#3'), findsOneWidget);
    expect(find.text('#6'), findsOneWidget);
    expect(find.textContaining('Best: 1410 kg'), findsOneWidget);
  });
}

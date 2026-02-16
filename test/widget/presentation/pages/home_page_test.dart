import 'package:exercise_management/core/command.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_volume_statistic.dart';
import 'package:exercise_management/presentation/pages/home_page.dart';
import 'package:exercise_management/presentation/view_models/exercise_programs_view_model.dart';
import 'package:exercise_management/presentation/view_models/exercise_statistics_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockExerciseStatisticsViewModel extends Mock
    implements ExerciseStatisticsViewModel {}

class MockExerciseProgramsViewModel extends Mock
    implements ExerciseProgramsViewModel {}

class MockCommand0<T> extends Mock implements Command0<T> {}

void main() {
  late MockExerciseStatisticsViewModel mockStatsViewModel;
  late MockExerciseProgramsViewModel mockProgramsViewModel;

  late MockCommand0<List<bool>> mockFetchCurrentWeek;
  late MockCommand0<double> mockFetchAvg30;
  late MockCommand0<double> mockFetchAvg90;
  late MockCommand0<double> mockFetchAvgHalfYear;
  late MockCommand0<double> mockFetchAvgYear;
  late MockCommand0<List<ExerciseVolumeStatistics>> mockFetchVolume;

  setUp(() {
    mockStatsViewModel = MockExerciseStatisticsViewModel();
    mockProgramsViewModel = MockExerciseProgramsViewModel();

    mockFetchCurrentWeek = MockCommand0<List<bool>>();
    mockFetchAvg30 = MockCommand0<double>();
    mockFetchAvg90 = MockCommand0<double>();
    mockFetchAvgHalfYear = MockCommand0<double>();
    mockFetchAvgYear = MockCommand0<double>();
    mockFetchVolume = MockCommand0<List<ExerciseVolumeStatistics>>();

    registerFallbackValue(() {});

    when(() => mockStatsViewModel.addListener(any())).thenReturn(null);
    when(() => mockStatsViewModel.removeListener(any())).thenReturn(null);
    when(() => mockProgramsViewModel.addListener(any())).thenReturn(null);
    when(() => mockProgramsViewModel.removeListener(any())).thenReturn(null);

    // Mock activeProgram to return null (no active program)
    when(() => mockProgramsViewModel.activeProgram).thenReturn(null);

    when(() => mockStatsViewModel.fetchCurrentWeekExerciseDaysStatistic)
        .thenReturn(mockFetchCurrentWeek);
    when(() => mockStatsViewModel.fetchAverageWeekly30Days)
        .thenReturn(mockFetchAvg30);
    when(() => mockStatsViewModel.fetchAverageWeekly90Days)
        .thenReturn(mockFetchAvg90);
    when(() => mockStatsViewModel.fetchAverageWeeklyHalfYear)
        .thenReturn(mockFetchAvgHalfYear);
    when(() => mockStatsViewModel.fetchAverageWeeklyYear)
        .thenReturn(mockFetchAvgYear);
    when(() => mockStatsViewModel.fetchExerciseVolumeStatistics)
        .thenReturn(mockFetchVolume);

    when(() => mockFetchCurrentWeek.running).thenReturn(false);
    when(() => mockFetchCurrentWeek.error).thenReturn(false);
    when(() => mockFetchCurrentWeek.result)
        .thenReturn(Result<List<bool>>.ok(List.filled(7, false)));
    when(() => mockFetchCurrentWeek.execute()).thenAnswer((_) async {});

    when(() => mockFetchAvg30.running).thenReturn(false);
    when(() => mockFetchAvg30.error).thenReturn(false);
    when(() => mockFetchAvg30.result).thenReturn(Result<double>.ok(0.0));
    when(() => mockFetchAvg30.execute()).thenAnswer((_) async {});

    when(() => mockFetchAvg90.running).thenReturn(false);
    when(() => mockFetchAvg90.error).thenReturn(false);
    when(() => mockFetchAvg90.result).thenReturn(Result<double>.ok(0.0));
    when(() => mockFetchAvg90.execute()).thenAnswer((_) async {});

    when(() => mockFetchAvgHalfYear.running).thenReturn(false);
    when(() => mockFetchAvgHalfYear.error).thenReturn(false);
    when(() => mockFetchAvgHalfYear.result).thenReturn(Result<double>.ok(0.0));
    when(() => mockFetchAvgHalfYear.execute()).thenAnswer((_) async {});

    when(() => mockFetchAvgYear.running).thenReturn(false);
    when(() => mockFetchAvgYear.error).thenReturn(false);
    when(() => mockFetchAvgYear.result).thenReturn(Result<double>.ok(0.0));
    when(() => mockFetchAvgYear.execute()).thenAnswer((_) async {});

    when(() => mockFetchVolume.running).thenReturn(false);
    when(() => mockFetchVolume.error).thenReturn(false);
    when(() => mockFetchVolume.result)
        .thenReturn(Result<List<ExerciseVolumeStatistics>>.ok([]));
    when(() => mockFetchVolume.execute()).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest({VoidCallback? onNavigateToSets}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ExerciseStatisticsViewModel>.value(
            value: mockStatsViewModel),
        ChangeNotifierProvider<ExerciseProgramsViewModel>.value(
            value: mockProgramsViewModel),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: HomePage(onNavigateToSets: onNavigateToSets),
        ),
      ),
    );
  }

  testWidgets('HomePage displays UI elements and CTA triggers callback',
      (tester) async {
    bool callbackCalled = false;
    await tester.pumpWidget(createWidgetUnderTest(onNavigateToSets: () {
      callbackCalled = true;
    }));
    await tester.pumpAndSettle();

    // Verify UI elements
    expect(find.text('EXERCISE NOW'), findsOneWidget);
    expect(find.text('Weekly Progress'), findsWidgets);
    expect(find.text('Average Weekly Stats'), findsOneWidget);
    expect(find.text('Exercise Volume'), findsWidgets);
    expect(find.byType(Card), findsNWidgets(3));

    // Tap CTA and verify callback
    await tester.tap(find.text('EXERCISE NOW'));
    expect(callbackCalled, isTrue);
  });
}

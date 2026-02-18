import 'package:exercise_management/core/command.dart';
import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/presentation/pages/add_exercise_set_page.dart';
import 'package:exercise_management/presentation/view_models/exercise_sets_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockExerciseSetsViewModel extends Mock implements ExerciseSetsViewModel {}

class MockCommand1<T, R> extends Mock implements Command1<T, R> {}

void main() {
  late MockExerciseSetsViewModel mockViewModel;
  late MockCommand1<ExerciseSet, ExerciseSet> mockAddExerciseSet;
  late MockCommand1<ExerciseSet, ExerciseSet> mockUpdateExerciseSet;

  final exerciseTemplate = ExerciseTemplate(
    id: '1',
    name: 'Bench Press',
    muscleGroup: MuscleGroup.chest,
    repetitionsRangeTarget: RepetitionsRange.medium,
  );

  setUp(() {
    mockViewModel = MockExerciseSetsViewModel();
    mockAddExerciseSet = MockCommand1<ExerciseSet, ExerciseSet>();
    mockUpdateExerciseSet = MockCommand1<ExerciseSet, ExerciseSet>();

    registerFallbackValue(ExerciseSet(
      exerciseTemplateId: '1',
      dateTime: DateTime.now(),
      equipmentWeight: 0,
      platesWeight: 0,
      repetitions: 0,
    ));

    when(() => mockViewModel.addListener(any())).thenReturn(null);
    when(() => mockViewModel.removeListener(any())).thenReturn(null);
    when(() => mockViewModel.exerciseTemplates).thenReturn([exerciseTemplate]);
    when(() => mockViewModel.addExerciseSet).thenReturn(mockAddExerciseSet);
    when(() => mockViewModel.updateExerciseSet).thenReturn(mockUpdateExerciseSet);

    when(() => mockAddExerciseSet.execute(any())).thenAnswer((_) async => Result.ok(ExerciseSet(
          exerciseTemplateId: '1',
          dateTime: DateTime.now(),
          equipmentWeight: 0,
          platesWeight: 0,
          repetitions: 0,
        )));
    when(() => mockUpdateExerciseSet.execute(any())).thenAnswer((_) async => Result.ok(ExerciseSet(
          exerciseTemplateId: '1',
          dateTime: DateTime.now(),
          equipmentWeight: 0,
          platesWeight: 0,
          repetitions: 0,
        )));
  });

  Widget createWidgetUnderTest({ExerciseSetPresentation? exerciseSet}) {
    return ChangeNotifierProvider<ExerciseSetsViewModel>.value(
      value: mockViewModel,
      child: MaterialApp(
        home: AddExerciseSetPage(exerciseSet: exerciseSet),
      ),
    );
  }

  testWidgets('AddExerciseSetPage renders correctly', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Add Exercise Set'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Date & Time'), findsOneWidget);
    expect(find.text('Equipment Weight'), findsOneWidget);
    expect(find.text('Plates Weight'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('Save button triggers addExerciseSet', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Equipment Weight'), '20');
    await tester.enterText(find.widgetWithText(TextFormField, 'Plates Weight'), '40');
    // The repetitions field label is dynamic, so we find by type and index
    await tester.enterText(find.byType(TextFormField).at(2), '10');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(() => mockAddExerciseSet.execute(any())).called(1);
  });
}

import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_program.dart';
import 'package:exercise_management/data/models/exercise_program_session.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exercise_program_repository.dart';
import 'package:exercise_management/data/repository/exercise_set_presentation_repository.dart';
import 'package:exercise_management/data/repository/exercise_set_repository.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:exercise_management/presentation/view_models/program_progression_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExerciseProgramRepository extends Mock implements ExerciseProgramRepository {}
class MockExerciseSetPresentationRepository extends Mock implements ExerciseSetPresentationRepository {}
class MockExerciseSetRepository extends Mock implements ExerciseSetRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String>[]);
  });

  group('ProgramProgressionViewModel', () {
    late MockExerciseProgramRepository mockProgramRepository;
    late MockExerciseSetPresentationRepository mockSetPresentationRepository;
    late MockExerciseSetRepository mockSetRepository;
    late ProgramProgressionViewModel viewModel;

    final template1 = ExerciseTemplate(id: 't1', name: 'Exercise 1', muscleGroup: MuscleGroup.chest, repetitionsRangeTarget: RepetitionsRange.medium);
    final template2 = ExerciseTemplate(id: 't2', name: 'Exercise 2', muscleGroup: MuscleGroup.chest, repetitionsRangeTarget: RepetitionsRange.medium);
    final template3 = ExerciseTemplate(id: 't3', name: 'Exercise 3', muscleGroup: MuscleGroup.chest, repetitionsRangeTarget: RepetitionsRange.medium);
    final session1 = ExerciseProgramSession(id: 's1', programId: 'p1', name: 'Session 1', exercises: [template1, template2]);
    final session2 = ExerciseProgramSession(id: 's2', programId: 'p1', name: 'Session 2', exercises: [template3]);
    final activeProgram = ExerciseProgram(id: 'p1', name: 'Program 1', isActive: true, sessions: [session1, session2]);

    setUp(() {
      mockProgramRepository = MockExerciseProgramRepository();
      mockSetPresentationRepository = MockExerciseSetPresentationRepository();
      mockSetRepository = MockExerciseSetRepository();

      when(() => mockProgramRepository.watchPrograms())
          .thenAnswer((_) => Stream.empty());
      when(() => mockSetRepository.watchExerciseSets())
          .thenAnswer((_) => Stream.empty());

      viewModel = ProgramProgressionViewModel(
        programRepository: mockProgramRepository,
        setPresentationRepository: mockSetPresentationRepository,
        exerciseSetRepository: mockSetRepository,
      );
    });

    test('nextSession is first session when no recent sets', () async {
      when(() => mockProgramRepository.getPrograms())
          .thenAnswer((_) async => Result.ok([activeProgram]));
      when(() => mockSetPresentationRepository.getStrictMostRecentRoutineCompletionDate(any()))
          .thenAnswer((_) async => Result.ok(null));

      await viewModel.fetchProgressionData.execute();

      expect(viewModel.activeProgram, equals(activeProgram));
      expect(viewModel.nextSession, equals(session1));
      expect(viewModel.lastSession, isNull);
      expect(viewModel.lastSessionDate, isNull);
    });

    test('nextSession is second session when first session was completely done', () async {
      final completionDate = DateTime(2023, 1, 1);
      
      when(() => mockProgramRepository.getPrograms())
          .thenAnswer((_) async => Result.ok([activeProgram]));
          
      when(() => mockSetPresentationRepository.getStrictMostRecentRoutineCompletionDate(['t1', 't2']))
          .thenAnswer((_) async => Result.ok(completionDate));
      when(() => mockSetPresentationRepository.getStrictMostRecentRoutineCompletionDate(['t3']))
          .thenAnswer((_) async => Result.ok(null));

      await viewModel.fetchProgressionData.execute();

      expect(viewModel.activeProgram, equals(activeProgram));
      expect(viewModel.nextSession, equals(session2)); // session 1 fully completed, next is session 2
      expect(viewModel.lastSession, equals(session1));
      expect(viewModel.lastSessionDate, equals(completionDate));
    });

    test('nextSession is first session when first session was only partially completed', () async {
      when(() => mockProgramRepository.getPrograms())
          .thenAnswer((_) async => Result.ok([activeProgram]));
          
      // 't1' and 't2' were not completed on the same date, so it returns null
      when(() => mockSetPresentationRepository.getStrictMostRecentRoutineCompletionDate(['t1', 't2']))
          .thenAnswer((_) async => Result.ok(null));
      when(() => mockSetPresentationRepository.getStrictMostRecentRoutineCompletionDate(['t3']))
          .thenAnswer((_) async => Result.ok(null));

      await viewModel.fetchProgressionData.execute();

      expect(viewModel.activeProgram, equals(activeProgram));
      expect(viewModel.nextSession, equals(session1)); // session 1 NOT fully completed, we stay on session 1
      expect(viewModel.lastSession, isNull);
      expect(viewModel.lastSessionDate, isNull);
    });

    test('nextSession wraps around to first session when last session was recently completed', () async {
      final completionDate = DateTime(2023, 1, 2);

      when(() => mockProgramRepository.getPrograms())
          .thenAnswer((_) async => Result.ok([activeProgram]));
          
      when(() => mockSetPresentationRepository.getStrictMostRecentRoutineCompletionDate(['t1', 't2']))
          .thenAnswer((_) async => Result.ok(null));
      when(() => mockSetPresentationRepository.getStrictMostRecentRoutineCompletionDate(['t3']))
          .thenAnswer((_) async => Result.ok(completionDate));

      await viewModel.fetchProgressionData.execute();

      expect(viewModel.activeProgram, equals(activeProgram));
      expect(viewModel.nextSession, equals(session1)); // session 2 completed, loops back to session 1
      expect(viewModel.lastSession, equals(session2));
      expect(viewModel.lastSessionDate, equals(completionDate));
    });

    test('nextSession is null when no active program', () async {
      final inactiveProgram = ExerciseProgram(id: 'p1', name: 'Program 1', isActive: false, sessions: [session1, session2]);

      when(() => mockProgramRepository.getPrograms())
          .thenAnswer((_) async => Result.ok([inactiveProgram]));

      await viewModel.fetchProgressionData.execute();

      expect(viewModel.activeProgram, isNull);
      expect(viewModel.nextSession, isNull);
      expect(viewModel.lastSession, isNull);
      expect(viewModel.lastSessionDate, isNull);
    });
    test('getLatestSetsForNextSession uses the most recent completion dates for each individual exercise', () async {
      // Session 1 (older) had Bench Press (t1) and Leg Extensions (t2).
      // Session 2 (newer) had Bench Press (t1) and Leg Curls (t3).
      final date1 = DateTime(2023, 1, 1); // Older date for Session 1
      final date2 = DateTime(2023, 1, 2); // Newer date for Session 2
      
      when(() => mockProgramRepository.getPrograms())
          .thenAnswer((_) async => Result.ok([activeProgram]));
      
      // Mock strict completion to make session 1 the next session
      when(() => mockSetPresentationRepository.getStrictMostRecentRoutineCompletionDate(['t1', 't2']))
          .thenAnswer((_) async => Result.ok(null));
      when(() => mockSetPresentationRepository.getStrictMostRecentRoutineCompletionDate(['t3']))
          .thenAnswer((_) async => Result.ok(date2));

      await viewModel.fetchProgressionData.execute();
      
      // Verify we are moving onto session 1
      expect(viewModel.nextSession, equals(session1));

      // Now mock the non-strict completion date fetch used for progression history
      // Bench press (t1) was most recently done on date2, Leg extensions (t2) on date1
      when(() => mockSetPresentationRepository.getMostRecentCompletionDate(['t1', 't2']))
          .thenAnswer((_) async => Result.ok({
            't1': date2,
            't2': date1,
          }));

      final mockSets = [
        ExerciseSetPresentation(
          setId: 'set1', 
          exerciseTemplateId: 't1', 
          displayName: 'Bench Press', 
          dateTime: date2, 
          equipmentWeight: 100, 
          platesWeight: 0, 
          repetitions: 10,
          repetitionsRange: RepetitionsRange.medium,
        ),
        ExerciseSetPresentation(
          setId: 'set2', 
          exerciseTemplateId: 't2', 
          displayName: 'Leg Extensions', 
          dateTime: date1, 
          equipmentWeight: 50, 
          platesWeight: 0, 
          repetitions: 12,
          repetitionsRange: RepetitionsRange.medium,
        ),
      ];

      when(() => mockSetPresentationRepository.getExerciseSetsByDateAndTemplates({
            't1': date2,
            't2': date1,
          }))
          .thenAnswer((_) async => Result.ok(mockSets));

      final latestSets = await viewModel.getLatestSetsForNextSession();
      
      expect(latestSets, isNotNull);
      expect(latestSets!.length, 2);
      
      // We verify that the view model correctly passed the most recent, individual dates to the repository
      // Specifically that Bench Press (t1) used date2, and Leg Extensions (t2) used date1.
      expect(latestSets.any((s) => s.exerciseTemplateId == 't1' && s.dateTime == date2), isTrue);
      expect(latestSets.any((s) => s.exerciseTemplateId == 't2' && s.dateTime == date1), isTrue);
    });
  });
}

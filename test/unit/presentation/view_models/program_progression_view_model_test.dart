import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_program.dart';
import 'package:exercise_management/data/models/exercise_program_session.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exercise_program_repository.dart';
import 'package:exercise_management/data/repository/exercise_set_presentation_repository.dart';
import 'package:exercise_management/presentation/view_models/program_progression_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExerciseProgramRepository extends Mock implements ExerciseProgramRepository {}
class MockExerciseSetPresentationRepository extends Mock implements ExerciseSetPresentationRepository {}

void main() {
  group('ProgramProgressionViewModel', () {
    late MockExerciseProgramRepository mockProgramRepository;
    late MockExerciseSetPresentationRepository mockSetPresentationRepository;
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
      viewModel = ProgramProgressionViewModel(
        programRepository: mockProgramRepository,
        setPresentationRepository: mockSetPresentationRepository,
      );
    });

    test('nextSession is first session when no recent sets', () async {
      when(() => mockProgramRepository.getPrograms())
          .thenAnswer((_) async => Result.ok([activeProgram]));
      when(() => mockSetPresentationRepository.getMostRecentCompletionDate(any()))
          .thenAnswer((_) async => Result.ok(null));

      await viewModel.fetchProgressionData.execute();

      expect(viewModel.activeProgram, equals(activeProgram));
      expect(viewModel.nextSession, equals(session1));
    });

    test('nextSession is second session when first session was completely done', () async {
      when(() => mockProgramRepository.getPrograms())
          .thenAnswer((_) async => Result.ok([activeProgram]));
          
      when(() => mockSetPresentationRepository.getMostRecentCompletionDate(['t1', 't2']))
          .thenAnswer((_) async => Result.ok(DateTime.now()));
      when(() => mockSetPresentationRepository.getMostRecentCompletionDate(['t3']))
          .thenAnswer((_) async => Result.ok(null));

      await viewModel.fetchProgressionData.execute();

      expect(viewModel.activeProgram, equals(activeProgram));
      expect(viewModel.nextSession, equals(session2)); // session 1 fully completed, next is session 2
    });

    test('nextSession is first session when first session was only partially completed', () async {
      when(() => mockProgramRepository.getPrograms())
          .thenAnswer((_) async => Result.ok([activeProgram]));
          
      // 't1' and 't2' were not completed on the same date, so it returns null
      when(() => mockSetPresentationRepository.getMostRecentCompletionDate(['t1', 't2']))
          .thenAnswer((_) async => Result.ok(null));
      when(() => mockSetPresentationRepository.getMostRecentCompletionDate(['t3']))
          .thenAnswer((_) async => Result.ok(null));

      await viewModel.fetchProgressionData.execute();

      expect(viewModel.activeProgram, equals(activeProgram));
      expect(viewModel.nextSession, equals(session1)); // session 1 NOT fully completed, we stay on session 1
    });

    test('nextSession wraps around to first session when last session was recently completed', () async {
      when(() => mockProgramRepository.getPrograms())
          .thenAnswer((_) async => Result.ok([activeProgram]));
          
      when(() => mockSetPresentationRepository.getMostRecentCompletionDate(['t1', 't2']))
          .thenAnswer((_) async => Result.ok(null));
      when(() => mockSetPresentationRepository.getMostRecentCompletionDate(['t3']))
          .thenAnswer((_) async => Result.ok(DateTime.now()));

      await viewModel.fetchProgressionData.execute();

      expect(viewModel.activeProgram, equals(activeProgram));
      expect(viewModel.nextSession, equals(session1)); // session 2 completed, loops back to session 1
    });

    test('nextSession is null when no active program', () async {
      final inactiveProgram = ExerciseProgram(id: 'p1', name: 'Program 1', isActive: false, sessions: [session1, session2]);

      when(() => mockProgramRepository.getPrograms())
          .thenAnswer((_) async => Result.ok([inactiveProgram]));

      await viewModel.fetchProgressionData.execute();

      expect(viewModel.activeProgram, isNull);
      expect(viewModel.nextSession, isNull);
    });
  });
}

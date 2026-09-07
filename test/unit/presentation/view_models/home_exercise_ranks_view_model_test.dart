import 'dart:async';

import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_program.dart';
import 'package:exercise_management/data/models/exercise_program_session.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exercise_set_presentation_repository.dart';
import 'package:exercise_management/data/repository/exercise_template_repository.dart';
import 'package:exercise_management/data/repository/in_memory_exercise_template_repository.dart';
import 'package:exercise_management/data/repository/in_memory_exercise_set_presentation_repository.dart';
import 'package:exercise_management/data/repository/in_memory_exercise_set_repository.dart';
import 'package:exercise_management/presentation/view_models/home_exercise_ranks_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExerciseSetPresentationRepository extends Mock
    implements ExerciseSetPresentationRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String>[]);
  });

  group('HomeExerciseRanksViewModel', () {
    late InMemoryExerciseSetRepository setRepository;
    late ExerciseTemplateRepository templateRepository;
    late InMemoryExerciseSetPresentationRepository presentationRepository;
    late HomeExerciseRanksViewModel viewModel;

    final benchPress = ExerciseTemplate(
        id: 't1',
        name: 'Bench Press',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium);
    final squat = ExerciseTemplate(
        id: 't2',
        name: 'Squat',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium);

    setUp(() async {
      setRepository = InMemoryExerciseSetRepository();
      templateRepository = InMemoryExerciseRepository();
      await templateRepository.addExercise(benchPress);
      await templateRepository.addExercise(squat);

      presentationRepository = InMemoryExerciseSetPresentationRepository(
        exerciseSetRepository: setRepository,
        exerciseTemplateRepository: templateRepository,
      );

      viewModel = HomeExerciseRanksViewModel(
        setPresentationRepository: presentationRepository,
        exerciseSetRepository: setRepository,
      );
    });

    var nextSetId = 0;
    ExerciseSet set(
        {required String templateId,
        required DateTime date,
        required double weight,
        required int reps}) {
      // Explicit ids: InMemoryExerciseSetRepository generates ids from the
      // current millisecond, so two content-identical sets added back to back
      // can collide and get silently rejected as duplicates.
      return ExerciseSet(
        id: 'set-${nextSetId++}',
        exerciseTemplateId: templateId,
        dateTime: date,
        equipmentWeight: weight,
        platesWeight: 0,
        repetitions: reps,
        completedAt: date,
      );
    }

    test('program with no exercises yields no summaries', () async {
      final program = ExerciseProgram(id: 'p1', name: 'P1', sessions: []);

      await viewModel.setActiveProgram(program);

      expect(viewModel.exerciseRankSummaries, isEmpty);
    });

    test('no active program yields no summaries', () async {
      await viewModel.setActiveProgram(null);

      expect(viewModel.exerciseRankSummaries, isEmpty);
    });

    test('an exercise with no recorded sets shows up with no sessions', () async {
      final session = ExerciseProgramSession(
          id: 's1', programId: 'p1', name: 'S1', exercises: [benchPress]);
      final program =
          ExerciseProgram(id: 'p1', name: 'P1', sessions: [session]);

      await viewModel.setActiveProgram(program);

      expect(viewModel.exerciseRankSummaries, hasLength(1));
      final summary = viewModel.exerciseRankSummaries.first;
      expect(summary.exerciseTemplateId, 't1');
      expect(summary.recentSessions, isEmpty);
      expect(summary.bestSession, isNull);
    });

    test('an exercise with a single recorded session is its own best', () async {
      final date = DateTime(2026, 1, 1);
      await setRepository.addExercises([
        set(templateId: 't1', date: date, weight: 100, reps: 5),
        set(templateId: 't1', date: date, weight: 100, reps: 5),
      ]);

      final session = ExerciseProgramSession(
          id: 's1', programId: 'p1', name: 'S1', exercises: [benchPress]);
      final program =
          ExerciseProgram(id: 'p1', name: 'P1', sessions: [session]);

      await viewModel.setActiveProgram(program);

      final summary = viewModel.exerciseRankSummaries.first;
      expect(summary.recentSessions, hasLength(1));
      expect(summary.recentSessions.first.rank, 1);
      expect(summary.bestSession, isNotNull);
      expect(summary.bestSession!.date, date);
      expect(summary.bestSession!.setsLabel, '2 x 100 kg x 5');
    });

    test('dedups an exercise that appears in more than one session of the program', () async {
      final session1 = ExerciseProgramSession(
          id: 's1', programId: 'p1', name: 'S1', exercises: [benchPress, squat]);
      final session2 = ExerciseProgramSession(
          id: 's2', programId: 'p1', name: 'S2', exercises: [benchPress]);
      final program = ExerciseProgram(
          id: 'p1', name: 'P1', sessions: [session1, session2]);

      await viewModel.setActiveProgram(program);

      expect(viewModel.exerciseRankSummaries, hasLength(2));
      expect(
          viewModel.exerciseRankSummaries.map((s) => s.exerciseTemplateId),
          containsAll(['t1', 't2']));
    });

    test('ranks sessions all-time, independent of how many are loaded elsewhere', () async {
      // Three sessions of Bench Press, the heaviest being the oldest one.
      final oldest = DateTime(2025, 1, 1);
      final middle = DateTime(2025, 6, 1);
      final newest = DateTime(2026, 1, 1);

      await setRepository.addExercises([
        set(templateId: 't1', date: oldest, weight: 140, reps: 5), // volume 700, best
        set(templateId: 't1', date: middle, weight: 100, reps: 5), // volume 500
        set(templateId: 't1', date: newest, weight: 120, reps: 5), // volume 600
      ]);

      final session = ExerciseProgramSession(
          id: 's1', programId: 'p1', name: 'S1', exercises: [benchPress]);
      final program =
          ExerciseProgram(id: 'p1', name: 'P1', sessions: [session]);

      await viewModel.setActiveProgram(program);

      final summary = viewModel.exerciseRankSummaries.first;

      // Only the two most recent sessions are surfaced, newest first.
      expect(summary.recentSessions, hasLength(2));
      expect(summary.recentSessions[0].date, newest);
      expect(summary.recentSessions[1].date, middle);

      // But their ranks reflect the full history, not just these two.
      expect(summary.recentSessions[0].rank, 2); // 600 is 2nd all-time
      expect(summary.recentSessions[1].rank, 3); // 500 is 3rd all-time

      // The all-time best is the oldest, heaviest session, not one of the loaded two.
      expect(summary.bestSession!.date, oldest);
      expect(summary.bestSession!.rank, 1);
    });

    test('breaks a tie for best session by earliest date', () async {
      final earlier = DateTime(2026, 1, 1);
      final later = DateTime(2026, 2, 1);

      await setRepository.addExercises([
        set(templateId: 't1', date: earlier, weight: 100, reps: 5), // volume 500
        set(templateId: 't1', date: later, weight: 100, reps: 5), // volume 500, tie
      ]);

      final session = ExerciseProgramSession(
          id: 's1', programId: 'p1', name: 'S1', exercises: [benchPress]);
      final program =
          ExerciseProgram(id: 'p1', name: 'P1', sessions: [session]);

      await viewModel.setActiveProgram(program);

      final summary = viewModel.exerciseRankSummaries.first;
      expect(summary.bestSession!.date, earlier);
    });

    test('excludes sets that have not been completed yet', () async {
      final completedDate = DateTime(2026, 1, 1);
      final uncompletedDate = DateTime(2026, 2, 1);

      await setRepository.addExercises([
        set(templateId: 't1', date: completedDate, weight: 100, reps: 5),
        // Progression pre-creates the next session's sets before they're
        // performed; those carry no completedAt yet.
        ExerciseSet(
          id: 'set-${nextSetId++}',
          exerciseTemplateId: 't1',
          dateTime: uncompletedDate,
          equipmentWeight: 999,
          platesWeight: 0,
          repetitions: 5,
        ),
      ]);

      final session = ExerciseProgramSession(
          id: 's1', programId: 'p1', name: 'S1', exercises: [benchPress]);
      final program =
          ExerciseProgram(id: 'p1', name: 'P1', sessions: [session]);

      await viewModel.setActiveProgram(program);

      final summary = viewModel.exerciseRankSummaries.first;
      expect(summary.recentSessions, hasLength(1));
      expect(summary.recentSessions.first.date, completedDate);
      expect(summary.bestSession!.date, completedDate);
    });

    test('formats a non-uniform session compactly', () async {
      final date = DateTime(2026, 1, 1);
      await setRepository.addExercises([
        set(templateId: 't1', date: date, weight: 100, reps: 5),
        set(templateId: 't1', date: date, weight: 95, reps: 6),
      ]);

      final session = ExerciseProgramSession(
          id: 's1', programId: 'p1', name: 'S1', exercises: [benchPress]);
      final program =
          ExerciseProgram(id: 'p1', name: 'P1', sessions: [session]);

      await viewModel.setActiveProgram(program);

      final summary = viewModel.exerciseRankSummaries.first;
      expect(summary.bestSession!.setsLabel, '100 kg x 5, 95 kg x 6');
    });

    test('completes a queued reload instead of hanging when disposed mid-flight', () async {
      final mockRepository = MockExerciseSetPresentationRepository();
      final neverResolves = Completer<Result<List<ExerciseSetPresentation>>>();
      when(() => mockRepository.getExerciseSetsForTemplates(any()))
          .thenAnswer((_) => neverResolves.future);

      final slowViewModel = HomeExerciseRanksViewModel(
        setPresentationRepository: mockRepository,
        exerciseSetRepository: setRepository,
      );

      final session = ExerciseProgramSession(
          id: 's1', programId: 'p1', name: 'S1', exercises: [benchPress]);
      final program =
          ExerciseProgram(id: 'p1', name: 'P1', sessions: [session]);

      slowViewModel.setActiveProgram(program); // starts and never finishes
      final queued = slowViewModel.setActiveProgram(program); // queued behind it

      slowViewModel.dispose();

      await expectLater(queued, completes);
    });
  });
}

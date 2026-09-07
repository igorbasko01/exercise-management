import 'package:clock/clock.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/services/completion_time_resolver.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ExerciseSetPresentation buildSet({
    required DateTime dateTime,
    DateTime? completedAt,
    String setId = 'set',
  }) {
    return ExerciseSetPresentation(
      setId: setId,
      exerciseTemplateId: 'template',
      dateTime: dateTime,
      equipmentWeight: 0,
      platesWeight: 20,
      repetitions: 5,
      displayName: 'Bench Press',
      repetitionsRange: RepetitionsRange.medium,
      completedAt: completedAt,
    );
  }

  group('CompletionTimeResolver.resolve', () {
    test('stamps now when the set is from today', () {
      final now = DateTime(2026, 9, 3, 18, 30);
      withClock(Clock.fixed(now), () {
        final set = buildSet(dateTime: DateTime(2026, 9, 3, 8, 0));

        final resolution = CompletionTimeResolver.resolve(set, []);

        expect(resolution.completedAt, now);
        expect(resolution.isDerived, isFalse);
      });
    });

    test(
        'derives from the latest completion among same-day siblings, plus one minute',
        () {
      final now = DateTime(2026, 9, 5, 10, 0);
      withClock(Clock.fixed(now), () {
        final pastDay = DateTime(2026, 9, 1, 18, 0);
        final set = buildSet(dateTime: pastDay, setId: 'last');
        final siblings = [
          buildSet(
              dateTime: pastDay,
              setId: '1',
              completedAt: DateTime(2026, 9, 1, 18, 2)),
          buildSet(
              dateTime: pastDay,
              setId: '2',
              completedAt: DateTime(2026, 9, 1, 18, 47)),
        ];

        final resolution = CompletionTimeResolver.resolve(set, siblings);

        expect(resolution.completedAt, DateTime(2026, 9, 1, 18, 48));
        expect(resolution.isDerived, isTrue);
      });
    });

    test(
        "falls back to the set's own dateTime when the past day has no completions",
        () {
      final now = DateTime(2026, 9, 5, 10, 0);
      withClock(Clock.fixed(now), () {
        final pastDay = DateTime(2026, 9, 1, 18, 0);
        final set = buildSet(dateTime: pastDay);
        final siblings = [
          buildSet(dateTime: pastDay, setId: 'other'),
        ];

        final resolution = CompletionTimeResolver.resolve(set, siblings);

        expect(resolution.completedAt, pastDay);
        expect(resolution.isDerived, isTrue);
      });
    });

    test('treats a workout crossing midnight as a past day, not today', () {
      final now = DateTime(2026, 9, 3, 0, 5);
      withClock(Clock.fixed(now), () {
        final sessionStart = DateTime(2026, 9, 2, 23, 50);
        final set = buildSet(dateTime: sessionStart, setId: 'late');
        final siblings = [
          buildSet(
              dateTime: sessionStart,
              setId: 'earlier',
              completedAt: DateTime(2026, 9, 2, 23, 55)),
        ];

        final resolution = CompletionTimeResolver.resolve(set, siblings);

        expect(resolution.completedAt, DateTime(2026, 9, 2, 23, 56));
        expect(resolution.isDerived, isTrue);
      });
    });

    test('picks the latest completion regardless of sibling order', () {
      final now = DateTime(2026, 9, 5, 10, 0);
      withClock(Clock.fixed(now), () {
        final pastDay = DateTime(2026, 9, 1, 18, 0);
        final set = buildSet(dateTime: pastDay);
        final siblings = [
          buildSet(
              dateTime: pastDay,
              setId: 'later',
              completedAt: DateTime(2026, 9, 1, 18, 47)),
          buildSet(
              dateTime: pastDay,
              setId: 'earlier',
              completedAt: DateTime(2026, 9, 1, 18, 2)),
        ];

        final resolution = CompletionTimeResolver.resolve(set, siblings);

        expect(resolution.completedAt, DateTime(2026, 9, 1, 18, 48));
        expect(resolution.isDerived, isTrue);
      });
    });
  });
}

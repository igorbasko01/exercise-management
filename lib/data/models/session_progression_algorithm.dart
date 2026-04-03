import 'package:exercise_management/core/enums/progression_type.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:exercise_management/data/models/progression_strategy.dart';

/// Abstract interface for session progression algorithms.
/// Implementations determine which [ProgressionStrategy] to apply
/// based on a list of completed exercise sets.
abstract class SessionProgressionAlgorithm {
  const SessionProgressionAlgorithm();

  /// Analyzes the given [sets] and returns the appropriate [ProgressionStrategy].
  ProgressionStrategy determineFrom(List<ExerciseSetPresentation> sets);

  /// Factory that returns the correct algorithm for the given [ProgressionType].
  factory SessionProgressionAlgorithm.fromType(ProgressionType type) {
    switch (type) {
      case ProgressionType.standard:
        return const StandardProgression();
      case ProgressionType.positiveOnly:
        return const PositiveOnlyProgression();
    }
  }
}

/// Standard progression algorithm.
///
/// Groups sets by repetitions and determines whether to increase or decrease
/// load based on whether the user completed at least 3 sets at the same
/// (highest) rep count.
class StandardProgression extends SessionProgressionAlgorithm {
  const StandardProgression();

  @override
  ProgressionStrategy determineFrom(List<ExerciseSetPresentation> sets) {
    if (sets.length < 3) {
      return const NoProgressionStrategy();
    }

    final groupedSetsByReps = _groupSetsByRepetitions(sets);
    final groupWithAtLeast3Sets = groupedSetsByReps.entries.firstWhere(
        (entry) => entry.value.length >= 3,
        orElse: () => MapEntry(0, []));
    final maxRepetitions =
        sets.map((set) => set.repetitions).reduce((a, b) => a > b ? a : b);

    if (groupWithAtLeast3Sets.key == 0) {
      final setWithMaxReps =
          sets.firstWhere((set) => set.repetitions == maxRepetitions);
      return DecreaseLoadStrategy(targetSet: setWithMaxReps);
    } else {
      final groupReps = groupWithAtLeast3Sets.key;
      if (groupReps < maxRepetitions) {
        final setWithMaxReps =
            sets.firstWhere((set) => set.repetitions == maxRepetitions);
        return DecreaseLoadStrategy(targetSet: setWithMaxReps);
      } else {
        return IncreaseLoadStrategy(
            targetSet: groupWithAtLeast3Sets.value.first);
      }
    }
  }

  static Map<int, List<ExerciseSetPresentation>> _groupSetsByRepetitions(
      List<ExerciseSetPresentation> sets) {
    final Map<int, List<ExerciseSetPresentation>> groupedSets = {};
    for (var set in sets) {
      groupedSets.putIfAbsent(set.repetitions, () => []).add(set);
    }
    return groupedSets;
  }
}

/// Positive-only progression algorithm.
///
/// Behaves like [StandardProgression] for increases, but returns
/// [NoProgressionStrategy] instead of [DecreaseLoadStrategy] when the
/// user struggles – the load is never reduced.
class PositiveOnlyProgression extends SessionProgressionAlgorithm {
  const PositiveOnlyProgression();

  @override
  ProgressionStrategy determineFrom(List<ExerciseSetPresentation> sets) {
    if (sets.length < 3) {
      return const NoProgressionStrategy();
    }

    final groupedSetsByReps = _groupSetsByRepetitions(sets);
    final groupWithAtLeast3Sets = groupedSetsByReps.entries.firstWhere(
        (entry) => entry.value.length >= 3,
        orElse: () => MapEntry(0, []));
    final maxRepetitions =
        sets.map((set) => set.repetitions).reduce((a, b) => a > b ? a : b);

    if (groupWithAtLeast3Sets.key == 0) {
      // User is struggling – no decrease, just keep current load
      return const NoProgressionStrategy();
    } else {
      final groupReps = groupWithAtLeast3Sets.key;
      if (groupReps < maxRepetitions) {
        // User is struggling – no decrease, just keep current load
        return const NoProgressionStrategy();
      } else {
        return IncreaseLoadStrategy(
            targetSet: groupWithAtLeast3Sets.value.first);
      }
    }
  }

  static Map<int, List<ExerciseSetPresentation>> _groupSetsByRepetitions(
      List<ExerciseSetPresentation> sets) {
    final Map<int, List<ExerciseSetPresentation>> groupedSets = {};
    for (var set in sets) {
      groupedSets.putIfAbsent(set.repetitions, () => []).add(set);
    }
    return groupedSets;
  }
}

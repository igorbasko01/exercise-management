import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/value.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:exercise_management/data/models/exercise_set_presentation_mapper.dart';

sealed class ProgressionStrategy {
  const ProgressionStrategy();

  factory ProgressionStrategy.noProgression() => const NoProgressionStrategy();

  factory ProgressionStrategy.decreaseLoad(
          {required ExerciseSetPresentation targetSet}) =>
      DecreaseLoadStrategy(targetSet: targetSet);

  factory ProgressionStrategy.increaseLoad(
          {required ExerciseSetPresentation targetSet}) =>
      IncreaseLoadStrategy(targetSet: targetSet);

  factory ProgressionStrategy.determineFrom(
      List<ExerciseSetPresentation> sets) {
    if (sets.length < 3) {
      return const NoProgressionStrategy();
    }

    // now we handle groups of sets that have at least 3 sets
    final groupedSetsByReps = _groupSetsByRepetitions(sets);
    // Find a group that has at least 3 sets with same repetitions.
    final groupWithAtLeast3Sets = groupedSetsByReps.entries.firstWhere(
        (entry) => entry.value.length >= 3,
        orElse: () => MapEntry(0, []));
    // Find max repetitions from all sets
    final maxRepetitions =
        sets.map((set) => set.repetitions).reduce((a, b) => a > b ? a : b);
    if (groupWithAtLeast3Sets.key == 0) {
      // No group with at least 3 sets with same repetitions found
      // it might be something like 5,4,3 or 5,5,4,3
      // it mainly means that user is struggling to complete the sets
      // so we decrease the load
      final setWithMaxReps =
          sets.firstWhere((set) => set.repetitions == maxRepetitions);
      return DecreaseLoadStrategy(targetSet: setWithMaxReps);
    } else {
      // We have a group with at least 3 sets with same repetitions
      // it might be something like 8,5,5,5 or 8,8,8,6
      // each one of them should be handled differently
      final groupReps = groupWithAtLeast3Sets.key;
      if (groupReps < maxRepetitions) {
        // This means that the 3 sets are lower than the max repetitions
        // it might be something like 8,5,5,5 which means user is struggling
        // so we decrease the load
        final setWithMaxReps =
            sets.firstWhere((set) => set.repetitions == maxRepetitions);
        return DecreaseLoadStrategy(targetSet: setWithMaxReps);
      } else {
        // This means that the 3 sets are the max repetitions
        // it might be something like 8,8,8,6 which means user is doing well
        // so we increase the load
        return IncreaseLoadStrategy(
            targetSet: groupWithAtLeast3Sets.value.first);
      }
    }
  }

  List<ExerciseSet> apply(List<ExerciseSetPresentation> sets);

  static Map<int, List<ExerciseSetPresentation>> _groupSetsByRepetitions(
      List<ExerciseSetPresentation> sets) {
    final Map<int, List<ExerciseSetPresentation>> groupedSets = {};
    for (var set in sets) {
      groupedSets.putIfAbsent(set.repetitions, () => []).add(set);
    }
    return groupedSets;
  }

  List<ExerciseSet> _copyAllSetsWithoutProgression(
      List<ExerciseSetPresentation> sets) {
    return sets
        .map((set) => ExerciseSetPresentationMapper.toExerciseSet(set.copyWith(
            setId: const Value(null), completedAt: const Value(null))))
        .toList();
  }

  double _adjustedWeight(double currentWeight, double adjustment) {
    List<double> allowedIncrements = [1.25, 2.5, 5];
    // find closest allowed increment to the adjustment
    // adjustment can be negative or positive
    double closestIncrement = allowedIncrements.reduce((a, b) =>
        (adjustment.abs() - a).abs() < (adjustment.abs() - b).abs() ? a : b);
    return (currentWeight + (closestIncrement * adjustment.sign))
        .clamp(0, double.infinity);
  }

  List<ExerciseSet> _createNewSetsWithLoad(List<ExerciseSetPresentation> sets,
      int newRepetitions, double newWeight) {
    return sets
        .map((set) => ExerciseSetPresentationMapper.toExerciseSet(set.copyWith(
            setId: const Value(null),
            completedAt: const Value(null),
            repetitions: newRepetitions,
            platesWeight: newWeight - set.equipmentWeight)))
        .toList();
  }
}

final class NoProgressionStrategy extends ProgressionStrategy {
  const NoProgressionStrategy();

  @override
  List<ExerciseSet> apply(List<ExerciseSetPresentation> sets) {
    return _copyAllSetsWithoutProgression(sets);
  }
}

final class DecreaseLoadStrategy extends ProgressionStrategy {
  final ExerciseSetPresentation targetSet;

  const DecreaseLoadStrategy({required this.targetSet});

  @override
  List<ExerciseSet> apply(List<ExerciseSetPresentation> sets) {
    final (newRepetitions, newWeight) = _decreaseLoad(targetSet.repetitions,
        targetSet.totalWeight, targetSet.repetitionsRange);

    return _createNewSetsWithLoad(sets, newRepetitions, newWeight);
  }

  (int, double) _decreaseLoad(int currentRepetitions, double currentTotalWeight,
      RepetitionsRange repRange) {
    int newRepetitions = currentRepetitions - 1;
    double newWeight = currentTotalWeight;

    if (newRepetitions < repRange.range.min) {
      newRepetitions = repRange.range.max;
      newWeight =
          _adjustedWeight(currentTotalWeight, -currentTotalWeight * 0.1);
    }

    return (newRepetitions, newWeight);
  }
}

final class IncreaseLoadStrategy extends ProgressionStrategy {
  final ExerciseSetPresentation targetSet;

  const IncreaseLoadStrategy({required this.targetSet});

  @override
  List<ExerciseSet> apply(List<ExerciseSetPresentation> sets) {
    final (newRepetitions, newWeight) = _increaseLoad(targetSet.repetitions,
        targetSet.totalWeight, targetSet.repetitionsRange);

    return _createNewSetsWithLoad(sets, newRepetitions, newWeight);
  }

  (int, double) _increaseLoad(int currentRepetitions, double currentTotalWeight,
      RepetitionsRange repRange) {
    int newRepetitions = currentRepetitions + 1;
    double newWeight = currentTotalWeight;

    if (newRepetitions > repRange.range.max) {
      newRepetitions = repRange.range.min;
      newWeight = _adjustedWeight(currentTotalWeight, currentTotalWeight * 0.1);
    }

    return (newRepetitions, newWeight);
  }
}

import 'package:exercise_management/core/enums/repetitions_range.dart';
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

  factory ProgressionStrategy.determineFrom(List<ExerciseSetPresentation> sets) {
    throw UnimplementedError();
  }

  List<ExerciseSet> apply(List<ExerciseSetPresentation> sets);

  List<ExerciseSet> _copyAllSetsWithoutProgression(
      List<ExerciseSetPresentation> sets) {
    return sets
        .map((set) =>
            ExerciseSetPresentationMapper.toExerciseSet(set.copyWithoutId()))
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
        .map((set) => ExerciseSetPresentationMapper.toExerciseSet(
            set.copyWithoutId(
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
      newWeight =
          _adjustedWeight(currentTotalWeight, currentTotalWeight * 0.1);
    }

    return (newRepetitions, newWeight);
  }
}

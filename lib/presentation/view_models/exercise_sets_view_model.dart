import 'package:exercise_management/core/command.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exercise_set_presentation_repository.dart';
import 'package:exercise_management/data/repository/exercise_set_repository.dart';
import 'package:exercise_management/data/repository/exercise_template_repository.dart';
import 'package:flutter/material.dart';

class ExerciseSetsViewModel extends ChangeNotifier {
  ExerciseSetsViewModel(
      {required ExerciseSetRepository exerciseSetRepository,
      required ExerciseSetPresentationRepository
          exerciseSetPresentationRepository,
      required ExerciseTemplateRepository exerciseTemplateRepository})
      : _exerciseSetRepository = exerciseSetRepository,
        _exerciseSetPresentationRepository = exerciseSetPresentationRepository,
        _exerciseTemplateRepository = exerciseTemplateRepository {
    fetchExerciseTemplates =
        Command0<List<ExerciseTemplate>>(_fetchExerciseTemplates)
          ..addListener(_onCommandExecuted);
    fetchExerciseSets =
        Command0<List<ExerciseSetPresentation>>(_fetchExerciseSets)
          ..addListener(_onCommandExecuted);
    addExerciseSet = Command1<ExerciseSet, ExerciseSet>(_addExerciseSet)
      ..addListener(_onCommandExecuted);
    addExerciseSets = Command1<void, List<ExerciseSet>>(_addExerciseSets)
      ..addListener(_onCommandExecuted);
    deleteExerciseSet = Command1<ExerciseSet, String>(_deleteExerciseSet)
      ..addListener(_onCommandExecuted);
    updateExerciseSet = Command1<ExerciseSet, ExerciseSet>(_updateExerciseSet)
      ..addListener(_onCommandExecuted);
    preloadExercises = Command0<void>(_preloadExercises)
      ..addListener(_onCommandExecuted);
    progressSets = Command1<void, List<ExerciseSet>>(_progressSets)
      ..addListener(_onCommandExecuted);
  }

  final ExerciseSetRepository _exerciseSetRepository;
  final ExerciseSetPresentationRepository _exerciseSetPresentationRepository;
  final ExerciseTemplateRepository _exerciseTemplateRepository;

  late final Command0<List<ExerciseSetPresentation>> fetchExerciseSets;
  late final Command1<ExerciseSet, ExerciseSet> addExerciseSet;
  late final Command1<void, List<ExerciseSet>> addExerciseSets;
  late final Command1<ExerciseSet, String> deleteExerciseSet;
  late final Command1<ExerciseSet, ExerciseSet> updateExerciseSet;
  late final Command0<List<ExerciseTemplate>> fetchExerciseTemplates;
  late final Command0<void> preloadExercises;
  late final Command1<void, List<ExerciseSet>> progressSets;

  List<ExerciseTemplate> _exerciseTemplates = [];

  List<ExerciseTemplate> get exerciseTemplates => _exerciseTemplates;

  List<ExerciseSetPresentation> _exerciseSets = [];

  List<ExerciseSetPresentation> get exerciseSets => _exerciseSets;

  void _onCommandExecuted() {
    notifyListeners();
  }

  Future<Result<List<ExerciseSetPresentation>>> _fetchExerciseSets() async {
    final result = await _exerciseSetPresentationRepository.getExerciseSets();
    switch (result) {
      case Ok<List<ExerciseSetPresentation>>():
        _exerciseSets = result.value;
        return Result.ok(_exerciseSets);
      case Error():
        return Result.error(result.error);
    }
  }

  Future<Result<ExerciseSet>> _addExerciseSet(ExerciseSet exerciseSet) async {
    final result = await _exerciseSetRepository.addExercise(exerciseSet);
    switch (result) {
      case Ok<ExerciseSet>():
        await _fetchExerciseSets();
        return Result.ok(result.value);
      case Error():
        return Result.error(result.error);
    }
  }

  Future<Result<void>> _addExerciseSets(List<ExerciseSet> exerciseSets) async {
    final result = await _exerciseSetRepository.addExercises(exerciseSets);
    switch (result) {
      case Ok<void>():
        await _fetchExerciseSets();
        return Result.ok(null);
      case Error():
        return Result.error(result.error);
    }
  }

  Future<Result<ExerciseSet>> _deleteExerciseSet(String id) async {
    final result = await _exerciseSetRepository.deleteExercise(id);
    switch (result) {
      case Ok<ExerciseSet>():
        await _fetchExerciseSets();
        return Result.ok(result.value);
      case Error():
        return Result.error(result.error);
    }
  }

  Future<Result<ExerciseSet>> _updateExerciseSet(
      ExerciseSet exerciseSet) async {
    final result = await _exerciseSetRepository.updateExercise(exerciseSet);
    switch (result) {
      case Ok<ExerciseSet>():
        await _fetchExerciseSets();
        return Result.ok(result.value);
      case Error():
        return Result.error(result.error);
    }
  }

  Future<Result<List<ExerciseTemplate>>> _fetchExerciseTemplates() async {
    final result = await _exerciseTemplateRepository.getExercises();
    switch (result) {
      case Ok<List<ExerciseTemplate>>():
        _exerciseTemplates = result.value;
        return Result.ok(_exerciseTemplates);
      case Error():
        return Result.error(result.error);
    }
  }

  Future<Result<void>> _preloadExercises() async {
    final resultTemplates = await _fetchExerciseTemplates();
    final resultSets = await _fetchExerciseSets();

    if (resultTemplates is Error) {
      return Result.error((resultTemplates as Error).error);
    }

    if (resultSets is Error) {
      return Result.error((resultSets as Error).error);
    }

    return Result.ok(null);
  }

  Future<Result<void>> _progressSets(List<ExerciseSet> sets) async {
    List<ExerciseSet> newSets = [];
    if (sets.length < 3) {
      newSets = sets.map((set) => set.copyWithoutId()).toList();
    } else {
      final groupedSets = _groupSetsByRepetitions(sets);
      // find a group with at least 3 sets
      final group = groupedSets.entries.firstWhere(
          (entry) => entry.value.length >= 3,
          orElse: () => MapEntry(0, []));
      // find highest repetitions in all sets
      final maxRepetitions =
          sets.map((set) => set.repetitions).reduce((a, b) => a > b ? a : b);
      final exerciseTemplateResult = await _exerciseTemplateRepository
          .getExercise(sets.first.exerciseTemplateId);
      if (exerciseTemplateResult is Error) {
        return Result.error((exerciseTemplateResult as Error).error);
      }
      final exerciseTemplate =
          (exerciseTemplateResult as Ok<ExerciseTemplate>).value;
      final repRange = exerciseTemplate.repetitionsRangeTarget;
      if (group.key == 0) {
        // no group with at least 3 sets with same repetitions found
        // reduce load
        final setWithMaxReps =
            sets.firstWhere((set) => set.repetitions == maxRepetitions);
        final (newRepetitions, newWeight) = _decreaseLoad(
            setWithMaxReps.repetitions, setWithMaxReps.totalWeight, repRange);
        newSets = sets
            .map((set) => set.copyWithoutId(
                repetitions: newRepetitions,
                platesWeight: newWeight - set.equipmentWeight))
            .toList();
      } else {
        // found a group with at least 3 sets with same repetitions
        final groupHighestRepetitions = group.key;
        if (groupHighestRepetitions < maxRepetitions) {
          // reduce load
          newSets = sets
              .map((set) => set.copyWithoutId(
                  repetitions: set.repetitions > 1 ? maxRepetitions - 1 : 1))
              .toList();
        } else {
          // increase load
          final sampleSet = group.value.first;
          final currentRepetitions = sampleSet.repetitions;
          final currentTotalWeight = sampleSet.totalWeight;
          final (newRepetitions, newWeight) =
              _increaseLoad(currentRepetitions, currentTotalWeight, repRange);
          newSets = sets
              .map((set) => set.copyWithoutId(
                  repetitions: newRepetitions,
                  platesWeight: newWeight - set.equipmentWeight))
              .toList();
        }
      }
    }

    final addResult = await _exerciseSetRepository.addExercises(newSets);
    switch (addResult) {
      case Ok<void>():
        return Result.ok(null);
      case Error():
        return Result.error(addResult.error);
    }
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

  double _adjustedWeight(double currentWeight, double adjustment) {
    List<double> allowedIncrements = [1.25, 2.5, 5];
    // find closest allowed increment to the adjustment
    // adjustment can be negative or positive
    double closestIncrement = allowedIncrements.reduce(
        (a, b) => (adjustment.abs() - a).abs() < (adjustment.abs() - b).abs() ? a : b);
    return (currentWeight + (closestIncrement * adjustment.sign)).clamp(0, double.infinity);
  }

  Map<int, List<ExerciseSet>> _groupSetsByRepetitions(List<ExerciseSet> sets) {
    final Map<int, List<ExerciseSet>> groupedSets = {};
    for (var set in sets) {
      groupedSets.putIfAbsent(set.repetitions, () => []).add(set);
    }
    return groupedSets;
  }

  @override
  void dispose() {
    fetchExerciseTemplates.removeListener(_onCommandExecuted);
    fetchExerciseSets.removeListener(_onCommandExecuted);
    addExerciseSet.removeListener(_onCommandExecuted);
    addExerciseSets.removeListener(_onCommandExecuted);
    deleteExerciseSet.removeListener(_onCommandExecuted);
    updateExerciseSet.removeListener(_onCommandExecuted);
    preloadExercises.removeListener(_onCommandExecuted);
    progressSets.removeListener(_onCommandExecuted);

    fetchExerciseSets.dispose();
    addExerciseSet.dispose();
    addExerciseSets.dispose();
    deleteExerciseSet.dispose();
    updateExerciseSet.dispose();
    fetchExerciseTemplates.dispose();
    preloadExercises.dispose();
    progressSets.dispose();

    super.dispose();
  }
}

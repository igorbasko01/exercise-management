import 'package:exercise_management/core/command.dart';
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
    if (sets.length == 1) {
      final set = sets.first;
      final newSet = set.copyWithoutId();
      final addResult = await _exerciseSetRepository.addExercise(newSet);
      if (addResult is Error) {
        return Result.error((addResult as Error).error);
      }
      return Result.ok(null);
    }
    return Result.ok(null);
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

import 'package:exercise_management/core/command.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/models/progression_strategy.dart';
import 'package:exercise_management/data/repository/exercise_set_presentation_repository.dart';
import 'package:exercise_management/data/repository/exercise_set_repository.dart';
import 'package:exercise_management/data/repository/exercise_template_repository.dart';
import 'package:exercise_management/core/services/exercise_ranking_manager.dart';
import 'package:flutter/material.dart';

class ExerciseSetsViewModel extends ChangeNotifier {
  ExerciseSetsViewModel({
    required ExerciseSetRepository exerciseSetRepository,
    required ExerciseSetPresentationRepository exerciseSetPresentationRepository,
    required ExerciseTemplateRepository exerciseTemplateRepository,
    required ExerciseRankingManager rankingManager,
  })  : _exerciseSetRepository = exerciseSetRepository,
        _exerciseSetPresentationRepository = exerciseSetPresentationRepository,
        _exerciseTemplateRepository = exerciseTemplateRepository,
        _rankingManager = rankingManager {
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
    progressSets = Command2<void, List<ExerciseSetPresentation>, DateTime>(_progressSets)
      ..addListener(_onCommandExecuted);
    fetchMoreExerciseSets = Command0<List<ExerciseSetPresentation>>(_fetchMoreExerciseSets)
      ..addListener(_onCommandExecuted);
  }

  final ExerciseSetRepository _exerciseSetRepository;
  final ExerciseSetPresentationRepository _exerciseSetPresentationRepository;
  final ExerciseTemplateRepository _exerciseTemplateRepository;
  final ExerciseRankingManager _rankingManager;

  late final Command0<List<ExerciseSetPresentation>> fetchExerciseSets;
  late final Command1<ExerciseSet, ExerciseSet> addExerciseSet;
  late final Command1<void, List<ExerciseSet>> addExerciseSets;
  late final Command1<ExerciseSet, String> deleteExerciseSet;
  late final Command1<ExerciseSet, ExerciseSet> updateExerciseSet;
  late final Command0<List<ExerciseTemplate>> fetchExerciseTemplates;
  late final Command0<void> preloadExercises;
  late final Command2<void, List<ExerciseSetPresentation>, DateTime> progressSets;
  late final Command0<List<ExerciseSetPresentation>> fetchMoreExerciseSets;

  List<ExerciseTemplate> _exerciseTemplates = [];

  List<ExerciseTemplate> get exerciseTemplates => _exerciseTemplates;

  List<ExerciseSetPresentation> _exerciseSets = [];

  List<ExerciseSetPresentation> get exerciseSets => _exerciseSets;

  String? _selectedExerciseTemplateId;

  String? get selectedExerciseTemplateId => _selectedExerciseTemplateId;

  void setSelectedExerciseTemplateId(String? templateId) {
    _selectedExerciseTemplateId = templateId;
    notifyListeners();
    fetchExerciseSets.execute();
  }

  /// Get the rank for a specific exercise group (date + template)
  int getRank(String date, String templateId) {
    return _rankingManager.getRank(date, templateId);
  }

  /// Calculate total volume for a list of exercise sets
  static double calculateTotalVolume(List<ExerciseSetPresentation> exercises) {
    return ExerciseRankingManager.calculateTotalVolume(exercises);
  }

  void _onCommandExecuted() {
    notifyListeners();
  }

  Future<Result<List<ExerciseSetPresentation>>> _fetchExerciseSets({int lastNDays = 7}) async {
    final result = await _exerciseSetPresentationRepository.getExerciseSets(
        lastNDays: lastNDays, exerciseTemplateId: _selectedExerciseTemplateId);
    switch (result) {
      case Ok<List<ExerciseSetPresentation>>():
        _exerciseSets = result.value;
        _rankingManager.calculateRanks(_exerciseSets, _formatDate);
        return Result.ok(_exerciseSets);
      case Error():
        return Result.error(result.error);
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}'
        '-${dateTime.month.toString().padLeft(2, '0')}'
        '-${dateTime.day.toString().padLeft(2, '0')}';
  }

  Future<Result<List<ExerciseSetPresentation>>> _fetchMoreExerciseSets() async {
    final totalDaysToFetch = _exerciseSets
        .map((set) => DateTime(set.dateTime.year, set.dateTime.month, set.dateTime.day))
        .toSet()
        .length + 7;  // Fetch 7 more days
    return await _fetchExerciseSets(lastNDays: totalDaysToFetch);
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

  Future<Result<void>> _progressSets(
      List<ExerciseSetPresentation> sets, DateTime newDate) async {
    final groupedSets = _groupSetsByTemplate(sets);

    List<ExerciseSet> newSets = [];
    for (var entry in groupedSets.entries) {
      final progressedSets = _progressSetsGroup(entry.value)
          .map((set) => set.copyWith(dateTime: newDate))
          .toList();
      newSets.addAll(progressedSets);
    }

    final addResult = await _exerciseSetRepository.addExercises(newSets);
    switch (addResult) {
      case Ok<void>():
        await _fetchExerciseSets();
        return Result.ok(null);
      case Error():
        return Result.error(addResult.error);
    }
  }

  List<ExerciseSet> _progressSetsGroup(List<ExerciseSetPresentation> sets) {
    return ProgressionStrategy.determineFrom(sets).apply(sets);
  }

  Map<String, List<ExerciseSetPresentation>> _groupSetsByTemplate(
      List<ExerciseSetPresentation> sets) {
    final Map<String, List<ExerciseSetPresentation>> groupedSets = {};
    for (var set in sets) {
      groupedSets.putIfAbsent(set.exerciseTemplateId, () => []).add(set);
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
    fetchMoreExerciseSets.removeListener(_onCommandExecuted);

    fetchExerciseSets.dispose();
    addExerciseSet.dispose();
    addExerciseSets.dispose();
    deleteExerciseSet.dispose();
    updateExerciseSet.dispose();
    fetchExerciseTemplates.dispose();
    preloadExercises.dispose();
    progressSets.dispose();
    fetchMoreExerciseSets.dispose();

    super.dispose();
  }
}

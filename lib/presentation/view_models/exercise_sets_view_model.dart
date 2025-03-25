import 'package:exercise_management/core/command.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:exercise_management/data/repository/exercise_set_presentation_repository.dart';
import 'package:exercise_management/data/repository/exercise_set_repository.dart';
import 'package:flutter/material.dart';

class ExerciseSetsViewModel extends ChangeNotifier {
  ExerciseSetsViewModel(
      {required ExerciseSetRepository exerciseSetRepository,
      required ExerciseSetPresentationRepository
          exerciseSetPresentationRepository})
      : _exerciseSetRepository = exerciseSetRepository,
        _exerciseSetPresentationRepository = exerciseSetPresentationRepository {
    fetchExerciseSets =
        Command0<List<ExerciseSetPresentation>>(_fetchExerciseSets)
          ..addListener(_onCommandExecuted);
    addExerciseSet = Command1<ExerciseSet, ExerciseSet>(_addExerciseSet)
      ..addListener(_onCommandExecuted);
    deleteExerciseSet = Command1<ExerciseSet, String>(_deleteExerciseSet)
      ..addListener(_onCommandExecuted);
    updateExerciseSet = Command1<ExerciseSet, ExerciseSet>(_updateExerciseSet)
      ..addListener(_onCommandExecuted);
  }

  final ExerciseSetRepository _exerciseSetRepository;
  final ExerciseSetPresentationRepository _exerciseSetPresentationRepository;

  late final Command0<List<ExerciseSetPresentation>> fetchExerciseSets;
  late final Command1<ExerciseSet, ExerciseSet> addExerciseSet;
  late final Command1<ExerciseSet, String> deleteExerciseSet;
  late final Command1<ExerciseSet, ExerciseSet> updateExerciseSet;

  void _onCommandExecuted() {
    notifyListeners();
  }

  Future<Result<List<ExerciseSetPresentation>>> _fetchExerciseSets() async {
    return await _exerciseSetPresentationRepository.getExerciseSets();
  }

  Future<Result<ExerciseSet>> _addExerciseSet(ExerciseSet exerciseSet) async {
    return await _exerciseSetRepository.addExercise(exerciseSet);
  }

  Future<Result<ExerciseSet>> _deleteExerciseSet(String id) async {
    return await _exerciseSetRepository.deleteExercise(id);
  }

  Future<Result<ExerciseSet>> _updateExerciseSet(
      ExerciseSet exerciseSet) async {
    return await _exerciseSetRepository.updateExercise(exerciseSet);
  }

  @override
  void dispose() {
    fetchExerciseSets.removeListener(_onCommandExecuted);
    addExerciseSet.removeListener(_onCommandExecuted);
    deleteExerciseSet.removeListener(_onCommandExecuted);
    updateExerciseSet.removeListener(_onCommandExecuted);

    fetchExerciseSets.dispose();
    addExerciseSet.dispose();
    deleteExerciseSet.dispose();
    updateExerciseSet.dispose();

    super.dispose();
  }
}

import 'package:exercise_management/core/command.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_program.dart';
import 'package:exercise_management/data/models/exercise_program_session.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:exercise_management/data/repository/exercise_program_repository.dart';
import 'package:exercise_management/data/repository/exercise_set_presentation_repository.dart';
import 'package:exercise_management/data/repository/exercise_set_repository.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class ProgramProgressionViewModel extends ChangeNotifier {
  final ExerciseProgramRepository _programRepository;
  final ExerciseSetPresentationRepository _setPresentationRepository;
  final ExerciseSetRepository _exerciseSetRepository;
  StreamSubscription? _programSubscription;
  StreamSubscription? _setSubscription;

  ProgramProgressionViewModel({
    required ExerciseProgramRepository programRepository,
    required ExerciseSetPresentationRepository setPresentationRepository,
    required ExerciseSetRepository exerciseSetRepository,
  })  : _programRepository = programRepository,
        _setPresentationRepository = setPresentationRepository,
        _exerciseSetRepository = exerciseSetRepository {
    fetchProgressionData = Command0(_fetchProgressionData)
      ..addListener(_onCommandExecuted);

    _programSubscription = _programRepository.watchPrograms().listen((_) {
      if (!fetchProgressionData.running) {
        fetchProgressionData.execute();
      }
    });

    _setSubscription = _exerciseSetRepository.watchExerciseSets().listen((_) {
      if (!fetchProgressionData.running) {
        fetchProgressionData.execute();
      }
    });
  }

  late final Command0<void> fetchProgressionData;

  ExerciseProgram? _activeProgram;
  ExerciseProgram? get activeProgram => _activeProgram;

  ExerciseProgramSession? _nextSession;
  ExerciseProgramSession? get nextSession => _nextSession;

  ExerciseProgramSession? _lastSession;
  ExerciseProgramSession? get lastSession => _lastSession;

  DateTime? _lastSessionDate;
  DateTime? get lastSessionDate => _lastSessionDate;

  void _onCommandExecuted() {
    notifyListeners();
  }

  Future<Result<void>> _fetchProgressionData() async {
    // 1. Fetch active program
    final programsResult = await _programRepository.getPrograms();
    if (programsResult is Error) {
      return Result.error((programsResult as Error).error);
    }
    
    final programs = (programsResult as Ok<List<ExerciseProgram>>).value;
    try {
      _activeProgram = programs.firstWhere((p) => p.isActive);
    } catch (_) {
      _activeProgram = null;
      _nextSession = null;
      _lastSession = null;
      _lastSessionDate = null;
      return Result.ok(null);
    }

    if (_activeProgram!.sessions.isEmpty) {
      _nextSession = null;
      _lastSession = null;
      _lastSessionDate = null;
      return Result.ok(null);
    }

    // 2. Loop through all sessions and find the one that was completely finished most recently.
    ExerciseProgramSession? mostRecentlyCompletedSession;
    DateTime? mostRecentCompletionDate;

    for (var session in _activeProgram!.sessions) {
      if (session.exercises.isEmpty) continue;

      final templateIds = session.exercises.map((e) => e.id).whereType<String>().toList();
      if (templateIds.isEmpty) continue;

      final completionResult = await _setPresentationRepository.getMostRecentCompletionDate(templateIds);
      if (completionResult is Ok<DateTime?>) {
        final date = completionResult.value;
        if (date != null) {
          if (mostRecentCompletionDate == null || date.isAfter(mostRecentCompletionDate)) {
            mostRecentCompletionDate = date;
            mostRecentlyCompletedSession = session;
          }
        }
      }
    }

    _lastSession = mostRecentlyCompletedSession;
    _lastSessionDate = mostRecentCompletionDate;

    // 3. Determine the "next session"
    if (mostRecentlyCompletedSession == null) {
      _nextSession = _activeProgram!.sessions.first;
    } else {
      final currentIndex = _activeProgram!.sessions.indexOf(mostRecentlyCompletedSession);
      final nextIndex = (currentIndex + 1) % _activeProgram!.sessions.length;
      _nextSession = _activeProgram!.sessions[nextIndex];
    }

    return Result.ok(null);
  }

  Future<List<ExerciseSetPresentation>?> getLatestSetsForNextSession() async {
    if (_nextSession == null || _nextSession!.exercises.isEmpty) {
      return null;
    }

    final templateIds = _nextSession!.exercises.map((e) => e.id).whereType<String>().toList();
    if (templateIds.isEmpty) return null;

    final completionResult = await _setPresentationRepository.getMostRecentCompletionDate(templateIds);
    if (completionResult is Error) return null;

    if (completionResult is Ok<DateTime?>) {
      final date = completionResult.value;
      if (date != null) {
        final setsResult = await _setPresentationRepository.getExerciseSetsByDateAndTemplates(date, templateIds);
        if (setsResult is Error) return null;

        if (setsResult is Ok<List<ExerciseSetPresentation>>) {
          return setsResult.value;
        }
      }
    }
    
    return []; // Return empty list to signify "no sets found" vs null for "error/not ready"
  }

  @override
  void dispose() {
    _programSubscription?.cancel();
    _setSubscription?.cancel();
    fetchProgressionData.removeListener(_onCommandExecuted);
    fetchProgressionData.dispose();
    super.dispose();
  }
}

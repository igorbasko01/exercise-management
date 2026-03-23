import 'package:exercise_management/core/command.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_program.dart';
import 'package:exercise_management/data/models/exercise_program_session.dart';
import 'package:exercise_management/data/repository/exercise_program_repository.dart';
import 'package:exercise_management/data/repository/exercise_set_presentation_repository.dart';
import 'package:flutter/foundation.dart';

class ProgramProgressionViewModel extends ChangeNotifier {
  final ExerciseProgramRepository _programRepository;
  final ExerciseSetPresentationRepository _setPresentationRepository;

  ProgramProgressionViewModel({
    required ExerciseProgramRepository programRepository,
    required ExerciseSetPresentationRepository setPresentationRepository,
  })  : _programRepository = programRepository,
        _setPresentationRepository = setPresentationRepository {
    fetchProgressionData = Command0(_fetchProgressionData)
      ..addListener(_onCommandExecuted);
  }

  late final Command0<void> fetchProgressionData;

  ExerciseProgram? _activeProgram;
  ExerciseProgram? get activeProgram => _activeProgram;

  ExerciseProgramSession? _nextSession;
  ExerciseProgramSession? get nextSession => _nextSession;

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
      return Result.ok(null);
    }

    if (_activeProgram!.sessions.isEmpty) {
      _nextSession = null;
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

  @override
  void dispose() {
    fetchProgressionData.removeListener(_onCommandExecuted);
    fetchProgressionData.dispose();
    super.dispose();
  }
}

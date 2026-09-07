import 'dart:async';

import 'package:exercise_management/core/command.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/core/services/exercise_ranking_manager.dart';
import 'package:exercise_management/data/models/exercise_program.dart';
import 'package:exercise_management/data/models/exercise_rank_summary.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exercise_set_presentation_repository.dart';
import 'package:exercise_management/data/repository/exercise_set_repository.dart';
import 'package:flutter/foundation.dart';

/// Drives the home screen's per-exercise all-time ranking widget: for every
/// exercise in the given program, the two most recent sessions with their
/// all-time rank, plus the all-time best session.
class HomeExerciseRanksViewModel extends ChangeNotifier {
  HomeExerciseRanksViewModel({
    required ExerciseSetPresentationRepository setPresentationRepository,
    required ExerciseSetRepository exerciseSetRepository,
  }) : _setPresentationRepository = setPresentationRepository {
    loadRanks = Command1<void, ExerciseProgram?>(_loadRanks)
      ..addListener(_onCommandExecuted);

    _setSubscription = exerciseSetRepository.watchExerciseSets().listen((_) {
      if (!loadRanks.running) {
        loadRanks.execute(_activeProgram);
      }
    });
  }

  final ExerciseSetPresentationRepository _setPresentationRepository;
  // A private instance, not the app-wide one: sharing it with ExerciseSetsViewModel
  // would let each overwrite the other's ranks, since they rank different windows.
  final ExerciseRankingManager _rankingManager = ExerciseRankingManager();
  StreamSubscription? _setSubscription;
  ExerciseProgram? _activeProgram;

  late final Command1<void, ExerciseProgram?> loadRanks;

  List<ExerciseRankSummary> _exerciseRankSummaries = [];
  List<ExerciseRankSummary> get exerciseRankSummaries => _exerciseRankSummaries;

  void _onCommandExecuted() {
    notifyListeners();
  }

  Future<Result<void>> _loadRanks(ExerciseProgram? program) async {
    _activeProgram = program;
    final templates = _dedupExerciseTemplates(program);

    if (templates.isEmpty) {
      _exerciseRankSummaries = [];
      return Result.ok(null);
    }

    final templateIds = templates.map((t) => t.id!).toList();
    final setsResult =
        await _setPresentationRepository.getExerciseSetsForTemplates(templateIds);
    switch (setsResult) {
      case Ok<List<ExerciseSetPresentation>>():
        _exerciseRankSummaries = _buildSummaries(templates, setsResult.value);
        return Result.ok(null);
      case Error():
        return Result.error(setsResult.error);
    }
  }

  List<ExerciseTemplate> _dedupExerciseTemplates(ExerciseProgram? program) {
    if (program == null) return [];

    final seenIds = <String>{};
    final templates = <ExerciseTemplate>[];
    for (var session in program.sessions) {
      for (var template in session.exercises) {
        final id = template.id;
        if (id == null || !seenIds.add(id)) continue;
        templates.add(template);
      }
    }
    return templates;
  }

  List<ExerciseRankSummary> _buildSummaries(
      List<ExerciseTemplate> templates, List<ExerciseSetPresentation> allSets) {
    _rankingManager.calculateRanks(allSets, _formatDate);

    final setsByTemplateAndDate = <String, Map<String, List<ExerciseSetPresentation>>>{};
    for (var set in allSets) {
      final date = _formatDate(set.dateTime);
      setsByTemplateAndDate
          .putIfAbsent(set.exerciseTemplateId, () => {})
          .putIfAbsent(date, () => [])
          .add(set);
    }

    return templates.map((template) {
      final templateId = template.id!;
      final dateGroups = setsByTemplateAndDate[templateId] ?? {};

      final sessions = dateGroups.entries.map((entry) {
        final sets = entry.value;
        return ExerciseSessionSummary(
          date: DateTime.parse(entry.key),
          totalVolume: ExerciseRankingManager.calculateTotalVolume(sets),
          rank: _rankingManager.getRank(entry.key, templateId),
          setsLabel: _formatSetsLabel(sets),
        );
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      return ExerciseRankSummary(
        exerciseTemplateId: templateId,
        exerciseName: template.name,
        recentSessions: sessions.take(2).toList(),
        bestSession: sessions.isEmpty ? null : _pickBestSession(sessions),
      );
    }).toList();
  }

  // Ties go to whichever session reached that volume first.
  ExerciseSessionSummary _pickBestSession(List<ExerciseSessionSummary> sessions) {
    return sessions.reduce((best, candidate) {
      if (candidate.totalVolume > best.totalVolume) return candidate;
      if (candidate.totalVolume < best.totalVolume) return best;
      return candidate.date.isBefore(best.date) ? candidate : best;
    });
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}'
        '-${dateTime.month.toString().padLeft(2, '0')}'
        '-${dateTime.day.toString().padLeft(2, '0')}';
  }

  String _formatSetsLabel(List<ExerciseSetPresentation> sets) {
    if (sets.isEmpty) return '';

    final first = sets.first;
    final isUniform = sets.every((set) =>
        set.totalWeight == first.totalWeight &&
        set.repetitions == first.repetitions);

    if (isUniform) {
      return '${sets.length} x ${_formatWeight(first.totalWeight)} kg x ${first.repetitions}';
    }

    return sets
        .map((set) => '${_formatWeight(set.totalWeight)} kg x ${set.repetitions}')
        .join(', ');
  }

  String _formatWeight(double weight) {
    return weight == weight.roundToDouble()
        ? weight.toStringAsFixed(0)
        : weight.toString();
  }

  @override
  void dispose() {
    _setSubscription?.cancel();
    loadRanks.removeListener(_onCommandExecuted);
    loadRanks.dispose();
    super.dispose();
  }
}

import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:flutter/material.dart';

/// Manages ranking of exercise groups by total volume
class ExerciseRankingManager extends ChangeNotifier {
  Map<String, int> _ranks = {};

  /// Get the rank for a specific exercise group
  /// Returns 1 if the rank is not found (default/fallback)
  int getRank(String date, String templateId) {
    final key = '$date-$templateId';
    return _ranks[key] ?? 1;
  }

  /// Calculate and update ranks for all exercise groups based on total volume
  void calculateRanks(List<ExerciseSetPresentation> allSets, String Function(DateTime) formatDate) {
    // Group sets by date and template
    final groupedSets = <String, List<ExerciseSetPresentation>>{};
    for (var set in allSets) {
      final date = formatDate(set.dateTime);
      final key = '$date-${set.exerciseTemplateId}';
      groupedSets.putIfAbsent(key, () => []).add(set);
    }

    // Calculate total volume for each group
    final volumeMap = <String, double>{};
    for (var entry in groupedSets.entries) {
      volumeMap[entry.key] = _calculateTotalVolume(entry.value);
    }

    // Sort groups by total volume (descending)
    final sortedEntries = volumeMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Assign ranks
    final newRanks = <String, int>{};
    for (var i = 0; i < sortedEntries.length; i++) {
      newRanks[sortedEntries[i].key] = i + 1;
    }

    _ranks = newRanks;
    notifyListeners();
  }

  /// Calculate total volume for a list of exercise sets
  /// Total volume = sum of (weight * repetitions) for all sets
  double calculateTotalVolume(List<ExerciseSetPresentation> exercises) {
    return _calculateTotalVolume(exercises);
  }

  double _calculateTotalVolume(List<ExerciseSetPresentation> exercises) {
    return exercises
        .map((set) => (set.equipmentWeight + set.platesWeight) * set.repetitions)
        .fold(0.0, (value, element) => value + element);
  }
}

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
  /// Ranks are calculated per exercise template, comparing sessions of the same exercise
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
      volumeMap[entry.key] = calculateTotalVolume(entry.value);
    }

    // Group by template ID to rank within each exercise type
    final volumesByTemplate = <String, List<MapEntry<String, double>>>{};
    for (var entry in volumeMap.entries) {
      // Extract template ID from the key (format: 'date-templateId')
      final templateId = entry.key.split('-').last;
      volumesByTemplate.putIfAbsent(templateId, () => []).add(entry);
    }

    // Assign ranks per template
    final newRanks = <String, int>{};
    for (var templateEntries in volumesByTemplate.values) {
      // Sort entries for this template by volume (descending)
      final sortedEntries = templateEntries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Assign ranks within this template
      for (var i = 0; i < sortedEntries.length; i++) {
        newRanks[sortedEntries[i].key] = i + 1;
      }
    }

    _ranks = newRanks;
    notifyListeners();
  }

  /// Calculate total volume for a list of exercise sets
  /// Total volume = sum of (weight * repetitions) for all sets
  double calculateTotalVolume(List<ExerciseSetPresentation> exercises) {
    return exercises
        .map((set) => (set.equipmentWeight + set.platesWeight) * set.repetitions)
        .fold(0.0, (value, element) => value + element);
  }
}
